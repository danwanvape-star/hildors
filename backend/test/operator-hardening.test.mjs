import test from 'node:test';
import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
import {DatabaseSync} from 'node:sqlite';
import {operatorOperations} from '../src/operators.mjs';
import {createStore} from '../src/store.mjs';
import {app} from '../src/server.mjs';
const secret=()=>randomBytes(24).toString('base64url');

test('new/reset accounts require self password change, preserve permissions and revoke sessions',()=>{
 const db=new DatabaseSync(':memory:'),ops=operatorOperations(db),root={id:'root',username:'root'};
 try {
 const password=secret(),next=secret();
 const a=ops.createOperator({username:'tester',displayName:'Tester',password,permissions:['plans.pricing']},root);
 assert.equal(a.mustChangePassword,true);
 const auth=ops.authenticateOperator(a.username,password);
 assert.throws(()=>ops.changeOperatorPassword(a.id,{currentPassword:secret(),password:next},a),/INVALID_CREDENTIALS/);
 assert.throws(()=>ops.changeOperatorPassword(a.id,{currentPassword:password,password},a),/PASSWORD_REUSED/);
 const changed=ops.changeOperatorPassword(a.id,{currentPassword:password,password:next},a);
 assert.equal(changed.mustChangePassword,false);
 assert.deepEqual(changed.permissions,a.permissions);
 assert.equal(ops.operatorIdentity(auth.id,auth.authVersion),null);
 assert.ok(ops.authenticateOperator(a.username,next));
 const reset=ops.resetOperatorPassword(a.id,{version:changed.version,password:secret()},root);
 assert.equal(reset.mustChangePassword,true);
 assert.ok(ops.operatorAudit().some(x=>x.action==='operator.password.change'&&x.actorId===a.id));
 }finally{db.close();}
});

test('legacy schema migration preserves grants and does not force existing users to change password',()=>{
 const db=new DatabaseSync(':memory:');
 try {
 db.exec('CREATE TABLE operators (id TEXT PRIMARY KEY,username TEXT NOT NULL UNIQUE,display_name TEXT NOT NULL,password_hash TEXT NOT NULL,active INTEGER NOT NULL,permissions TEXT NOT NULL,version INTEGER NOT NULL,auth_version INTEGER NOT NULL,created_at TEXT NOT NULL,updated_at TEXT NOT NULL)');
 db.prepare('INSERT INTO operators VALUES (?,?,?,?,?,?,?,?,?,?)').run('old','old','Old','unused',1,'["orders.deliver"]',4,7,'then','then');
 const ops=operatorOperations(db);assert.equal(ops.getOperator('old').mustChangePassword,false);
 assert.deepEqual(ops.getOperator('old').permissions,['orders.deliver']);
 assert.equal(ops.getOperator('old').version,4);assert.ok(ops.operatorIdentity('old',7));
 operatorOperations(db);assert.equal(ops.getOperator('old').mustChangePassword,false);
 }finally{db.close();}
});

test('account mutation rolls back when audit fails',()=>{
 const db=new DatabaseSync(':memory:'),ops=operatorOperations(db);
 try {
 db.exec("CREATE TRIGGER fail_audit BEFORE INSERT ON operator_audit BEGIN SELECT RAISE(ABORT,'audit unavailable'); END");
 assert.throws(()=>ops.createOperator({username:'tester',displayName:'Tester',password:secret(),permissions:[]},{id:'root'}),/audit unavailable/);
 assert.equal(ops.listOperators().length,0);
 }finally{db.close();}
});

test('forced password gate prevents business reads and mutations; self change logs all sessions out',async t=>{
 const store=createStore(),server=app(store,{adminToken:secret()});
 await new Promise(r=>server.listen(0,'127.0.0.1',r));
 t.after(async()=>{await new Promise(r=>server.close(r));store.close();});
 const password=secret(),a=store.createOperator({username:'operator',displayName:'Operator',password,permissions:['content.view']},{id:'root'});
 const base=`http://127.0.0.1:${server.address().port}`;
 const call=async(path,body,cookie)=>{const r=await fetch(base+path,{method:body?'POST':'GET',headers:{...(cookie?{cookie}:{}),'Content-Type':'application/json'},body:body?JSON.stringify(body):undefined});return {status:r.status,data:await r.json(),cookie:r.headers.get('set-cookie')?.split(';')[0]};};
 const login=await call('/admin/login',{username:a.username,password});
 assert.equal(login.data.actor.mustChangePassword,true);
 assert.equal((await call('/admin/me',null,login.cookie)).status,200);
 assert.equal((await call('/admin/packages',null,login.cookie)).data.code,'PASSWORD_CHANGE_REQUIRED');
 const next=secret();assert.equal((await call('/admin/me/password',{currentPassword:password,password:next},login.cookie)).status,200);
 assert.equal((await call('/admin/me',null,login.cookie)).status,401);
 const again=await call('/admin/login',{username:a.username,password:next});
 assert.equal((await call('/admin/packages',null,again.cookie)).status,200);
 assert.equal((await call('/admin/operators',null,again.cookie)).status,403);
});
