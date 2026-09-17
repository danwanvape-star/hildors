import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { randomUUID, createHash } from 'node:crypto';
import { createStore } from '../src/store.mjs';
import { app } from '../src/server.mjs';

const free = { mode: 'free', currency: 'USD', amountMinor: 0 };
const paid = { mode: 'paid', currency: 'USD', amountMinor: 199 };
async function fixture(t, pricing) {
  const directory = await mkdtemp(join(tmpdir(), 'clip-pricing-'));
  const store = createStore();
  const user = store.createUser(), token = store.createSession(user);
  const bytes = Buffer.from('pricing delivery fixture'), id = randomUUID();
  await writeFile(join(directory, `${id}.mp4`), bytes);
  await writeFile(join(directory, `${id}.jpg`), Buffer.from([255,216,255,217]));
  let item = store.create({ title:'priced', description:'fixture', source:'hildors', format:'single', tags:[], clips:[{id:'clip',title:'clip', ...(pricing === undefined ? {} : {pricing})}] });
  store.attachMedia(item.id,'clip',item.version,{id,bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')});
  item = store.setInspection(item.id,'clip',id,{status:'checked'});
  item = store.review(item.id,item.version,'approved','fixture','fixture');
  item = store.transition(item.id,item.version,'published');
  const server = app(store,{adminToken:'pricing-admin',mediaDirectory:directory,enableDownloads:true});
  await new Promise(r => server.listen(0,'127.0.0.1',r));
  t.after(async()=>{await new Promise(r=>server.close(r));store.close();await rm(directory,{recursive:true,force:true});});
  const request = (path, options={})=>fetch(`http://127.0.0.1:${server.address().port}${path}`,options);
  const save = (pricing, version=store.get(item.id).version, auth='pricing-admin')=>request(`/admin/packages/${item.id}/clips/clip/pricing`,{method:'POST',headers:{Authorization:`Bearer ${auth}`,'Content-Type':'application/json'},body:JSON.stringify({version,pricing})});
  const delivery = action=>request(`/v1/me/packages/${item.id}/clips/clip/${action}`,{headers:{Authorization:`Bearer ${token}`}});
  return {store,item,user,token,id,request,save,delivery,bytes,directory};
}

test('pricing API validates USD minor units, authenticates, versions and audits persisted edits',async t=>{
  const f=await fixture(t), version=f.item.version;
  assert.equal((await f.save(paid,version,'wrong')).status,401);
  for(const pricing of [null,{}, {...paid,currency:'CNY'}, {...free,amountMinor:1}, {...paid,amountMinor:0}, {...paid,amountMinor:-1}, {...paid,amountMinor:1.5}, {...paid,amountMinor:100000000}, {...paid,amountMinor:'199'}]) {
    assert.equal((await f.save(pricing)).status,400);
    assert.equal(f.store.get(f.item.id).version,version);
  }
  assert.equal((await f.save(paid,version+1)).status,409);
  const saved=await f.save(paid); assert.equal(saved.status,200);
  assert.deepEqual((await saved.json()).clips[0].pricing,paid);
  assert.equal(f.store.get(f.item.id).version,version+1);
  assert.match(f.store.auditLog()[0].action,/clip_pricing_updated:clip/);
  assert.equal((await f.save(free,version)).status,409);
  assert.deepEqual(f.store.get(f.item.id).clips[0].pricing,paid);
  assert.throws(()=>f.store.updateClipPricing(f.item.id,'clip',version+1,{...paid,amountMinor:0}),/INVALID_PRICING/);
});

test('free delivery requires no entitlement; paid never inherits package entitlement and revokes public full preview',async t=>{
  const f=await fixture(t);
  assert.equal((await (await f.delivery('access')).json()).canDownload,false);
  assert.equal((await f.save(free)).status,200);
  assert.equal((await (await f.delivery('access')).json()).canDownload,true);
  assert.deepEqual(Buffer.from(await (await f.delivery('download')).arrayBuffer()),f.bytes);
  assert.equal((await f.delivery('manifest')).status,200);
  f.store.setEntitlement(f.user,f.item.id,'active','fixture');
  assert.equal((await f.save(paid)).status,200);
  assert.equal((await (await f.delivery('access')).json()).canDownload,false);
  assert.equal((await f.delivery('manifest')).status,404);
  assert.equal((await f.delivery('download')).status,404);
  assert.equal((await f.request(`/v1/media/${f.id}`,{headers:{Range:'bytes=0-3'}})).status,404);
  assert.equal((await f.request(`/v1/media/${f.id}/thumbnail`)).status,200);
  const catalog=await (await f.request('/v1/catalog')).json();
  assert.deepEqual(catalog.items[0].clips[0].pricing,paid);
  assert.equal(catalog.items[0].clips[0].previewPath,undefined);
  assert.ok(catalog.items[0].clips[0].thumbnailPath);
  assert.equal((await f.save(free)).status,200);
  assert.equal((await f.request(`/v1/media/${f.id}`)).status,200);
});

test('configured invalid pricing fails closed even with entitlement, while unspecified legacy retains access',async t=>{
  const f=await fixture(t);
  f.store.setEntitlement(f.user,f.item.id,'active','fixture');
  assert.equal((await (await f.delivery('access')).json()).canDownload,true);
  assert.equal((await (await f.request('/v1/catalog')).json()).items[0].clips[0].pricing,undefined);
  const corrupt = await fixture(t, {mode:'free',currency:'USD',amountMinor:5});
  corrupt.store.setEntitlement(corrupt.user,corrupt.item.id,'active','legacy-import');
  assert.equal((await (await corrupt.delivery('access')).json()).canDownload,false);
  assert.equal((await corrupt.delivery('download')).status,404);
  assert.equal((await corrupt.request(`/v1/media/${corrupt.id}`)).status,404);
});

test('paid limits include one cent and maximum; free siblings cannot expose a shared paid file',async t=>{
  const f=await fixture(t);
  for(const amountMinor of [1,99999999]) assert.equal((await f.save({...paid,amountMinor})).status,200);
  let sibling=f.store.create({title:'shared',source:'hildors',format:'single',tags:[],clips:[{id:'shared',pricing:free}]});
  sibling=f.store.attachMedia(sibling.id,'shared',sibling.version,{...f.store.get(f.item.id).clips[0].media});
  sibling=f.store.review(sibling.id,sibling.version,'approved','fixture','fixture');
  f.store.transition(sibling.id,sibling.version,'published');
  const access = action => f.request(`/v1/me/packages/${sibling.id}/clips/shared/${action}`, {headers:{Authorization:`Bearer ${f.token}`}});
  assert.equal((await (await access('access')).json()).canDownload,false);
  assert.equal((await access('manifest')).status,404);
  assert.equal((await access('download')).status,404);
  assert.equal((await f.request(`/v1/media/${f.id}`)).status,404);
  assert.equal((await f.request(`/v1/media/${f.id}/thumbnail`)).status,200);
});
import { serveMedia } from '../src/media.mjs';

test('media preflight rechecks price after asynchronous stat and denies before streaming',async t=>{
  const f=await fixture(t);
  f.store.updateClipPricing(f.item.id,'clip',f.item.version,free);
  const response={writeHead(){throw new Error('stream headers leaked before authorization');},end(){throw new Error('unexpected stream end');}};
  let checked=false;
  const streaming=serveMedia({headers:{}},response,f.directory,f.id,{preflight:()=>{
    checked=true; return f.store.get(f.item.id).clips[0].pricing.mode==='free';
  }});
  f.store.updateClipPricing(f.item.id,'clip',f.item.version+1,paid);
  await streaming;
  assert.equal(checked,true);
});
