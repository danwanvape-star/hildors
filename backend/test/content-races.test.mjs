import test from 'node:test';
import assert from 'node:assert/strict';
import { request } from 'node:http';
import { mkdtemp, readFile, readdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createStore } from '../src/store.mjs';
import { app } from '../src/server.mjs';

async function setup(t) {
  const directory = await mkdtemp(join(tmpdir(), 'hildors-races-'));
  const store = createStore(); let inspections = 0;
  const server = app(store, {adminToken:'admin',mediaDirectory:directory,inspector:async()=>{inspections++; return {status:'checked'};}});
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  t.after(async()=>{await new Promise(resolve=>server.close(resolve));store.close();await rm(directory,{recursive:true});});
  return {store,directory,base:`http://127.0.0.1:${server.address().port}`,inspections:()=>inspections};
}

test('slow creator inspect rejects a version made stale while its body is arriving', async t => {
  const {store,base,inspections} = await setup(t);
  const user=store.createUser(), profile=store.upsertCreatorProfile(user,{displayName:'Creator',email:'race@example.test'});
  store.reviewCreatorProfile(profile.id,profile.version,'approved');
  const token=store.createSession(user);
  let item=store.create({title:'Story',description:'Background',format:'single',source:'creator',ownerId:user,submissionStatus:'draft',tags:[],clips:[{id:'c',title:'Clip'}]});
  item=store.attachMedia(item.id,'c',item.version,{id:'media-race'});
  let reached; const bodyStarted=new Promise(resolve=>{reached=resolve;});
  const originalGet=store.get; store.get=id=>{const value=originalGet(id);if(id===item.id)reached();return value;};
  let pendingRequest;
  const response=new Promise((resolve,reject)=>{
    pendingRequest=request(base+`/v1/me/content/${item.id}/clips/c/inspect`,{method:'POST',headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'}},res=>{res.resume();res.on('end',()=>resolve(res.statusCode));});
    pendingRequest.on('error',reject); pendingRequest.write('{"version":');
  });
  await bodyStarted;
  const updated=store.updateMetadata(item.id,item.version,{title:'Updated',description:'Revised background',tags:[]});
  pendingRequest.end(`${item.version}}`);
  assert.equal(await response,409);
  assert.equal(inspections(),0);
  assert.equal(store.get(item.id).version,updated.version);
});

test('rejected admin cover attachment cleans its temporary uploaded file', async t => {
  const {store,base,directory}=await setup(t);
  const item=store.create({title:'Pending',format:'package',ownerId:'creator',submissionStatus:'pending',clips:[{id:'c'}]});
  const photo=await readFile(new URL('../../assets/images/hildors_logo.jpg',import.meta.url));
  const response=await fetch(base+`/admin/packages/${item.id}/cover`,{method:'PUT',headers:{Authorization:'Bearer admin','Content-Type':'image/jpeg','If-Match':String(item.version)},body:photo});
  assert.equal(response.status,409);
  assert.deepEqual(await readdir(directory),[]);
});
