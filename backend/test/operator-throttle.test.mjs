import test from 'node:test';
import assert from 'node:assert/strict';

test('account attempts remain limited across sources and username case; source also limits varied usernames',async()=>{
 const {loginThrottle}=await import('../src/operator-throttle.mjs');
 let now=0;const throttle=loginThrottle({now:()=>now,accountLimit:2,sourceLimit:3});
 assert.equal(throttle.take('one','User'),0);
 assert.equal(throttle.take('two','user'),0);
 assert.ok(throttle.take('three','USER')>0);
 assert.equal(throttle.take('one','other'),0);
 assert.equal(throttle.take('one','third'),0);
 assert.ok(throttle.take('one','fourth')>0);
 now=15*60*1000+1;assert.equal(throttle.take('one','user'),0);
});
test('throttle fails closed when bounded buckets fill and recovers after expiration',async()=>{
 const {loginThrottle}=await import('../src/operator-throttle.mjs');
 let now=0;const throttle=loginThrottle({now:()=>now,maxBuckets:2});
 assert.equal(throttle.take('one','user'),0);
 for(let i=0;i<50;i++)assert.ok(throttle.take('x'+i,'u'+i)>0);
 now=900001;assert.equal(throttle.take('two','other'),0);
});

test('only explicit trusted loopback proxy can supply validated client address',async()=>{
 const {operatorSource}=await import('../src/operator-throttle.mjs');
 const req={socket:{remoteAddress:'127.0.0.1'},headers:{'x-real-ip':'198.51.100.7'}};
 assert.equal(operatorSource(req,true),'198.51.100.7');
 assert.equal(operatorSource(req,false),'127.0.0.1');
 req.socket.remoteAddress='198.51.100.8';assert.equal(operatorSource(req,true),'198.51.100.8');
 req.socket.remoteAddress='127.0.0.1';req.headers['x-real-ip']='invalid, data';assert.equal(operatorSource(req,true),'127.0.0.1');
});
