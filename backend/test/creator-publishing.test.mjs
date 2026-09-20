import test from 'node:test';
import assert from 'node:assert/strict';
import {createStore} from '../src/store.mjs';
import {app} from '../src/server.mjs';
const free={mode:'free',currency:'USD',amountMinor:0},paid={mode:'paid',currency:'USD',amountMinor:199};
async function fixture(t,tier='standard') {
 const store=createStore(),user=store.createUser(),token=store.createSession(user);
 let creator=store.upsertCreatorProfile(user,{email:`${user}@example.test`,displayName:'Creator'});
 creator=store.manageCreatorProfile(creator.id,creator.version,{status:'approved',tier,canPublish:false,note:'通过'});
 const server=app(store,{adminToken:'admin'});await new Promise(r=>server.listen(0,'127.0.0.1',r));
 t.after(async()=>{await new Promise(r=>server.close(r));store.close()});
 const request=async(path,body,auth=token)=>{const r=await fetch(`http://127.0.0.1:${server.address().port}${path}`,{method:body===undefined?'GET':'POST',headers:{Authorization:`Bearer ${auth}`,'Content-Type':'application/json'},body:body===undefined?undefined:JSON.stringify(body)});return {status:r.status,data:await r.json()}};
 const create=(format='single',pricing)=>request('/v1/me/content',{title:'作品',description:'角色故事',tags:['东方仙侠'],format,clips:[{id:'one',title:'one',...(pricing?{pricing}:{})}]});
 return {store,user,token,creator,request,create};
}
test('every approved tier may upload free standalone or package content and all drafts stay private',async t=>{
 for(const tier of ['standard','verified','partner']){
  const f=await fixture(t,tier),cap=await f.request('/v1/me/content-capabilities');
  assert.equal(cap.status,200);assert.equal(cap.data.canUpload,true);assert.equal(cap.data.canSetPaid,tier==='partner');
  for(const format of ['single','package']){const r=await f.create(format);assert.equal(r.status,201);assert.equal(r.data.status,'draft');assert.equal(r.data.submissionStatus,'draft');assert.deepEqual(r.data.clips[0].pricing,free);}
  assert.equal((await f.request('/v1/catalog')).data.items.length,0);
 }
});
test('only partners can create or price paid clips; ownership, states and versions are enforced',async t=>{
 for(const tier of ['standard','verified']){const f=await fixture(t,tier);assert.equal((await f.create('single',paid)).status,403);const item=(await f.create()).data;
  assert.equal((await f.request(`/v1/me/content/${item.id}/clips/one/pricing`,{version:item.version,pricing:paid})).status,403);
  assert.equal((await f.request(`/admin/packages/${item.id}/clips/one/pricing`,{version:item.version,pricing:paid},'admin')).status,403);
 }
 const f=await fixture(t,'partner'),item=(await f.create('single',paid)).data;
 assert.equal((await f.create('single',{...paid,amountMinor:1.5})).status,400);
 assert.deepEqual(item.clips[0].pricing,paid);
 const path=`/v1/me/content/${item.id}/clips/one/pricing`;
 assert.equal((await f.request(path,{version:item.version+1,pricing:free})).status,409);
 const other=f.store.createUser(),otherToken=f.store.createSession(other);let otherProfile=f.store.upsertCreatorProfile(other,{email:'other@example.test'});f.store.manageCreatorProfile(otherProfile.id,1,{status:'approved',tier:'partner'});
 assert.equal((await f.request(path,{version:item.version,pricing:free},otherToken)).status,404);
 let updated=await f.request(path,{version:item.version,pricing:free});assert.equal(updated.status,200);assert.deepEqual(updated.data.clips[0].pricing,free);
 assert.equal((await f.request(path,{version:updated.data.version,pricing:{...paid,amountMinor:1.5}})).status,400);
 const current=f.store.getCreatorProfile(f.user);f.store.manageCreatorProfile(current.id,current.version,{status:'suspended',note:'暂停'});
 assert.equal((await f.request(path,{version:updated.data.version,pricing:paid})).status,403);
});
test('partner submission requires moderation and downgrade cannot bypass paid-content review',async t=>{
 const f=await fixture(t,'partner');let item=(await f.create('single',paid)).data;
 item=f.store.attachMedia(item.id,'one',item.version,{id:'media'});item=f.store.setInspection(item.id,'one','media',{status:'checked'});
 item=f.store.submitContent(item.id,item.version);
 assert.equal(item.submissionStatus,'pending');assert.equal((await f.request(`/v1/me/content/${item.id}/clips/one/pricing`,{version:item.version,pricing:free})).status,409);
 assert.throws(()=>f.store.transition(item.id,item.version,'published'),/MEDIA_REVIEW_REQUIRED/);
 const profile=f.store.getCreatorProfile(f.user);f.store.manageCreatorProfile(profile.id,profile.version,{status:'approved',tier:'standard'});
 assert.throws(()=>f.store.review(item.id,item.version,'approved','审核','授权'),/CREATOR_PAID_NOT_ALLOWED/);
 const partner=f.store.getCreatorProfile(f.user);f.store.manageCreatorProfile(partner.id,partner.version,{status:'approved',tier:'partner'});
 item=f.store.review(item.id,item.version,'approved','审核','授权');
 const downgrade=f.store.getCreatorProfile(f.user);f.store.manageCreatorProfile(downgrade.id,downgrade.version,{status:'approved',tier:'verified'});
 assert.throws(()=>f.store.transition(item.id,item.version,'published'),/CREATOR_PAID_NOT_ALLOWED/);
 const restore=f.store.getCreatorProfile(f.user);f.store.manageCreatorProfile(restore.id,restore.version,{status:'approved',tier:'partner'});
 item=f.store.transition(item.id,item.version,'published');assert.equal(item.status,'published');
});
test('a paid package clip cannot be restored to publication after partner downgrade',async t=>{
 const f=await fixture(t,'partner');let item=(await f.create('package',paid)).data;
 item=f.store.attachMedia(item.id,'one',item.version,{id:'media',inspection:{status:'checked'}});
 item=f.store.attachCover(item.id,item.version,{id:'cover',extension:'jpg'});
 item=f.store.submitContent(item.id,item.version);item=f.store.review(item.id,item.version,'approved','审核','授权');item=f.store.transition(item.id,item.version,'published');
 item=f.store.transitionClip(item.id,'one',item.version,'withdrawn');
 const creator=f.store.getCreatorProfile(f.user);f.store.manageCreatorProfile(creator.id,creator.version,{status:'approved',tier:'standard'});
 assert.throws(()=>f.store.transitionClip(item.id,'one',item.version,'published',{note:'重新上架',rightsReference:'授权'}),/CREATOR_PAID_NOT_ALLOWED/);
});
