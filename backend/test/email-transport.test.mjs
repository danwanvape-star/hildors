import test from 'node:test';
import assert from 'node:assert/strict';
import {emailConfig,createMailer} from '../src/email-transport.mjs';

test('email defaults disabled and cannot require verification with no provider',()=>{
  const config=emailConfig({});
  assert.equal(config.enabled,false);
  assert.equal(config.requireOrderEmail,false);
  assert.throws(()=>emailConfig({HILDORS_REQUIRE_ORDER_EMAIL:'1'}),/provider/i);
  assert.throws(()=>emailConfig({HILDORS_MAIL_PROVIDER:'resend'}),/credential/i);
});

test('mailer sends only server-owned headers with stable idempotency and refuses redirects',async()=>{
  const calls=[];
  const config=emailConfig({HILDORS_MAIL_PROVIDER:'resend',HILDORS_MAIL_FROM:'Hildors <orders@example.com>',HILDORS_MAIL_API_KEY:'test-key',HILDORS_EMAIL_CODE_SECRET:'s'.repeat(40),HILDORS_REQUIRE_ORDER_EMAIL:'1'});
  const mailer=createMailer(config,{fetchImpl:async(url,options)=>{calls.push({url,options});return new Response(JSON.stringify({id:'sent-id'}),{status:200});}});
  await mailer.send({to:'customer@example.com',subject:'Your code',text:'123456',idempotencyKey:'challenge-1'});
  assert.equal(calls[0].url,'https://api.resend.com/emails');
  assert.equal(calls[0].options.redirect,'error');
  assert.equal(calls[0].options.headers['Idempotency-Key'],'challenge-1');
  assert.deepEqual(JSON.parse(calls[0].options.body).to,['customer@example.com']);
  assert.equal(JSON.parse(calls[0].options.body).from,'Hildors <orders@example.com>');
});

test('provider errors are sanitized and disabled mail never calls network',async()=>{
  const disabled=createMailer(emailConfig({}),{fetchImpl:()=>assert.fail('no network')});
  await assert.rejects(disabled.send({}),/EMAIL_SERVICE_UNAVAILABLE/);
  const configured={enabled:true,apiKey:'secret',from:'sender@example.com'};
  for(const status of [400,429,500]) {
    const mailer=createMailer(configured,{fetchImpl:async()=>new Response('secret provider detail',{status})});
    await assert.rejects(mailer.send({to:'a@example.com',subject:'Hi',text:'body',idempotencyKey:'key'}),error=>{
      assert.equal(error.message,'EMAIL_SEND_FAILED');
      assert.equal(error.retryable,status===429||status>=500);return true;
    });
  }
});
