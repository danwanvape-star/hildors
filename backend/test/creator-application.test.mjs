import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, readdir, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createStore } from '../src/store.mjs';
import { app } from '../src/server.mjs';
import { inspectVideo } from '../src/processor.mjs';

const draft = {displayName:'Video Maker',email:'maker@example.test',characterTags:['神话传说'],skillTags:['简单动作'],marketRegion:'CN',agreementVersion:'v2',adultConfirmed:true,agreementAccepted:true};
const mp4 = Buffer.concat([Buffer.from([0,0,0,24]),Buffer.from('ftypisom'),Buffer.alloc(32)]);
async function fixture(t, inspector = async () => ({status:'checked',validation:'decoded',durationSeconds:1})) {
  const directory = await mkdtemp(join(tmpdir(),'creator-application-')), store = createStore();
  const server = app(store,{adminToken:'admin-test',mediaDirectory:directory,inspector});
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  t.after(async()=>{await new Promise(resolve=>server.close(resolve));store.close();await rm(directory,{recursive:true,force:true});});
  const user=store.createUser(), other=store.createUser(), token=store.createSession(user), otherToken=store.createSession(other);
  const request=async(path,{method='GET',body,auth=token,headers={}}={})=>{
    const r=await fetch(`http://127.0.0.1:${server.address().port}${path}`,{method,headers:{Authorization:`Bearer ${auth}`,'Content-Type':Buffer.isBuffer(body)?'video/mp4':'application/json',...headers},body:body===undefined?undefined:Buffer.isBuffer(body)?body:JSON.stringify(body)});
    return {status:r.status,headers:r.headers,data:r.headers.get('content-type')?.includes('json')?await r.json():Buffer.from(await r.arrayBuffer())};
  };
  const save=(value=draft)=>request('/v1/me/creator-application',{method:'POST',body:value});
  const upload=version=>request('/v1/me/creator-application/videos?name=demo.mp4',{method:'PUT',body:mp4,headers:{'If-Match':String(version)}});
  return {store,directory,user,token,otherToken,request,save,upload};
}

test('application drafts validate system tags, directions, consent and optimistic versions',async t=>{
  const f=await fixture(t);
  for(const patch of [{characterTags:['invented']},{skillTags:['3D']},{adultConfirmed:false},{agreementAccepted:false}]) assert.equal((await f.save({...draft,...patch})).status,400);
  let r=await f.save(); assert.equal(r.status,200); assert.equal(r.data.status,'draft'); assert.equal(r.data.applicationVersion,2); assert.deepEqual(r.data.applicationVideos,[]);
  assert.equal((await f.save({...draft,version:r.data.version-1})).status,409);
  r=await f.save({...draft,version:r.data.version,displayName:'Updated'}); assert.equal(r.data.displayName,'Updated');
  assert.equal((await f.request('/v1/me/creator-profile')).data.applicationVersion,2);
  assert.equal((await f.request('/v1/me/creator-application/submit',{method:'POST',body:{version:r.data.version}})).data.code,'CREATOR_APPLICATION_VIDEO_REQUIRED');
});

test('checked application videos are private, ranged, versioned and locked after submission',async t=>{
  const f=await fixture(t); let r=await f.save(); r=await f.upload(r.data.version);
  assert.equal(r.status,200); const profile=r.data, video=profile.applicationVideos[0]; assert.equal(video.inspection.validation,'decoded');
  assert.equal(f.store.list().length,0);
  const path=`/v1/me/creator-application/videos/${video.id}`;
  const ranged=await f.request(path,{headers:{Range:'bytes=0-11'}}); assert.equal(ranged.status,206); assert.deepEqual(ranged.data,mp4.subarray(0,12));
  assert.equal((await f.request(path,{auth:f.otherToken})).status,404);
  assert.equal((await f.request(`/v1/media/${video.id}`)).status,404);
  assert.equal((await f.request(`/admin/creators/${profile.id}/application-videos/${video.id}`,{auth:'admin-test'})).status,200);
  assert.equal((await f.request(`/admin/creators/${profile.id}/application-videos/${video.id}`)).status,401);
  r=await f.request('/v1/me/creator-application/submit',{method:'POST',body:{version:profile.version}}); assert.equal(r.data.status,'pending');
  assert.equal((await f.save({...draft,version:r.data.version})).status,409);
  assert.equal((await f.upload(r.data.version)).status,409);
  assert.equal((await f.request(`${path}?version=${r.data.version}`,{method:'DELETE'})).status,409);
});

test('failed decode cleans all artifacts and leaves version unchanged for retry',async t=>{
  let succeeds=false;
  const f=await fixture(t,async(directory,id)=>{await writeFile(join(directory,`${id}.jpg`),'thumbnail');return succeeds?{status:'checked',validation:'decoded'}:{status:'failed',code:'INVALID_VIDEO'};});
  const initial=(await f.save()).data;
  const failed=await f.upload(initial.version); assert.equal(failed.status,422); assert.equal(f.store.getCreatorProfile(f.user).version,initial.version);
  assert.deepEqual(await readdir(join(f.directory,'creator-applications')),[]);
  succeeds=true; assert.equal((await f.upload(initial.version)).status,200);
});

test('revocation and concurrent draft edits during decode reject attachment and clean files',async t=>{
  let duringDecode=()=>{};
  const f=await fixture(t,async()=>{duringDecode();return {status:'checked',validation:'decoded'};});
  let p=(await f.save()).data;
  duringDecode=()=>f.store.saveCreatorApplication(f.user,{...draft,version:p.version,displayName:'Concurrent'});
  assert.equal((await f.upload(p.version)).status,409); assert.deepEqual(await readdir(join(f.directory,'creator-applications')),[]);
  p=f.store.getCreatorProfile(f.user); duringDecode=()=>f.store.revokeSession(f.token);
  assert.equal((await f.upload(p.version)).status,401); assert.deepEqual(await readdir(join(f.directory,'creator-applications')),[]);
  assert.equal(f.store.getCreatorProfile(f.user).applicationVideos.length,0);
});

test('rejection allows delete and resubmit while legacy endpoint cannot erase v2 certification',async t=>{
  const f=await fixture(t); let p=(await f.save()).data; p=(await f.upload(p.version)).data;
  p=(await f.request('/v1/me/creator-application/submit',{method:'POST',body:{version:p.version}})).data;
  p=f.store.manageCreatorProfile(p.id,p.version,{status:'rejected',note:'Need another video'});
  assert.equal((await f.request('/v1/me/creator-profile',{method:'POST',body:{...draft,portfolioUrl:''}})).status,409);
  assert.throws(()=>f.store.upsertCreatorProfile(f.user,draft),/MIGRATION_REQUIRED/);
  const video=p.applicationVideos[0]; p=(await f.request(`/v1/me/creator-application/videos/${video.id}?version=${p.version}`,{method:'DELETE'})).data;
  assert.equal(p.applicationVideos.length,0); assert.equal(p.reviewNote,'Need another video');
  assert.deepEqual(await readdir(join(f.directory,'creator-applications')),[]);
  p=(await f.upload(p.version)).data;
  assert.equal((await f.request('/v1/me/creator-application/submit',{method:'POST',body:{version:p.version}})).data.status,'pending');
});

test('new legacy enrollment is blocked, pending legacy upgrades, approved identity stays approved',async t=>{
  const f=await fixture(t);
  assert.equal((await f.request('/v1/me/creator-profile',{method:'POST',body:{...draft,portfolioUrl:''}})).data.code,'CREATOR_APPLICATION_MIGRATION_REQUIRED');
  let p=f.store.upsertCreatorProfile(f.user,{...draft,portfolioUrl:''});
  const migrated=await f.save({...draft,version:p.version}); assert.equal(migrated.data.status,'draft'); assert.equal(migrated.data.id,p.id);
  assert.throws(()=>f.store.reviewCreatorProfile(p.id,migrated.data.version,'approved'),/INVALID_CREATOR_PROFILE/);
  const user=f.store.createUser(),token=f.store.createSession(user);
  p=f.store.upsertCreatorProfile(user,{...draft,email:'legacy@example.test',portfolioUrl:''}); p=f.store.manageCreatorProfile(p.id,p.version,{status:'approved',abilityLevel:'gold'});
  const edit=await f.request('/v1/me/creator-profile',{method:'POST',auth:token,body:{...draft,email:'legacy@example.test',portfolioUrl:''}});
  assert.equal(edit.data.status,'approved');
  assert.equal(edit.data.abilityLevel,'gold');
  assert.equal((await f.request('/v1/me/creator-application',{method:'POST',auth:token,body:{...draft,version:edit.data.version}})).status,409);
});

test('video upload caps ten attachments and rejects stale versions without attaching files',async t=>{
  const f=await fixture(t); let p=(await f.save()).data;
  for(let n=0;n<10;n++) {const r=await f.upload(p.version);assert.equal(r.status,200);p=r.data;}
  assert.equal((await f.upload(p.version)).data.code,'CREATOR_APPLICATION_VIDEO_LIMIT');
  assert.equal((await f.upload(p.version-1)).status,409);
  assert.equal((await readdir(join(f.directory,'creator-applications'))).length,10);
});

test('application inspection shares the server processing limit and cleans a busy retry',async t=>{
  let started; const finishes=[];
  const begun=new Promise(resolve=>{started=resolve;});
  const f=await fixture(t,async()=>{started();await new Promise(resolve=>{finishes.push(resolve);});return {status:'checked',validation:'decoded'};});
  const p=(await f.save()).data;
  const first=f.upload(p.version);await begun;
  try {
    const second=await Promise.race([f.upload(p.version),new Promise(resolve=>setTimeout(()=>resolve({status:0}),1000))]);
    assert.equal(second.status,409);
    assert.equal(second.data.code,'PROCESSOR_BUSY');
  } finally { for(const finish of finishes) finish(); }
  assert.equal((await first).status,200);
  assert.equal((await readdir(join(f.directory,'creator-applications'))).length,1);
});

test('real certification MP4 is decoded before attachment and malformed MP4 is cleaned', {skip:process.env.HILDORS_MEDIA_INTEGRATION!=='1'},async t=>{
  const f=await fixture(t,inspectVideo);const initial=(await f.save()).data;
  assert.equal((await f.upload(initial.version)).status,422);
  assert.deepEqual(await readdir(join(f.directory,'creator-applications')),[]);
  const video=await readFile(new URL('../../assets/videos/showcase/showcase_02.mp4',import.meta.url));
  const r=await f.request('/v1/me/creator-application/videos?name=real.mp4',{method:'PUT',body:video,headers:{'If-Match':String(initial.version)}});
  assert.equal(r.status,200);assert.equal(r.data.applicationVideos[0].inspection.validation,'decoded');
  assert.ok(r.data.applicationVideos[0].inspection.durationSeconds>0);
});
