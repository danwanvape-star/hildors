import test from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { createStore, seedDemos } from '../src/store.mjs';
import { app } from '../src/server.mjs';
import { authorizedClip } from '../src/delivery.mjs';
import { visiblePackage, editableClip } from '../src/package-clips.mjs';

const free = {mode:'free',currency:'USD',amountMinor:0};
function draft(store, format = 'single', extra = {}) {
  return store.create({title:'Lifecycle',description:'Description',source:'hildors',tags:['东方仙侠'],format,
    cover:format === 'package' ? {id:randomUUID(),extension:'jpg'} : undefined,
    clips:[{id:'main',title:'Main',pricing:free,media:{id:randomUUID(),bytes:32,sha256:'a'.repeat(64),inspection:{status:'checked'}}}],...extra});
}
function published(store, format = 'single', extra = {}) {
  let item = draft(store, format, extra);
  item = store.review(item.id,item.version,'approved','Reviewed','Licensed');
  return store.transition(item.id,item.version,'published');
}

test('single and package lifecycle preserves evidence, versions and explicit publication', t => {
  const store=createStore(); t.after(()=>store.close());
  for (const format of ['single','package']) {
    let item=published(store,format); const {id}=item, review=item.review, media=item.clips[0].media;
    assert.throws(()=>store.deletePackage(id,item.version),/CONFLICT/);
    item=store.transition(id,item.version,'withdrawn');
    assert.throws(()=>store.transition(id,item.version-1,'published'),/CONFLICT/);
    item=store.transition(id,item.version,'published');
    assert.equal(item.status,'published'); assert.deepEqual(item.review,review);
    item=store.transition(id,item.version,'withdrawn');
    const deleted=store.deletePackage(id,item.version);
    assert.equal(deleted.version,item.version+1); assert.ok(deleted.deletedAt);
    assert.equal(store.get(id),null); assert.ok(!store.list().some(x=>x.id===id));
    assert.deepEqual(store.get(id,{includeDeleted:true}).clips[0].media,media);
    assert.throws(()=>store.deletePackage(id,deleted.version),/CONFLICT/);
    assert.throws(()=>store.restorePackage(id,deleted.version-1),/CONFLICT/);
    assert.throws(()=>store.updateClipPricing(id,'main',deleted.version,free),/CONFLICT/);
    item=store.restorePackage(id,deleted.version);
    assert.equal(item.status,'withdrawn'); assert.equal(item.deletedAt,undefined); assert.ok(item.restoredAt);
    assert.equal(visiblePackage(item),false); assert.deepEqual(item.review,review);
    assert.throws(()=>store.restorePackage(id,item.version),/CONFLICT/);
    item=store.transition(id,item.version,'published'); assert.equal(visiblePackage(item),true);
    assert.deepEqual(store.auditLog().filter(x=>x.package_id===id).slice(0,3).map(x=>x.action),['published','restored','deleted']);
  }
});

test('draft and rejected content restores privately and demo seeding does not resurrect trash', t=>{
  const store=createStore();t.after(()=>store.close());
  let item=draft(store);item=store.review(item.id,item.version,'rejected','Fix rights');
  item=store.deletePackage(item.id,item.version);item=store.restorePackage(item.id,item.version);
  assert.equal(item.status,'draft'); assert.equal(item.review.decision,'rejected');
  assert.throws(()=>store.transition(item.id,item.version,'published'),/MEDIA_REVIEW_REQUIRED/);
  seedDemos(store);let demo=store.get('hildors_demo_01');demo=store.transition(demo.id,demo.version,'withdrawn');
  store.deletePackage(demo.id,demo.version);assert.doesNotThrow(()=>seedDemos(store));assert.equal(store.get(demo.id),null);
});

test('withdrawn packages with every clip withdrawn can recover clips privately before republication',t=>{
  const store=createStore();t.after(()=>store.close());let item=published(store,'package');
  item=store.transitionClip(item.id,'main',item.version,'withdrawn');
  item=store.transition(item.id,item.version,'withdrawn');
  assert.throws(()=>store.transition(item.id,item.version,'published'),/MEDIA_REVIEW_REQUIRED/);
  item=store.transitionClip(item.id,'main',item.version,'restored');
  assert.equal(item.status,'withdrawn');assert.equal(visiblePackage(item),false);
  item=store.transition(item.id,item.version,'published');assert.equal(visiblePackage(item),true);
});

test('restoring an unreviewed appended clip cannot inherit the package approval',t=>{
  const store=createStore();t.after(()=>store.close());let item=published(store,'package');
  item=store.appendClip(item.id,item.version,'Unreviewed',{id:randomUUID(),inspection:{status:'checked'}});
  const added=item.clips.at(-1).id;
  item=store.transitionClip(item.id,added,item.version,'withdrawn');
  item=store.transition(item.id,item.version,'withdrawn');
  item=store.transitionClip(item.id,added,item.version,'restored');
  assert.equal(item.clips.at(-1).visibility,'draft');
  item=store.transition(item.id,item.version,'published');
  assert.deepEqual(item.clips.filter(c=>!c.visibility||c.visibility==='published').map(c=>c.id),['main']);
  item=store.transitionClip(item.id,added,item.version,'published',{note:'Rights reviewed',rightsReference:'License'});
  assert.equal(item.clips.at(-1).visibility,'published');
  assert.ok(item.clips.at(-1).review);
});

test('reinspection and unknown legacy withdrawal history cannot restore a clip as approved',t=>{
  const store=createStore();t.after(()=>store.close());
  for(const legacy of [false,true]) {
    let item=published(store,'package');
    item=store.transitionClip(item.id,'main',item.version,'withdrawn');
    if(legacy) item=store.updateMetadata(item.id,item.version,{clips:item.clips.map(({visibilityBeforeWithdrawal,...clip})=>clip)});
    else item=store.setInspection(item.id,'main',item.clips[0].media.id,{status:'checked'});
    item=store.transition(item.id,item.version,'withdrawn');
    item=store.transitionClip(item.id,'main',item.version,'restored');
    assert.equal(item.clips[0].visibility,'draft');
    item=store.transition(item.id,item.version,'published');
    assert.equal(visiblePackage(item),false);
    item=store.transitionClip(item.id,'main',item.version,'published',{note:'Reviewed again'});
    assert.equal(visiblePackage(item),true);
  }
});

test('republishing rechecks creator qualification and pricing',t=>{
  const store=createStore();t.after(()=>store.close());const user=store.createUser();
  let profile=store.upsertCreatorProfile(user,{email:'creator@example.test',displayName:'Creator'});
  profile=store.manageCreatorProfile(profile.id,profile.version,{status:'approved',tier:'partner'});
  let item=draft(store,'single',{ownerId:user,submissionStatus:'pending'});
  item=store.review(item.id,item.version,'approved','Reviewed','Licensed');item=store.transition(item.id,item.version,'published');
  item=store.transition(item.id,item.version,'withdrawn');
  profile=store.manageCreatorProfile(profile.id,profile.version,{status:'suspended',note:'Suspended'});
  assert.throws(()=>store.transition(item.id,item.version,'published'),/CREATOR_APPROVAL_REQUIRED/);
  profile=store.manageCreatorProfile(profile.id,profile.version,{status:'approved',tier:'partner'});
  item=store.updateClipPricing(item.id,'main',item.version,{mode:'paid',currency:'USD',amountMinor:199});
  store.manageCreatorProfile(profile.id,profile.version,{status:'approved',tier:'standard'});
  assert.throws(()=>store.transition(item.id,item.version,'published'),/CREATOR_PAID_NOT_ALLOWED/);
});

test('explicit governance hold blocks both republication paths and survives recycle-bin restoration',t=>{
  const store=createStore();t.after(()=>store.close());
  let item=published(store,'package');
  item=store.transitionClip(item.id,'main',item.version,'withdrawn');
  item=store.updateMetadata(item.id,item.version,{governance:{hold:true,reason:'Rights verification'}});
  assert.throws(()=>store.transitionClip(item.id,'main',item.version,'published',{note:'Recheck'}),/CONTENT_GOVERNANCE_HOLD/);
  item=store.transition(item.id,item.version,'withdrawn');
  item=store.deletePackage(item.id,item.version);item=store.restorePackage(item.id,item.version);
  assert.equal(item.governance.hold,true);assert.equal(item.status,'withdrawn');
  // A second reviewed package isolates the hold from the all-clips-withdrawn check.
  let second=published(store,'package');second=store.transition(second.id,second.version,'withdrawn');
  second=store.updateMetadata(second.id,second.version,{governance:{hold:true}});
  assert.throws(()=>store.transition(second.id,second.version,'published'),/CONTENT_GOVERNANCE_HOLD/);
  second=store.deletePackage(second.id,second.version);second=store.restorePackage(second.id,second.version);
  assert.throws(()=>store.transition(second.id,second.version,'published'),/CONTENT_GOVERNANCE_HOLD/);
});

test('republishing rechecks inspected media and does not infer a hold from report status',t=>{
  const store=createStore();t.after(()=>store.close());
  let item=published(store);const user=store.createUser();
  const report=store.createContentReport(user,{packageId:item.id,reason:'other'});
  store.resolveContentReport(report.id,{version:report.version,status:'action_taken',resolution:'Contacted uploader'});
  item=store.transition(item.id,item.version,'withdrawn');
  item=store.transition(item.id,item.version,'published');assert.equal(item.status,'published');
  item=store.transition(item.id,item.version,'withdrawn');
  item=store.updateMetadata(item.id,item.version,{clips:item.clips.map(clip=>({...clip,media:{...clip.media,inspection:{status:'failed'}}}))});
  assert.throws(()=>store.transition(item.id,item.version,'published'),/MEDIA_REVIEW_REQUIRED/);
});

test('deleted content is absent from catalog, owner routes, entitlements, media and delivery',async t=>{
  const store=createStore(),user=store.createUser(),token=store.createSession(user);
  let profile=store.upsertCreatorProfile(user,{email:'owner@example.test',displayName:'Owner'});
  store.manageCreatorProfile(profile.id,profile.version,{status:'approved',tier:'standard'});
  let item=published(store,'package',{ownerId:user,submissionStatus:'pending'});
  store.setEntitlement(user,item.id,'active','grant');
  const server=app(store,{adminToken:'admin',enableDownloads:true});await new Promise(r=>server.listen(0,'127.0.0.1',r));
  t.after(async()=>{await new Promise(r=>server.close(r));store.close();});
  const request=async(path,body,auth=token)=>{
    const response=await fetch(`http://127.0.0.1:${server.address().port}${path}`,{method:body?'POST':'GET',headers:{Authorization:`Bearer ${auth}`,'Content-Type':'application/json'},body:body?JSON.stringify(body):undefined});
    return {status:response.status,data:await response.json()};
  };
  const base=`/admin/packages/${item.id}`;
  assert.equal((await request(base+'/delete',{version:item.version},'admin')).status,409);
  item=(await request(base+'/withdraw',{version:item.version},'admin')).data;
  item=(await request(base+'/publish',{version:item.version},'admin')).data;assert.equal(item.status,'published');
  item=(await request(base+'/withdraw',{version:item.version},'admin')).data;
  item=(await request(base+'/delete',{version:item.version},'admin')).data;assert.ok(item.deletedAt);
  assert.equal((await request(base+'/delete',{version:item.version},'admin')).status,409);
  assert.equal((await request(base+'/restore',{version:item.version-1},'admin')).status,409);
  assert.equal((await request('/admin/packages',undefined,'admin')).data.items[0].deletedAt,item.deletedAt);
  assert.deepEqual((await request('/v1/catalog')).data.items,[]);
  assert.deepEqual((await request('/v1/me/content')).data.items,[]);
  assert.deepEqual((await request('/v1/me/entitlements')).data.items,[]);
  for(const path of [`/v1/packages/${item.id}`,`/v1/me/content/${item.id}`,`/v1/media/${item.clips[0].media.id}`,`/v1/media/${item.clips[0].media.id}/thumbnail`,`/v1/covers/${item.cover.id}`,`/v1/me/packages/${item.id}/clips/main/manifest`,`/v1/me/packages/${item.id}/clips/main/download`]) {
    assert.equal((await request(path)).status,404,path);
  }
  assert.equal(authorizedClip(store,user,item.id,'main'),null);
  assert.equal((await request('/v1/me/reports',{packageId:item.id,reason:'other'})).status,404);
  assert.equal(visiblePackage({...item,status:'published'}),false);
  assert.equal(editableClip({...item,status:'draft'},item.clips[0]),false);
  assert.throws(()=>store.setEntitlement(user,item.id,'active','again'),/CONFLICT/);
  const restored=await request(base+'/restore',{version:item.version},'admin');assert.equal(restored.status,200);assert.equal(restored.data.status,'withdrawn');
  assert.equal((await request(`/v1/packages/${item.id}`)).status,404);
  assert.equal(authorizedClip(store,user,item.id,'main'),null);
});
