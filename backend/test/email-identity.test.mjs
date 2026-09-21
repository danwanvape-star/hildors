import test from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { emailIdentityOperations } from '../src/email-identity.mjs';

function fixture(t) {
  const db = new DatabaseSync(':memory:');
  db.exec('PRAGMA foreign_keys=ON; CREATE TABLE users(id TEXT PRIMARY KEY); CREATE TABLE issued_sessions(user_id TEXT REFERENCES users(id));');
  const ops = { ...emailIdentityOperations(db), createDeviceSession(userId) {
    db.exec('SAVEPOINT session');
    db.prepare('INSERT INTO issued_sessions VALUES (?)').run(userId);
    db.exec('RELEASE session');
    return {token:'test-token',refreshToken:'test-refresh',expiresIn:86400};
  }};
  t.after(() => db.close());
  return {db,ops};
}

test('normalized email binds authenticated guest and code is single use and hashed at rest', t => {
  const {db,ops}=fixture(t);
  db.prepare('INSERT INTO users VALUES (?)').run('guest');
  const c=ops.startEmailChallenge(' Person@Example.com ',{userId:'guest',ip:'one'});
  assert.match(c.code,/^\d{6}$/);
  assert.equal(c.email,'person@example.com');
  assert.equal(JSON.stringify(db.prepare('SELECT * FROM email_auth_challenges').get()).includes(c.code),false);
  assert.throws(()=>ops.verifyEmailChallenge(c.challengeId,c.code),/INVALID_EMAIL_CHALLENGE/);
  const result=ops.verifyEmailChallenge(c.challengeId,c.code,{userId:'guest'});
  assert.equal(result.userId,'guest');
  assert.equal(result.token,'test-token');
  assert.deepEqual(ops.emailAccount('guest'),{userId:'guest',email:'person@example.com',emailVerified:true});
  assert.throws(()=>ops.verifyEmailChallenge(c.challengeId,c.code,{userId:'guest'}),/INVALID_EMAIL_CHALLENGE/);
});

test('returning email owner cannot be transferred to another authenticated guest', t => {
  const {db,ops}=fixture(t);
  const c=ops.startEmailChallenge('owner@example.com');
  const owner=ops.verifyEmailChallenge(c.challengeId,c.code);
  db.prepare('INSERT INTO users VALUES (?)').run('other');
  db.prepare('UPDATE email_auth_challenges SET created_at=created_at-61000').run();
  const next=ops.startEmailChallenge('OWNER@example.com',{userId:'other'});
  assert.equal(ops.verifyEmailChallenge(next.challengeId,next.code,{userId:'other'}).userId,owner.userId);
  assert.equal(ops.emailAccount('other').emailVerified,false);
});

test('five failures lock challenge; expiration, invalidation and malformed codes fail generically', t => {
  const {db,ops}=fixture(t);
  const c=ops.startEmailChallenge('attempts@example.com');
  for(let i=0;i<5;i++) assert.throws(()=>ops.verifyEmailChallenge(c.challengeId,'bad'),/INVALID_EMAIL_CHALLENGE/);
  assert.throws(()=>ops.verifyEmailChallenge(c.challengeId,c.code),/INVALID_EMAIL_CHALLENGE/);
  const expired=ops.startEmailChallenge('expired@example.com');
  db.prepare('UPDATE email_auth_challenges SET expires_at=0 WHERE id=?').run(expired.challengeId);
  assert.throws(()=>ops.verifyEmailChallenge(expired.challengeId,expired.code),/INVALID_EMAIL_CHALLENGE/);
  const invalidated=ops.startEmailChallenge('invalidated@example.com');
  ops.invalidateEmailChallenge(invalidated.challengeId);
  assert.throws(()=>ops.verifyEmailChallenge(invalidated.challengeId,invalidated.code),/INVALID_EMAIL_CHALLENGE/);
});

test('rate limits survive invalidation and cover email and IP; stale rows pruned', t => {
  const {db,ops}=fixture(t);
  const c=ops.startEmailChallenge('rate@example.com');
  ops.invalidateEmailChallenge(c.challengeId);
  assert.throws(()=>ops.startEmailChallenge('RATE@example.com'),/EMAIL_RATE_LIMITED/);
  for(let i=0;i<20;i++) ops.startEmailChallenge(`ip${i}@example.com`,{ip:'same'});
  assert.throws(()=>ops.startEmailChallenge('next@example.com',{ip:'same'}),/EMAIL_RATE_LIMITED/);
  db.prepare('UPDATE email_auth_challenges SET created_at=created_at-3600001').run();
  ops.startEmailChallenge('fresh@example.com',{ip:'same'});
  assert.equal(db.prepare('SELECT count(*) AS n FROM email_auth_challenges').get().n,1);
});

test('session failure rolls back consumption, newly created user and verified identity', t => {
  const {db,ops}=fixture(t);
  const c=ops.startEmailChallenge('atomic@example.com');
  const original=ops.createDeviceSession;
  ops.createDeviceSession=function(id) { original.call(this,id); throw new Error('session failure'); };
  assert.throws(()=>ops.verifyEmailChallenge(c.challengeId,c.code),/session failure/);
  assert.equal(db.prepare('SELECT count(*) AS n FROM users').get().n,0);
  assert.equal(db.prepare('SELECT count(*) AS n FROM verified_emails').get().n,0);
  assert.equal(db.prepare('SELECT count(*) AS n FROM issued_sessions').get().n,0);
  ops.createDeviceSession=original;
  assert.equal(ops.verifyEmailChallenge(c.challengeId,c.code).emailVerified,true);
});

test('hourly email limit and resend superseding preserve five request ceiling', t => {
  const {db,ops}=fixture(t);
  let previous;
  for(let i=0;i<5;i++) {
    db.prepare('UPDATE email_auth_challenges SET created_at=created_at-61000').run();
    const c=ops.startEmailChallenge('hour@example.com');
    if(previous) assert.throws(()=>ops.verifyEmailChallenge(previous.challengeId,previous.code),/INVALID_EMAIL_CHALLENGE/);
    previous=c;
  }
  db.prepare('UPDATE email_auth_challenges SET created_at=created_at-61000').run();
  assert.throws(()=>ops.startEmailChallenge('hour@example.com'),/EMAIL_RATE_LIMITED/);
  assert.equal(ops.verifyEmailChallenge(previous.challengeId,previous.code).emailVerified,true);
});

test('already verified identities never gain another email or merge through a second challenge', t => {
  const {ops}=fixture(t);
  const first=ops.startEmailChallenge('first@example.com');
  const owner=ops.verifyEmailChallenge(first.challengeId,first.code);
  const second=ops.startEmailChallenge('second@example.com',{userId:owner.userId});
  const separate=ops.verifyEmailChallenge(second.challengeId,second.code,{userId:owner.userId});
  assert.notEqual(owner.userId,separate.userId);
  assert.equal(ops.emailAccount(owner.userId).email,'first@example.com');
});

test('configured secret survives module reconstruction; weak secrets and malformed emails rejected', t => {
  const {db,ops}=fixture(t);
  assert.throws(()=>emailIdentityOperations(db,{codeSecret:'weak'}),/INVALID_EMAIL_CODE_SECRET/);
  for(const email of ['bad','x@example.com\r\nBcc: hidden@example.com','a..b@example.com']) {
    assert.throws(()=>ops.startEmailChallenge(email),/INVALID_EMAIL/);
  }
  const secret='a-secure-configured-test-secret-32-bytes';
  const issuer={...ops,...emailIdentityOperations(db,{codeSecret:secret})};
  const challenge=issuer.startEmailChallenge('restart@example.com');
  const verifier={...ops,...emailIdentityOperations(db,{codeSecret:secret})};
  assert.equal(verifier.verifyEmailChallenge(challenge.challengeId,challenge.code).emailVerified,true);
});

test('existing-only email verification never creates an account', t=>{
 const {db,ops}=fixture(t);
 const challenge=ops.startEmailChallenge('unknown@example.com');
 assert.throws(()=>ops.verifyEmailChallenge(challenge.challengeId,challenge.code,{requireExisting:true}),/INVALID_EMAIL_CHALLENGE/);
 assert.equal(db.prepare('SELECT count(*) AS n FROM users').get().n,0);
});
