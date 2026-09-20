import test from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { orderEmailOutboxOperations, drainOrderEmails } from '../src/order-email-outbox.mjs';

// SQLite and JS can sample different Windows wall clocks near a millisecond boundary.
// Anchor worker time to persisted due times rather than assuming those clocks match.
const dueTime = db => db.prepare('SELECT COALESCE(MAX(next_attempt_at),0) AS due FROM order_email_outbox').get().due + 1;

function fixture(t, path = ':memory:') {
  const db = new DatabaseSync(path);
  db.exec(`CREATE TABLE IF NOT EXISTS verified_emails(email TEXT PRIMARY KEY,user_id TEXT UNIQUE,verified_at INTEGER);
    CREATE TABLE IF NOT EXISTS customization_orders(id TEXT PRIMARY KEY,user_id TEXT,version INTEGER,status TEXT,document TEXT);`);
  const store = orderEmailOutboxOperations(db);
  t.after(() => db.close());
  const verify = () => db.prepare('INSERT OR IGNORE INTO verified_emails VALUES (?,?,?)').run('owner@example.test','owner',1);
  const insert = (id = 'order') => db.prepare('INSERT INTO customization_orders VALUES (?,?,1,?,?)').run(id,'owner','free_review',JSON.stringify({email:'attacker@example.test',requirements:'SECRET',images:['PRIVATE']}));
  const transition = status => db.prepare('UPDATE customization_orders SET status=?,version=version+1 WHERE id=?').run(status,'order');
  return {db,store,verify,insert,transition};
}

test('only verified recipient; state transitions dedupe; metadata and existing orders are excluded', async t => {
  const {db,store,verify,insert,transition} = fixture(t);
  insert('unverified'); verify(); insert();
  db.exec("UPDATE customization_orders SET version=version+1 WHERE id='order'");
  transition('needs_info'); transition('needs_info'); transition('quoted');
  orderEmailOutboxOperations(db);
  const sent = [];
  await drainOrderEmails(store,{enabled:true,send:async message=>sent.push(message)},{now:dueTime(db)});
  assert.equal(sent.length,3);
  assert.equal(new Set(sent.map(x=>x.idempotencyKey)).size,3);
  for (const message of sent) {
    assert.equal(message.to,'owner@example.test');
    assert.match(message.text,/Hildors App/);
    assert.doesNotMatch(JSON.stringify(message),/SECRET|PRIVATE|attacker/);
  }
  assert.equal(store.orderEmailOutboxSummary().sent,3);
});

test('queue persists across restart and disabled mailer leaves attempts untouched', async t => {
  const dir=mkdtempSync(join(tmpdir(),'order-mail-'));
  const path=join(dir,'store.sqlite');
  const first=new DatabaseSync(path);
  first.exec('CREATE TABLE verified_emails(email TEXT PRIMARY KEY,user_id TEXT UNIQUE,verified_at INTEGER); CREATE TABLE customization_orders(id TEXT PRIMARY KEY,user_id TEXT,version INTEGER,status TEXT,document TEXT)');
  orderEmailOutboxOperations(first);
  first.exec("INSERT INTO verified_emails VALUES ('owner@example.test','owner',1); INSERT INTO customization_orders VALUES ('order','owner',1,'free_review','{}')");
  first.close();
  const {db,store}=fixture(t,path);
  t.after(()=>rmSync(dir,{recursive:true,force:true}));
  await drainOrderEmails(store,{enabled:false,send:()=>assert.fail('disabled')});
  assert.equal(db.prepare('SELECT attempts FROM order_email_outbox').get().attempts,0);
  await drainOrderEmails(store,{enabled:true,send:async()=>{}},{now:dueTime(db)});
  assert.equal(store.orderEmailOutboxSummary().sent,1);
});

test('transient failure retries with same key and bounded safe errors', async t => {
  const {db,store,verify,insert}=fixture(t); verify(); insert();
  const now=dueTime(db), keys=[];
  const mailer={enabled:true,send:async message=>{keys.push(message.idempotencyKey); throw Object.assign(new Error('SECRET provider body'),{status:503});}};
  await drainOrderEmails(store,mailer,{now});
  const row=db.prepare('SELECT * FROM order_email_outbox').get();
  assert.equal(row.last_error,'DELIVERY_TRANSIENT');
  assert.equal(row.attempts,1);
  await drainOrderEmails(store,mailer,{now:now+1});
  assert.equal(keys.length,1);
  mailer.send=async message=>keys.push(message.idempotencyKey);
  await drainOrderEmails(store,mailer,{now:now+60001});
  assert.deepEqual(keys,[keys[0],keys[0]]);
  assert.equal(store.orderEmailOutboxSummary().sent,1);
});

test('leases prevent concurrent sends and reject stale completion; expired idempotency window never resends', async t => {
  const {db,store,verify,insert}=fixture(t); verify(); insert();
  const now=dueTime(db);
  const first=store.claimOrderEmail(now);
  assert.ok(first);
  assert.equal(store.claimOrderEmail(now+1),null);
  const second=store.claimOrderEmail(now+60001);
  assert.equal(first.id,second.id);
  assert.notEqual(first.leaseToken,second.leaseToken);
  assert.equal(store.completeOrderEmail(first.id,first.leaseToken,now+60002),false);
  assert.equal(store.claimOrderEmail(now+24*60*60*1000),null);
  assert.equal(store.orderEmailOutboxSummary().failed,1);
});

test('rolled back order does not queue; permanent errors stop; retries are bounded', async t => {
  const {db,store,verify,insert}=fixture(t); verify();
  db.exec('BEGIN'); insert('rolledback'); db.exec('ROLLBACK');
  assert.equal(store.orderEmailOutboxSummary().pending,0);
  insert();
  const now=dueTime(db);
  await drainOrderEmails(store,{enabled:true,send:async()=>{throw Object.assign(new Error('private'),{status:422});}},{now});
  assert.equal(store.orderEmailOutboxSummary().failed,1);
  insert('retry');
  const retryNow=dueTime(db);
  for(let i=0;i<10;i++) await drainOrderEmails(store,{enabled:true,send:async()=>{throw new Error('timeout');}},{now:retryNow+i*3600001});
  assert.equal(store.orderEmailOutboxSummary().failed,2);
  assert.equal(db.prepare("SELECT attempts FROM order_email_outbox WHERE order_id='retry'").get().attempts,8);
});

test('installation never backfills existing orders', t => {
  const db=new DatabaseSync(':memory:'); t.after(()=>db.close());
  db.exec(`CREATE TABLE verified_emails(email TEXT PRIMARY KEY,user_id TEXT UNIQUE,verified_at INTEGER);
    CREATE TABLE customization_orders(id TEXT PRIMARY KEY,user_id TEXT,version INTEGER,status TEXT,document TEXT);
    INSERT INTO verified_emails VALUES ('owner@example.test','owner',1);
    INSERT INTO customization_orders VALUES ('old','owner',1,'free_review','{}');`);
  const store=orderEmailOutboxOperations(db);
  assert.equal(store.claimOrderEmail(Date.now()+1000),null);
});

test('parallel drain workers send each event only once', async t => {
  const {db,store,verify,insert}=fixture(t); verify(); insert();
  const now=dueTime(db);
  let finish;
  const pending=new Promise(resolve=>{finish=resolve;});
  let sends=0;
  const mailer={enabled:true,send:async()=>{sends++; await pending;}};
  const first=drainOrderEmails(store,mailer,{now});
  await drainOrderEmails(store,mailer,{now});
  assert.equal(sends,1);
  finish(); await first;
  assert.equal(store.orderEmailOutboxSummary().sent,1);
});

test('mailer requires explicit enabled and honors sanitized retryable classification', async t => {
  const {db,store,verify,insert}=fixture(t); verify(); insert();
  await drainOrderEmails(store,{send:async()=>assert.fail('not explicitly enabled')});
  assert.equal(db.prepare('SELECT attempts FROM order_email_outbox').get().attempts,0);
  const now=dueTime(db);
  await drainOrderEmails(store,{enabled:true,send:async()=>{throw Object.assign(new Error('sanitized'),{retryable:false});}},{now});
  assert.equal(store.orderEmailOutboxSummary().failed,1);
  insert('transient');
  await drainOrderEmails(store,{enabled:true,send:async()=>{throw Object.assign(new Error('sanitized'),{retryable:true,status:422});}},{now:dueTime(db)});
  assert.equal(store.orderEmailOutboxSummary().pending,1);
  assert.equal(db.prepare("SELECT last_error FROM order_email_outbox WHERE order_id='transient'").get().last_error,'DELIVERY_TRANSIENT');
});

test('initial receipt waits for actual material uploads and cannot repeat after deletion or reupload', async t => {
  const {db,store,verify}=fixture(t); verify();
  const save = materials => db.prepare("UPDATE customization_orders SET document=?,version=version+1 WHERE id='uploads'")
    .run(JSON.stringify({materialCount:2,materials,materialsUploaded:true}));
  db.prepare('INSERT INTO customization_orders VALUES (?,?,1,?,?)')
    .run('uploads','owner','free_review',JSON.stringify({materialCount:2,materials:[],materialsUploaded:true}));
  assert.equal(store.orderEmailOutboxSummary().pending,0);
  // A failed upload never attaches a real material; a client flag cannot announce completion.
  save([]); save([{id:'first'}]);
  assert.equal(store.orderEmailOutboxSummary().pending,0);
  save([{id:'first'},{id:'second'}]);
  assert.equal(store.orderEmailOutboxSummary().pending,1);
  save([]); save([{id:'replacement-1'},{id:'replacement-2'}]);
  assert.equal(store.orderEmailOutboxSummary().pending,1);
  const sent=[];
  await drainOrderEmails(store,{enabled:true,send:async message=>sent.push(message)},{now:dueTime(db)});
  assert.equal(sent.length,1);
  assert.equal(sent[0].idempotencyKey,'uploads:received');
});

test('zero-material and already-complete submissions queue initial receipt immediately', t => {
  const {db,store,verify}=fixture(t); verify();
  const insert=db.prepare('INSERT INTO customization_orders VALUES (?,?,1,?,?)');
  insert.run('none','owner','free_review',JSON.stringify({materialCount:0}));
  insert.run('complete','owner','free_review',JSON.stringify({materialCount:1,materials:[{id:'material'}]}));
  assert.equal(store.orderEmailOutboxSummary().pending,2);
});
