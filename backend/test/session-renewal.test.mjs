import test from 'node:test';
import assert from 'node:assert/strict';
import {createStore} from '../src/store.mjs';
import {app} from '../src/server.mjs';

test('device refresh preserves user and orders, invalid tokens fail and logout revokes refresh',async t=>{
 const store=createStore(),server=app(store);
 await new Promise(r=>server.listen(0,'127.0.0.1',r));
 t.after(async()=>{await new Promise(r=>server.close(r));store.close();});
 const base=`http://127.0.0.1:${server.address().port}`;
 const post=async(path,body,token)=>{const r=await fetch(base+path,{method:'POST',headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},body:JSON.stringify(body)});return {status:r.status,data:await r.json()};};
 const initial=await post('/v1/device-session',{});
 assert.equal(initial.status,201);assert.match(initial.data.refreshToken,/^[A-Za-z0-9_-]{43}$/);
 const user=store.authenticate(initial.data.token), order=store.createCustomizationOrder(user,{characterName:'Persistent order'});
 const refreshed=await post('/v1/session-refresh',{refreshToken:initial.data.refreshToken});
 assert.equal(refreshed.status,200);assert.equal(store.authenticate(refreshed.data.token),user);
 assert.equal(store.listCustomizationOrders(user)[0].id,order.id);
 assert.equal((await post('/v1/session-refresh',{refreshToken:'bad'})).status,401);
 await fetch(base+'/v1/me/session',{method:'DELETE',headers:{Authorization:`Bearer ${refreshed.data.token}`}});
 assert.equal((await post('/v1/session-refresh',{refreshToken:initial.data.refreshToken})).status,401);
});

test('valid legacy session can acquire refresh without changing identity',async t=>{
 const store=createStore(),server=app(store);await new Promise(r=>server.listen(0,'127.0.0.1',r));
 t.after(async()=>{await new Promise(r=>server.close(r));store.close();});
 const user=store.createUser(),token=store.createSession(user);
 const r=await fetch(`http://127.0.0.1:${server.address().port}/v1/me/session/renew`,{method:'POST',headers:{Authorization:`Bearer ${token}`}});
 assert.equal(r.status,200);const data=await r.json();assert.equal(store.authenticate(data.token),user);assert.match(data.refreshToken,/^[A-Za-z0-9_-]{43}$/);
});

test('refresh outlives access expiry but cannot outlive its own expiry',t=>{
 const store=createStore();t.after(()=>store.close());
 const user=store.createUser(),start=Date.now(),session=store.createDeviceSession(user);
 t.mock.method(Date,'now',()=>start+2*86400000);
 assert.equal(store.authenticate(session.token),null);
 const refreshed=store.refreshDeviceSession(session.refreshToken);
 assert.equal(store.authenticate(refreshed.token),user);
 t.mock.method(Date,'now',()=>start+181*86400000);
 assert.equal(store.refreshDeviceSession(session.refreshToken),null);
});
