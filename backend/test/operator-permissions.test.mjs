import {operatorLogin} from './helpers/operator-login.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import {createStore} from '../src/store.mjs';
import {app} from '../src/server.mjs';
test('operator permissions are enforced and version changes revoke sessions',async t=>{
 const store=createStore(),server=app(store,{adminToken:'root-token',adminUsername:'root',adminPassword:'root-password'});
 await new Promise(r=>server.listen(0,'127.0.0.1',r));t.after(async()=>{await new Promise(r=>server.close(r));store.close();});
 const base=`http://127.0.0.1:${server.address().port}`;
 const call=async(path,{body,token='root-token',cookie,method=body?'POST':'GET'}={})=>{const r=await fetch(base+path,{method,headers:{'Content-Type':'application/json',...(cookie?{cookie}:token?{authorization:`Bearer ${token}`}:{})},...(body?{body:JSON.stringify(body)}:{})});return {status:r.status,data:await r.json(),cookie:r.headers.get('set-cookie')?.split(';')[0]};};
 const created=await call('/admin/operators',{body:{username:'reviewer',displayName:'审核员',password:'safe-test-password',permissions:['content.view','content.review'],active:true}});
 assert.equal(created.status,201);assert.equal(JSON.stringify(created.data).includes('hash'),false);
 const login=await call('/admin/login',{body:{username:'reviewer',password:'safe-test-password'}});assert.equal(login.status,200);
 const completed=await operatorLogin(base,{username:'reviewer',password:'safe-test-password'});const cookie=completed.headers.get('set-cookie').split(';')[0];assert.equal((await call('/admin/packages',{cookie})).status,200);
 assert.equal((await call('/admin/operators',{cookie})).status,403);
 assert.equal((await call('/admin/layout',{cookie})).status,403);
 assert.equal((await call('/admin/unknown',{cookie})).status,403);
 assert.equal((await call('/admin/packages/missing/publish',{cookie,body:{version:1}})).status,403);
 assert.equal((await call('/admin/customization-orders/missing',{cookie,body:{version:1,status:'quoted'}})).status,403);
 assert.equal((await call('/admin/operators/'+created.data.id,{body:{version:2,permissions:['content.view'],active:true,displayName:'审核员'}})).status,200);
 assert.equal((await call('/admin/packages',{cookie})).status,401);
 assert.equal((await call('/admin/operators/'+created.data.id,{body:{version:1,permissions:[],active:true}})).status,409);
 assert.ok(store.operatorAudit().some(a=>a.action==='operator.create'));
});

test('creator review cannot edit commercial settings; order review cannot change quotes',async t=>{
 const store=createStore(),server=app(store,{adminToken:'root'});await new Promise(r=>server.listen(0,'127.0.0.1',r));t.after(async()=>{await new Promise(r=>server.close(r));store.close();});
 const op=store.createOperator({username:'scoped',displayName:'受限',password:'test-operator-password',permissions:['creators.review','orders.review']},{id:'root'});
 const base=`http://127.0.0.1:${server.address().port}`;
 const login=await operatorLogin(base,{username:op.username,password:'test-operator-password'});const cookie=login.headers.get('set-cookie').split(';')[0];
 const post=async(path,body)=>fetch(base+path,{method:'POST',headers:{cookie},body:JSON.stringify(body)});
 const creator=store.upsertCreatorProfile(store.createUser(),{displayName:'作者',email:'test@example.test'});
 const value={version:creator.version,status:'approved',tier:'standard',commissionRate:'0',manager:'',canPublish:false,canReceiveOrders:false,identityVerified:false,agreementSigned:false,payoutReady:false,note:''};
 assert.equal((await post('/admin/creators/'+creator.id,{...value,commissionRate:20})).status,403);
 assert.equal((await post('/admin/creators/'+creator.id,value)).status,200);
 const order=store.createCustomizationOrder(store.createUser(),{characterName:'角色',materialCount:0});
 assert.equal((await post('/admin/customization-orders/'+order.id,{version:order.version,status:'needs_info',note:'补充',fields:{quoteAmount:900}})).status,403);
});

test('operator password reset, disable, validation and self escalation are guarded',()=>{
 const store=createStore();try{
 const root={id:'root'},a=store.createOperator({username:'manager',displayName:'管理',password:'test-manager-password',permissions:['operators.manage']},root);
 const old=store.authenticateOperator(a.username,'test-manager-password');assert.ok(old);
 assert.throws(()=>store.updateOperator(a.id,{version:1,permissions:['operators.manage','content.view']},{...a,isRoot:false}),/SELF_ESCALATION/);
 const b=store.resetOperatorPassword(a.id,{version:1,password:'new-manager-password'},root);assert.equal(b.version,2);assert.equal(store.operatorIdentity(old.id,old.authVersion),null);
 assert.equal(store.authenticateOperator(a.username,'test-manager-password'),null);assert.ok(store.authenticateOperator(a.username,'new-manager-password'));
 store.updateOperator(a.id,{version:2,active:false},root);assert.equal(store.authenticateOperator(a.username,'new-manager-password'),null);
 assert.throws(()=>store.createOperator({username:'invalid',displayName:'错误',password:'short',permissions:[]},root),/INVALID_PASSWORD/);
 assert.throws(()=>store.createOperator({username:'invalid',displayName:'错误',password:'long-test-password',permissions:['invented']},root),/INVALID_PERMISSIONS/);
 }finally{store.close();}
});
import {adminPermissions} from '../src/operators.mjs';
test('every declared workflow action has its own required permission',async()=>{
 const store={getCustomizationOrder:()=>({workflow:{}})};
 for(const [status,key] of Object.entries({free_review:'review',needs_info:'review',approved_for_quote:'review',rejected:'review',quoted:'quote',in_production:'deliver',quality_review:'deliver',user_acceptance:'deliver',delivered:'deliver',withdrawn:'cancel'}))assert.deepEqual(await adminPermissions('POST','/admin/customization-orders/order',async()=>({status}),store),['orders.'+key]);
 assert.equal(await adminPermissions('POST','/admin/future-route',async()=>({}),store),null);
});

test('in-flight media inspection cannot commit after permission revocation',async t=>{
 let started,release;const begun=new Promise(r=>started=r),pending=new Promise(r=>release=r);
 const store=createStore(),server=app(store,{adminToken:'root',inspector:async()=>{started();return pending;}});await new Promise(r=>server.listen(0,'127.0.0.1',r));t.after(async()=>{release({status:'failed'});await new Promise(r=>server.close(r));store.close();});
 const op=store.createOperator({username:'uploader',displayName:'上传员',password:'test-upload-password',permissions:['content.upload']},{id:'root'});
 const item=store.create({title:'角色',format:'single',tags:[],clips:[{id:'main',title:'视频',media:{id:'00000000-0000-0000-0000-000000000000'}}]});
 const base=`http://127.0.0.1:${server.address().port}`;
 const login=await operatorLogin(base,{username:op.username,password:'test-upload-password'});const cookie=login.headers.get('set-cookie').split(';')[0];
 const result=fetch(base+`/admin/packages/${item.id}/clips/main/inspect`,{method:'POST',headers:{cookie}});
 await begun;store.updateOperator(op.id,{version:2,permissions:[]},{id:'root'});release({status:'failed',code:'SHOULD_NOT_COMMIT'});
 assert.equal((await result).status,401);assert.notEqual(store.get(item.id).clips[0].media.inspection.code,'SHOULD_NOT_COMMIT');
});
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {DatabaseSync} from 'node:sqlite';
test('operators persist with salted password hashes and contain no plaintext secrets',()=>{
 const dir=mkdtempSync(join(tmpdir(),'operators-')),path=join(dir,'test.sqlite');let store=createStore(path);
 try{const a=store.createOperator({username:'durable',displayName:'持久',password:'durable-test-password',permissions:['orders.view']},{id:'root'});store.close();store=createStore(path);assert.equal(store.listOperators()[0].id,a.id);assert.ok(store.authenticateOperator('durable','durable-test-password'));const db=new DatabaseSync(path);try{const row=db.prepare('SELECT * FROM operators').get();assert.match(row.password_hash,/^[a-f0-9]{32}:[a-f0-9]{128}$/);assert.equal(JSON.stringify(row).includes('durable-test-password'),false);}finally{db.close();}}
 finally{store.close();rmSync(dir,{recursive:true,force:true});}
});
test('repeated failed logins are rate limited without revealing account existence',async t=>{
 const store=createStore(),server=app(store,{adminUsername:'root',adminPassword:'root-password'});await new Promise(r=>server.listen(0,'127.0.0.1',r));t.after(async()=>{await new Promise(r=>server.close(r));store.close();});
 const login=body=>fetch(`http://127.0.0.1:${server.address().port}/admin/login`,{method:'POST',body:JSON.stringify(body)});
 for(let i=0;i<10;i++){const r=await login({username:'missing',password:'incorrect-password'});assert.equal(r.status,401);assert.equal((await r.json()).code,'INVALID_CREDENTIALS');}
 const limited=await login({username:'root',password:'root-password'});assert.equal(limited.status,429);assert.ok(Number(limited.headers.get('retry-after'))>0);
});
test('creator commercial updates preserve review fields and clip publish requires review too',async t=>{
 const store=createStore(),server=app(store);await new Promise(r=>server.listen(0,'127.0.0.1',r));t.after(async()=>{await new Promise(r=>server.close(r));store.close();});
 const actor={id:'root'};store.createOperator({username:'commercial',displayName:'商务',password:'test-commercial-password',permissions:['creators.manage']},actor);
 let creator=store.upsertCreatorProfile(store.createUser(),{displayName:'创作者',email:'commerce@example.test'});creator=store.manageCreatorProfile(creator.id,1,{status:'approved',note:'认证通过'});
 const base=`http://127.0.0.1:${server.address().port}`,login=await operatorLogin(base,{username:'commercial',password:'test-commercial-password'});const cookie=login.headers.get('set-cookie').split(';')[0];
 const r=await fetch(base+'/admin/creators/'+creator.id,{method:'POST',headers:{cookie},body:JSON.stringify({version:creator.version,commissionRate:15})});assert.equal(r.status,200);const updated=await r.json();assert.equal(updated.status,'approved');assert.equal(updated.management.note,'认证通过');assert.equal(updated.management.commissionRate,15);
 assert.deepEqual(await adminPermissions('POST','/admin/packages/pkg/clips/clip/publish',async()=>({}),store),['content.publish','content.review']);
});
