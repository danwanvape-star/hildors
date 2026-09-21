import test from 'node:test';
import assert from 'node:assert/strict';
import {createStore} from '../src/store.mjs';

test('deletion requests are scoped, idempotent, cancellable and cannot claim completed deletion', t=>{
 const store=createStore(); t.after(()=>store.close());
 const a=store.createUser(), b=store.createUser();
 const session=store.createDeviceSession(a);
 assert.throws(()=>store.requestAccountDeletion(a,{}),/INVALID_INPUT/);
 const r=store.requestAccountDeletion(a,{confirm:true});
 assert.equal(r.status,'received');
 assert.equal(store.requestAccountDeletion(a,{confirm:true}).id,r.id);
 assert.equal(store.accountDeletionRequest(b),null);
 assert.throws(()=>store.reviewAccountDeletion(r.id,{version:1,status:'deleted'}),/INVALID_INPUT/);
 assert.throws(()=>store.reviewAccountDeletion(r.id,{version:1,status:'needs_information',message:''}),/INVALID_INPUT/);
 const review=store.reviewAccountDeletion(r.id,{version:1,status:'in_review'});
 assert.equal(review.version,2);
 assert.throws(()=>store.cancelAccountDeletion(b,{version:2}),/CONFLICT/);
 assert.throws(()=>store.cancelAccountDeletion(a,{version:1}),/CONFLICT/);
 assert.equal(store.cancelAccountDeletion(a,{version:2}).status,'cancelled');
 assert.equal(store.authenticate(session.token),a);
 assert.equal(store.requestAccountDeletion(a,{confirm:true}).version,4);
});

import {app} from '../src/server.mjs';
import {accountDeletionRoute} from '../src/account-deletion.mjs';

test('HTTP account deletion intake verifies identity, isolates status and supports operator review',async t=>{
 const store=createStore();const owner=store.createUser(),other=store.createUser();
 const token=store.createSession(owner),otherToken=store.createSession(other);
 const server=app(store,{adminToken:'test-admin'});
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 t.after(async()=>{await new Promise(resolve=>server.close(resolve));store.close();});
 const base=`http://127.0.0.1:${server.address().port}`;
 const call=(path,auth,body)=>fetch(base+path,{method:body?'POST':'GET',headers:{...(auth?{Authorization:`Bearer ${auth}`} :{}),...(body?{'Content-Type':'application/json'}:{})},body:body?JSON.stringify(body):undefined});
 assert.equal((await call('/v1/me/deletion-request')).status,401);
 assert.equal((await call('/admin/account-deletions',token)).status,401);
 const created=await (await call('/v1/me/deletion-request',token,{confirm:true,userId:other})).json();
 assert.equal(created.request.status,'received');
 assert.equal((await (await call('/v1/me/deletion-request',otherToken)).json()).request,null);
 const listed=await (await call('/admin/account-deletions','test-admin')).json();assert.equal(listed.items[0].userId,owner);
 assert.equal((await call('/admin/account-deletions/'+created.request.id,'test-admin',{version:1,status:'in_review'})).status,200);
 assert.equal((await (await call('/v1/me/deletion-request',token)).json()).request.status,'in_review');
 assert.equal((await call('/admin/account-deletions/'+created.request.id,'test-admin',{version:2,status:'deleted'})).status,400);
 assert.equal((await call('/v1/me/deletion-request/cancel',token,{version:2})).status,200);
 const web=await call('/account-deletion');assert.equal(web.status,200);assert.match(web.headers.get('content-security-policy'),/script-src 'self'/);
 assert.match(await web.text(),/does not immediately delete/);
});

test('deletion request rechecks session after asynchronous body read',async t=>{
 const store=createStore();t.after(()=>store.close());const userId=store.createUser();let valid=true,result;
 await accountDeletionRoute({req:{method:'POST'},url:new URL('http://local/v1/me/deletion-request'),store,userId,
 authorized:()=>valid,send:(s,b)=>result=[s,b],fail:(s,b)=>result=[s,b],readJson:async()=>{valid=false;return {confirm:true};}});
 assert.equal(result[0],401);assert.equal(store.accountDeletionRequest(userId),null);
});
