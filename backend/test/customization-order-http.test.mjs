import test from 'node:test';
import assert from 'node:assert/strict';
import {createStore} from '../src/store.mjs';
import {app} from '../src/server.mjs';
import {createCustomizationBilling} from '../src/customization-billing.mjs';
const terms={deliveryContent:'MP4',deliveryPeriod:'Confirmed individually',revisionScope:'Lighting',usageRights:'Personal use',maxRevisions:1};
test('custom order HTTP scopes identity, preserves old prices, verifies receipts and serves admin tools',async t=>{
 const store=createStore();const owner=store.createUser(),other=store.createUser();
 const token=store.createSession(owner),otherToken=store.createSession(other);
 const receipt={verified:true,platform:'apple',environment:'sandbox',transactionId:'test-only-transaction',status:'purchased',currency:'USD',amountMicros:'19990000'};
 const server=app(store,{adminToken:'test-admin',customizationBilling:createCustomizationBilling({mode:'test',apple:{verify:async(proof,expected)=>({...receipt,...expected})}})});
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));t.after(async()=>{await new Promise(resolve=>server.close(resolve));store.close();});
 const base=`http://127.0.0.1:${server.address().port}`;
 const call=(path,auth,body)=>fetch(base+path,{method:body?'POST':'GET',headers:{...(auth?{Authorization:`Bearer ${auth}`} :{}),...(body?{'Content-Type':'application/json'}:{})},body:body?JSON.stringify(body):undefined});
 for(const path of ['/console/customization-plans','/console/customization-plans.js','/console/customization-orders-v2','/console/customization-orders-v2.js'])assert.equal((await call(path)).status,200,path);
 assert.equal((await call('/admin/customization-plans',token)).status,401);
 store.updateCustomizationPlan('custom-10s',{version:1,usdBaseCents:1999,listed:true,appleProductId:'custom10.v1'},'test');
 const order=store.createCustomizationOrder(owner,{planId:'custom-10s',planVersion:2,characterName:'Private'});
 const root=`/v1/me/customization-orders/${order.id}`;
 assert.equal((await call(root,otherToken)).status,404);
 assert.equal((await call(root+'/deliverable',otherToken)).status,404);
 assert.equal((await call(root+'/purchase',otherToken,{})).status,404);
 assert.equal((await call(`/admin/customization-orders/${order.id}/plan-offer`,token,{version:1,terms})).status,401);
 let response=await call(`/admin/customization-orders/${order.id}/plan-offer`,'test-admin',{version:1,terms});assert.equal(response.status,200);let current=await response.json();
 assert.throws(()=>store.updateCustomizationPlan('custom-10s',{version:2,usdBaseCents:2999,listed:true,appleProductId:'custom10.v1'},'test'),/PLAN_PRODUCT_VERSION_REQUIRED/);
 store.updateCustomizationPlan('custom-10s',{version:2,usdBaseCents:2999,listed:true,appleProductId:'custom10.v2'},'test');
 response=await call(root+'/purchase',token,{platform:'apple',proof:'test-proof',offerVersion:current.offer.version,acceptedTerms:true});assert.equal(response.status,200);current=await response.json();
 assert.equal(current.status,'in_production');assert.equal(current.paidSnapshot.plan.usdBaseCents,1999);
 const version=current.version;
 response=await call(root+'/purchase',token,{platform:'apple',proof:'test-proof',offerVersion:current.offer.version,acceptedTerms:true});assert.equal(response.status,200);assert.equal((await response.json()).version,version);
 receipt.status='refunded';response=await call(root+'/purchase',token,{platform:'apple',proof:'test-proof',offerVersion:current.offer.version,acceptedTerms:true});assert.equal(response.status,200);assert.equal((await response.json()).payment.status,'refunded');
});

import {mkdtemp,mkdir,writeFile,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {createHash} from 'node:crypto';
test('private offline delivery is owner-only, final-only and revoked by refund',async t=>{
 const s=createStore(),uid=s.createUser(),other=s.createUser();const token=s.createSession(uid),otherToken=s.createSession(other);
 const directory=await mkdtemp(join(tmpdir(),'hildors-delivery-'));const server=app(s,{adminToken:'test-admin',mediaDirectory:directory});
 await new Promise(r=>server.listen(0,'127.0.0.1',r));t.after(async()=>{await new Promise(r=>server.close(r));s.close();await rm(directory,{recursive:true,force:true});});
 s.updateCustomizationPlan('custom-10s',{version:1,usdBaseCents:1999,listed:true},'test');let o=s.createCustomizationOrder(uid,{planId:'custom-10s',planVersion:2});o=s.preparePlanOffer(o.id,{version:o.version,terms});
 const receipt={orderId:o.id,userId:uid,platform:'apple',transactionId:'private-test',status:'purchased',currency:'USD',amountMicros:'19990000'};o=s.applyVerifiedCustomizationTransaction(receipt);
 const data=Buffer.from('test delivery bytes');await mkdir(join(directory,'private-deliverables'));await writeFile(join(directory,'private-deliverables','final-test.mp4'),data);
 o=s.attachPlanDeliverable(o.id,o.version,{id:'final-test',bytes:data.length,sha256:createHash('sha256').update(data).digest('hex'),inspection:{status:'checked',videoDurationSeconds:10}});
 o=s.reviewPlanOrder(o.id,{version:o.version,action:'approve_delivery'});
 const base=`http://127.0.0.1:${server.address().port}/v1/me/customization-orders/${o.id}`;
 const get=(suffix,auth=token)=>fetch(base+suffix,{headers:{Authorization:`Bearer ${auth}`}});
 assert.equal((await get('/manifest')).status,404);assert.equal((await get('/deliverable')).status,200);
 o=s.planOrderAction(o.id,uid,{version:o.version,action:'accept_delivery'});
 assert.equal((await get('/manifest',otherToken)).status,404);assert.equal((await get('/download',otherToken)).status,404);
 const manifest=await (await get('/manifest')).json();assert.equal(manifest.packageId,`custom-order-${o.id}`);assert.equal(manifest.bytes,data.length);
 const result=await get('/download');assert.equal(result.status,200);assert.equal(result.headers.get('cache-control'),'private, no-store');assert.deepEqual(Buffer.from(await result.arrayBuffer()),data);
 s.applyVerifiedCustomizationTransaction({...receipt,status:'refunded'});assert.equal((await get('/manifest')).status,404);assert.equal((await get('/download')).status,404);
});

import {setTimeout as delay} from 'node:timers/promises';
test('custom deliverable inspection shares the bounded media processor',async t=>{
 const directory=await mkdtemp(join(tmpdir(),'hildors-inspection-lock-')),s=createStore(),uid=s.createUser();let started,release,calls=0;
 const began=new Promise(r=>started=r),gate=new Promise(r=>release=r);
 const server=app(s,{adminToken:'test-admin',mediaDirectory:directory,inspector:async()=>{calls++;started();await gate;return {status:'checked',videoDurationSeconds:10};}});
 await new Promise(r=>server.listen(0,'127.0.0.1',r));t.after(async()=>{release();await new Promise(r=>server.close(r));s.close();await rm(directory,{recursive:true,force:true});});
 s.updateCustomizationPlan('custom-10s',{version:1,usdBaseCents:1999,listed:true},'test');
 function paid(){let o=s.createCustomizationOrder(uid,{planId:'custom-10s',planVersion:2});o=s.preparePlanOffer(o.id,{version:o.version,terms});return s.applyVerifiedCustomizationTransaction({orderId:o.id,userId:uid,platform:'apple',transactionId:o.id,status:'purchased',currency:'USD',amountMicros:'19990000'});}
 const a=paid(),b=paid(),data=Buffer.alloc(32);data.write('ftyp',4);
 const upload=o=>fetch(`http://127.0.0.1:${server.address().port}/admin/customization-orders/${o.id}/deliverable`,{method:'PUT',headers:{Authorization:'Bearer test-admin','Content-Type':'video/mp4','If-Match':String(o.version)},body:data});
 const first=upload(a);await began;const second=upload(b);await delay(100);
 try{assert.equal(calls,1,'unbounded concurrent inspection');}finally{release();await Promise.all([first,second]);}
 assert.equal((await first).status,200);assert.equal((await second).status,409);
});
