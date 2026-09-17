import test from 'node:test';
import assert from 'node:assert/strict';
import { createStore } from '../src/store.mjs';
import { app } from '../src/server.mjs';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

async function fixture(t) {
  const store = createStore(), directory = await mkdtemp(join(tmpdir(), 'orders-'));
  const server = app(store, { adminToken: 'admin-test', mediaDirectory: directory });
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  t.after(async () => { await new Promise(r => server.close(r)); store.close(); await rm(directory, { recursive:true, force:true }); });
  const user = store.createUser(), creatorUser = store.createUser(), otherUser = store.createUser();
  let creator = store.upsertCreatorProfile(creatorUser, {displayName:'Maker',email:'maker@example.test',skillTags:['3D']});
  creator = store.manageCreatorProfile(creator.id, creator.version, {status:'approved',canReceiveOrders:true});
  const tokens = {user:store.createSession(user),creator:store.createSession(creatorUser),other:store.createSession(otherUser),admin:'admin-test'};
  const request = async (path, actor = 'admin', body, extra = {}, method) => {
    const response = await fetch(`http://127.0.0.1:${server.address().port}${path}`, {method:method ?? (body === undefined?'GET':'POST'),headers:{Authorization:`Bearer ${tokens[actor]}`,'Content-Type':'application/json',...extra},body:body === undefined?undefined:Buffer.isBuffer(body)?body:JSON.stringify(body)});
    const data = response.headers.get('content-type')?.includes('json') ? await response.json() : await response.arrayBuffer();
    return {status:response.status,data};
  };
  let order = store.createCustomizationOrder(user, {characterName:'Fox',requestedFeatures:['idle'],materialCount:1,requirements:'blue eyes'});
  order = store.updateCustomizationOrderWorkflow(order.id,order.version,'approved_for_quote');
  return {store,request,order,creator};
}

test('legacy recovery preserves history, unlocks real uploads and requires a fresh assigned quote', async t => {
  const {store,request,order:initial,creator}=await fixture(t);
  let order=store.updateCustomizationOrderWorkflow(initial.id,initial.version,'quoted','旧报价',{quoteAmount:100,currency:'USD',deliveryDays:7});
  order=store.updateCustomizationOrderWorkflow(order.id,order.version,'in_production','旧流程',{assignee:'旧负责人',dueAt:'2026-10-01'});
  const path=`/admin/customization-orders/${order.id}/recover`;
  assert.equal((await request(path,'user',{version:order.version,note:'修复'})).status,401);
  assert.equal((await request(path,'admin',{version:order.version-1,note:'修复'})).status,409);
  assert.equal((await request(path,'admin',{version:order.version,note:''})).status,400);
  const historyCount=order.workflowHistory.length;
  let result=await request(path,'admin',{version:order.version,note:'请重新上传参考图，重新派单及确认报价'});
  assert.equal(result.status,200);
  order=result.data;
  assert.equal(order.status,'needs_info');
  assert.deepEqual(order.workflow,{});
  assert.equal(order.workflowHistory.length,historyCount+1);
  assert.equal(order.workflowHistory.at(-1).action,'legacy_recovered');
  assert.equal(order.materialsUploaded,false);
  assert.throws(()=>store.updateCustomizationOrderWorkflow(order.id,order.version,'approved_for_quote'),/ORDER_MATERIAL_REQUIRED/);
  const png=Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aZxQAAAAASUVORK5CYII=','base64');
  result=await request(`/v1/me/customization-orders/${order.id}/materials?slot=recovery-1&name=reference.png`,'user',png,{'Content-Type':'image/png'});
  assert.equal(result.status,200);
  order=store.getCustomizationOrder(order.id);
  order=store.updateCustomizationOrderWorkflow(order.id,order.version,'approved_for_quote');
  assert.throws(()=>store.updateCustomizationOrderWorkflow(order.id,order.version,'quoted','',{quoteAmount:100,currency:'USD',deliveryDays:7}),/ORDER_CREATOR_REQUIRED/);
  order=store.dispatchOrder(order.id,{version:order.version,mode:'direct',creatorId:creator.id});
  assert.equal((await request(path,'admin',{version:order.version,note:'再次修复'})).status,400);
});
test('direct assignment, creator quote, and actual user acceptance', async t => {
  const {request,order,creator} = await fixture(t);
  let r = await request(`/admin/customization-orders/${order.id}/dispatch`,'admin',{version:order.version,mode:'direct',creatorId:creator.id});
  assert.equal(r.status,200); assert.equal(r.data.assignedCreatorId,creator.id);
  const assignedVersion = r.data.version;
  const pool=await request('/admin/order-creators');assert.equal(pool.status,200);assert.equal(pool.data.items.find(c=>c.id===creator.id).activeOrderCount,1);
  assert.equal((await request(`/admin/customization-orders/${order.id}`,'admin',{version:assignedVersion,status:'quoted',fields:{quoteAmount:120,currency:'USD',deliveryDays:7}})).data.code,'ORDER_QUOTE_PROPOSAL_REQUIRED');
  assert.equal((await request(`/admin/customization-orders/${order.id}/dispatch`,'admin',{version:order.version,mode:'direct',creatorId:creator.id})).status,409);
  r = await request('/v1/me/creator-tasks','creator'); assert.equal(r.data.items[0].requirements,'blue eyes');
  r = await request(`/v1/me/creator-tasks/${order.id}`,'creator',{version:assignedVersion,action:'quote',fields:{quoteAmount:100,currency:'USD',deliveryDays:7}});
  assert.equal(r.status,200); assert.equal(r.data.creatorQuote.quoteAmount,100);
  r = await request(`/admin/customization-orders/${order.id}`,'admin',{version:r.data.version,status:'quoted',fields:{quoteAmount:120,currency:'USD',deliveryDays:7}}); assert.equal(r.status,200);
  assert.equal((await request(`/admin/customization-orders/${order.id}`,'admin',{version:r.data.version,status:'in_production',fields:{assignee:'fake',dueAt:'2026-12-31'}})).status,400);
  r = await request(`/v1/me/customization-orders/${order.id}/action`,'user',{version:r.data.version,action:'accept_quote'});
  assert.equal(r.status,200); assert.equal(r.data.status,'in_production');
});
test('application dispatch excludes private materials until chosen and enforces applicant membership', async t => {
  const {request,order,creator} = await fixture(t);
  const png = Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),Buffer.alloc(40)]);
  let r = await request(`/v1/me/customization-orders/${order.id}/materials?name=ref.png&slot=1`,'user',png,{'Content-Type':'image/png'});
  assert.equal(r.status,200); const material = r.data.materials[0];
  assert.equal((await request(`/v1/me/customization-orders/${order.id}/materials?name=ref.png&slot=1`,'user',png,{'Content-Type':'image/png'})).data.materials.length,1);
  r = await request(`/admin/customization-orders/${order.id}`); const version = r.data.version;
  r = await request(`/admin/customization-orders/${order.id}/dispatch`,'admin',{version,mode:'applications'}); assert.equal(r.status,200);
  assert.equal((await request(`/admin/customization-orders/${order.id}/dispatch`,'admin',{version:r.data.version,mode:'applications',creatorId:creator.id})).status,400);
  const tasks = (await request('/v1/me/creator-tasks','creator')).data.items; assert.equal(tasks[0].materials,undefined); assert.equal(tasks[0].userId,undefined);
  assert.equal((await request(`/v1/me/creator-tasks/${order.id}/materials/${material.id}`,'creator')).status,404);
  r = await request(`/v1/me/creator-tasks/${order.id}`,'creator',{version:r.data.version,action:'apply'}); assert.equal(r.status,200);
  assert.equal(r.data.materials,undefined);
  r = await request(`/admin/customization-orders/${order.id}/dispatch`,'admin',{version:r.data.version,mode:'applications',creatorId:creator.id}); assert.equal(r.status,200);
  assert.equal((await request(`/v1/me/creator-tasks/${order.id}/materials/${material.id}`,'creator')).status,200);
  assert.equal((await request(`/v1/me/customization-orders/${order.id}/materials/${material.id}`,'other')).status,404);
  assert.equal((await request(`/admin/customization-orders/${order.id}/materials/${material.id}`)).status,200);
});
test('paged search returns bounded summaries and counts', async t => {
  const {request,store} = await fixture(t);
  const user = store.createUser();
  for(let n=0;n<31;n++) store.createCustomizationOrder(user,{characterName:`Batch ${n}`,workflowHistory:[{note:'private'}]});
  const {status,data} = await request('/admin/customization-orders?page=2&pageSize=10&q=Batch');
  assert.equal(status,200); assert.equal(data.total,31); assert.equal(data.items.length,10); assert.equal(data.page,2); assert.equal(data.items[0].workflowHistory,undefined);
});

test('revocation and reassignment immediately remove creator private access',async t=>{
  const {store,request,order,creator}=await fixture(t);
  const png=Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),Buffer.alloc(40)]);
  let r=await request(`/v1/me/customization-orders/${order.id}/materials?slot=a`,'user',png,{'Content-Type':'image/png'});
  const material=r.data.materials[0];
  r=await request(`/admin/customization-orders/${order.id}/dispatch`,'admin',{version:r.data.version,mode:'direct',creatorId:creator.id});
  const oldVersion=r.data.version;
  r=await request(`/admin/customization-orders/${order.id}/dispatch`,'admin',{version:r.data.version,mode:'applications'});
  assert.equal(r.status,200);
  assert.equal((await request(`/v1/me/creator-tasks/${order.id}/materials/${material.id}`,'creator')).status,404);
  assert.equal((await request(`/v1/me/creator-tasks/${order.id}`,'creator',{version:oldVersion,action:'quote',fields:{quoteAmount:50,currency:'USD',deliveryDays:1}})).status,409);
  store.manageCreatorProfile(creator.id,store.getCreatorProfile(creator.id).version,{status:'suspended',canReceiveOrders:true});
  assert.equal((await request(`/admin/customization-orders/${order.id}/dispatch`,'admin',{version:r.data.version,mode:'direct',creatorId:creator.id})).status,400);
  assert.equal((await request('/v1/me/creator-tasks','creator')).status,400);
});

test('idempotent request keys are scoped to the customer', async t=>{
  const {request}=await fixture(t);
  const body={clientRequestId:'request-123456',characterName:'One',sourceType:'OC',requestedFeatures:['idle'],materialCount:1,marketRegion:'us',privacyConsentVersion:'v1',requirements:'full brief'};
  const first=await request('/v1/me/customization-orders','user',body);
  const retry=await request('/v1/me/customization-orders','user',body);
  const other=await request('/v1/me/customization-orders','other',body);
  assert.equal(first.status,201);assert.equal(retry.data.id,first.data.id);assert.notEqual(other.data.id,first.data.id);
  assert.equal(first.data.requirements,'full brief');
});

test('delivery requires real customer acceptance and revision clears QC',async t=>{
  const {store,request,order,creator}=await fixture(t);
  let r=await request(`/admin/customization-orders/${order.id}/dispatch`,'admin',{version:order.version,mode:'direct',creatorId:creator.id});
  r=await request(`/v1/me/creator-tasks/${order.id}`,'creator',{version:r.data.version,action:'quote',fields:{quoteAmount:100,currency:'USD',deliveryDays:7}});
  r=await request(`/admin/customization-orders/${order.id}`,'admin',{version:r.data.version,status:'quoted',fields:{quoteAmount:100,currency:'USD',deliveryDays:7}});
  r=await request(`/v1/me/customization-orders/${order.id}/action`,'user',{version:r.data.version,action:'accept_quote'});
  r=await request(`/v1/me/creator-tasks/${order.id}`,'creator',{version:r.data.version,action:'submit',fields:{deliverableReference:'private-delivery-1'}});
  assert.equal(r.status,200);assert.equal(r.data.status,'quality_review');
  r=await request(`/admin/customization-orders/${order.id}`,'admin',{version:r.data.version,status:'user_acceptance',fields:{qcPassed:true,deliveryReference:'package-1'}});
  assert.equal(r.status,200);
  const customerView=await request(`/v1/me/customization-orders/${order.id}`,'user');
  assert.equal(customerView.data.workflow.deliverableReference,undefined);assert.equal(customerView.data.workflow.deliveryReference,undefined);
  assert.equal((await request(`/admin/customization-orders/${order.id}`,'admin',{version:r.data.version,status:'delivered',fields:{deliveryReference:'fake'}})).status,400);
  assert.equal((await request(`/v1/me/customization-orders/${order.id}/action`,'other',{version:r.data.version,action:'accept_delivery'})).status,404);
  r=await request(`/v1/me/customization-orders/${order.id}/action`,'user',{version:r.data.version,action:'request_revision',note:'adjust blue eyes'});
  assert.equal(r.status,200);assert.equal(r.data.status,'in_production');assert.equal(r.data.workflow.qcPassed,false);
  r=await request(`/v1/me/creator-tasks/${order.id}`,'creator',{version:r.data.version,action:'submit',fields:{deliverableReference:'private-delivery-2'}});
  assert.equal((await request(`/admin/customization-orders/${order.id}`,'admin',{version:r.data.version,status:'user_acceptance',fields:{qcPassed:true}})).data.code,'ORDER_DELIVERY_REQUIRED');
  r=await request(`/admin/customization-orders/${order.id}`,'admin',{version:r.data.version,status:'user_acceptance',fields:{qcPassed:true,deliveryReference:'package-2'}});
  r=await request(`/v1/me/customization-orders/${order.id}/action`,'user',{version:r.data.version,action:'accept_delivery'});
  assert.equal(r.data.status,'delivered');assert.equal(store.getCustomizationOrder(order.id).acceptedAt,r.data.acceptedAt);
});

test('customer can remove wrong reference before production, version guards prevent stale removal',async t=>{
  const {request,order}=await fixture(t);
  const png=Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),Buffer.alloc(40)]);
  const uploaded=await request(`/v1/me/customization-orders/${order.id}/materials?slot=replace`,'user',png,{'Content-Type':'image/png'});
  const material=uploaded.data.materials[0];
  // Use fixture transport method override reserved for this destructive operation.
  const before=uploaded.data.version;
  assert.equal((await request(`/v1/me/customization-orders/${order.id}/materials/${material.id}?version=${before-1}`,'user',undefined,{},'DELETE')).status,409);
  assert.equal((await request(`/v1/me/customization-orders/${order.id}/materials/${material.id}?version=${before}`,'other',undefined,{},'DELETE')).status,404);
  const removed=await request(`/v1/me/customization-orders/${order.id}/materials/${material.id}?version=${before}`,'user',undefined,{},'DELETE');
  assert.equal(removed.status,200);assert.equal(removed.data.materials.length,0);assert.equal(removed.data.materialsUploaded,false);
  assert.equal((await request(`/admin/customization-orders/${order.id}/materials/${material.id}`)).status,404);
});
