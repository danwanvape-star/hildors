import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, readFile, writeFile, rm } from 'node:fs/promises';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { execFileSync } from 'node:child_process';
import { app } from '../src/server.mjs';
import { createStore } from '../src/store.mjs';
import { findTool } from '../src/processor.mjs';
const id='87654321-1234-1234-1234-123456789abc';
test('private image variants enforce owner/admin/assigned creator access and retain originals',async()=>{
 const directory=await mkdtemp(join(tmpdir(),'hildors-private-image-'));
 const store=createStore(), server=app(store,{adminToken:'admin',mediaDirectory:directory});
 try {
  const source=join(directory,`${id}.png`);
  execFileSync(findTool('ffmpeg'),['-v','error','-f','lavfi','-i','testsrc2=size=1600x1200,noise=alls=30:allf=t','-frames:v','1',source],{windowsHide:true});
  const original=await readFile(source), image={id,extension:'png',contentType:'image/png',bytes:original.length};
  const customer=store.createUser(), stranger=store.createUser(), maker=store.createUser();
  const customerToken=store.createSession(customer), strangerToken=store.createSession(stranger), makerToken=store.createSession(maker);
  let profile=store.upsertCreatorProfile(maker,{displayName:'Maker',email:'image@example.test'});
  profile=store.manageCreatorProfile(profile.id,profile.version,{status:'approved',canReceiveOrders:true});
  let order=store.createCustomizationOrder(customer,{characterName:'Test',materialCount:0,requestedFeatures:[]});
  order=store.attachOrderMaterial(order.id,customer,{...image,name:'Reference'},'front');
  order=store.updateCustomizationOrderWorkflow(order.id,order.version,'approved_for_quote');
  order=store.dispatchOrder(order.id,{version:order.version,mode:'direct',creatorId:profile.id});
  const draft=store.create({title:'Cover',source:'creator',format:'package',tags:[],clips:[{id:'one',title:'One'}]});
  store.attachCover(draft.id,draft.version,image);
  await mkdir(join(directory,'order-materials'));await writeFile(join(directory,'order-materials',`${id}.png`),original);
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const base=`http://127.0.0.1:${server.address().port}`;
  const path=`/v1/me/customization-orders/${order.id}/materials/${id}`;
  const auth=token=>({Authorization:`Bearer ${token}`});
  assert.equal((await fetch(base+path+'?variant=preview')).status,401);
  assert.equal((await fetch(base+path+'?variant=preview',{headers:auth(strangerToken)})).status,404);
  assert.equal((await fetch(base+`/admin/covers/${id}?variant=preview`)).status,401);
  for(const [route,token] of [[path,customerToken],[`/admin/customization-orders/${order.id}/materials/${id}`,'admin'],[`/v1/me/creator-tasks/${order.id}/materials/${id}`,makerToken],[`/admin/covers/${id}`,'admin']]) {
   for(const [variant,edge] of [['thumbnail',384],['preview',1024]]) {
    const response=await fetch(base+route+`?variant=${variant}`,{headers:auth(token)});
    assert.equal(response.status,200);assert.equal(response.headers.get('cache-control'),'no-store');assert.equal(response.headers.get('content-type'),'image/jpeg');
    const bytes=Buffer.from(await response.arrayBuffer());assert.ok(bytes.length<original.length);
    const inspect=join(directory,`check-${variant}.jpg`);await writeFile(inspect,bytes);
    const info=JSON.parse(execFileSync(findTool('ffprobe'),['-v','error','-show_streams','-of','json',inspect]));
    assert.equal(info.streams[0].width,edge);assert.equal(info.streams[0].height,edge*3/4);
   }
   const response=await fetch(base+route,{headers:auth(token)});assert.deepEqual(Buffer.from(await response.arrayBuffer()),original);
   assert.equal((await fetch(base+route+'?variant=bad',{headers:auth(token)})).status,400);
  }
  // Revocation after route authorization must still prevent cached derivative delivery.
  const get=store.getCustomizationOrder.bind(store); let reads=0;
  store.getCustomizationOrder=oid=>{const value=get(oid);if(++reads===2)store.revokeSession(customerToken);return value;};
  assert.equal((await fetch(base+path+'?variant=preview',{headers:auth(customerToken)})).status,401);
  assert.deepEqual(await readFile(source),original);
 } finally {await new Promise(resolve=>server.close(resolve));store.close();await rm(directory,{recursive:true,force:true});}
});
