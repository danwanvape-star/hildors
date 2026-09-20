import test from 'node:test';
import assert from 'node:assert/strict';
import {createStore} from '../src/store.mjs';
import {app} from '../src/server.mjs';

async function fixture(t,options={}) {
  const store=createStore(),sent=[];
  const server=app(store,{mailer:{enabled:true,send:async m=>sent.push(m)},requireOrderEmail:true,...options});
  await new Promise(r=>server.listen(0,'127.0.0.1',r));
  t.after(async()=>{await new Promise(r=>server.close(r));store.close();});
  async function request(path,body,token) {
    const r=await fetch(`http://127.0.0.1:${server.address().port}${path}`,{method:body===undefined?'GET':'POST',headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},body:body===undefined?undefined:JSON.stringify(body)});
    return {status:r.status,body:await r.json()};
  }
  return {store,sent,request};
}

test('verified email survives new-device login and order ignores spoofed contact',async t=>{
  const {store,sent,request}=await fixture(t);
  const anonymous=store.createUser(),token=store.createSession(anonymous);
  const unverified=await request('/v1/me/customization-orders',{characterName:'Fox'},token);
  assert.equal(unverified.status,403);assert.equal(unverified.body.code,'EMAIL_VERIFICATION_REQUIRED');
  const start=await request('/v1/email-auth/start',{email:'  Person@Example.com '},token);
  assert.equal(start.status,200);assert.equal(start.body.code,undefined);
  const code=sent[0].text.match(/\b\d{6}\b/)[0];
  const verified=await request('/v1/email-auth/verify',{challengeId:start.body.challengeId,code},token);
  assert.equal(verified.status,200);assert.equal(verified.body.userId,anonymous);
  const account=await request('/v1/me/account',undefined,verified.body.token);
  assert.equal(account.body.email,'person@example.com');
  const created=await request('/v1/me/customization-orders',{characterName:'Fox',sourceType:'original',marketRegion:'us',requestedFeatures:['idle'],materialCount:1,requirements:'Blue',privacyConsentVersion:'v1',verifiedContactEmail:'attacker@example.com'},verified.body.token);
  assert.equal(created.status,201);assert.equal(created.body.verifiedContactEmail,'person@example.com');
  const later=Date.now()+61000;const originalNow=Date.now;
  Date.now=()=>later;
  try {
    const next=await request('/v1/email-auth/start',{email:'person@example.com'});
    const again=await request('/v1/email-auth/verify',{challengeId:next.body.challengeId,code:sent[1].text.match(/\b\d{6}\b/)[0]});
    assert.equal(again.body.userId,anonymous);
    const orders=await request('/v1/me/customization-orders',undefined,again.body.token);
    assert.equal(orders.body.items[0].id,created.body.id);
  } finally {Date.now=originalNow;}
});

test('unconfigured mail and provider failure do not pretend a code was sent',async t=>{
  const {request}=await fixture(t,{mailer:{enabled:false},requireOrderEmail:false});
  assert.deepEqual((await request('/v1/email-auth/config')).body,{enabled:false,requireOrderEmail:false});
  assert.equal((await request('/v1/email-auth/start',{email:'person@example.com'})).status,503);
});

test('provider failure invalidates emailed code and hides provider errors',async t=>{
  let delivered;
  const {request,store}=await fixture(t,{mailer:{enabled:true,send:async m=>{delivered=m;throw new Error('secret-api-key');}}});
  const result=await request('/v1/email-auth/start',{email:'person@example.com'});
  assert.equal(result.status,503);assert.equal(result.body.code,'EMAIL_SEND_FAILED');
  assert.throws(()=>store.verifyEmailChallenge(delivered.idempotencyKey.replace('verify/',''),delivered.text.match(/\b\d{6}\b/)[0]),/INVALID_EMAIL_CHALLENGE/);
});

test('revoked guest session cannot bind email but revoked owner can recover by emailed code',async t=>{
  const {store,sent,request}=await fixture(t);
  const guest=store.createUser(),token=store.createSession(guest);
  const start=await request('/v1/email-auth/start',{email:'revoked-guest@example.com'},token);
  const code=sent[0].text.match(/\b\d{6}\b/)[0];
  store.revokeSession(token);
  const denied=await request('/v1/email-auth/verify',{challengeId:start.body.challengeId,code},token);
  assert.equal(denied.status,400);
  assert.equal(denied.body.code,'INVALID_EMAIL_CHALLENGE');
  assert.deepEqual(store.emailAccount(guest),{userId:guest,email:null,emailVerified:false});

  const validToken=store.createSession(guest);
  const owner=await request('/v1/email-auth/verify',{challengeId:start.body.challengeId,code},validToken);
  assert.equal(owner.status,200);
  assert.equal(owner.body.userId,guest);
  const originalNow=Date.now,later=Date.now()+61000;
  Date.now=()=>later;
  try {
    const login=await request('/v1/email-auth/start',{email:'revoked-guest@example.com'},owner.body.token);
    store.revokeSession(owner.body.token);
    const recovered=await request('/v1/email-auth/verify',{
      challengeId:login.body.challengeId,code:sent[1].text.match(/\b\d{6}\b/)[0],
    },owner.body.token);
    assert.equal(recovered.status,200);
    assert.equal(recovered.body.userId,guest);
    assert.equal(store.authenticate(recovered.body.token),guest);
  } finally {Date.now=originalNow;}
});

test('expired guest session cannot bind an otherwise valid challenge',async t=>{
  const {store,sent,request}=await fixture(t);
  const guest=store.createUser(),token=store.createSession(guest,1);
  const start=await request('/v1/email-auth/start',{email:'expired-guest@example.com'},token);
  const originalNow=Date.now,later=Date.now()+2000;
  Date.now=()=>later;
  try {
    const denied=await request('/v1/email-auth/verify',{
      challengeId:start.body.challengeId,code:sent[0].text.match(/\b\d{6}\b/)[0],
    },token);
    assert.equal(denied.status,400);
    assert.equal(denied.body.code,'INVALID_EMAIL_CHALLENGE');
    assert.equal(store.emailAccount(guest).emailVerified,false);
  } finally {Date.now=originalNow;}
});
