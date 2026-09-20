import {isIP} from 'node:net';
export function operatorSource(req,trustLocalProxy=false){
 const remote=req.socket.remoteAddress||'unknown';
 const trusted=trustLocalProxy&&['127.0.0.1','::1','::ffff:127.0.0.1'].includes(remote);
 const forwarded=req.headers['x-real-ip'];
 return trusted&&typeof forwarded==='string'&&isIP(forwarded)?forwarded:remote;
}
// Count admitted attempts, including successes, so valid credentials cannot reset
// the source budget. Forwarded addresses require an explicitly trusted local proxy.
export function loginThrottle({now=Date.now,accountLimit=10,sourceLimit=10,maxBuckets=2048,windowMs=15*60*1000}={}) {
 const buckets=new Map();
 return {take(source,username){
  const time=now();
  for(const [key,value] of buckets)if(value.until<=time)buckets.delete(key);
  const keys=[['source:'+source,sourceLimit],['account:'+String(username??'').trim().toLowerCase().slice(0,128),accountLimit]];
  let retry=0;
  for(const [key,limit] of keys){const value=buckets.get(key);if(value?.count>=limit)retry=Math.max(retry,value.until-time);}
  if(retry)return Math.ceil(retry/1000);
  if(buckets.size+keys.filter(([key])=>!buckets.has(key)).length>maxBuckets)return Math.ceil(windowMs/1000);
  for(const [key] of keys){const value=buckets.get(key)??{count:0,until:time+windowMs};value.count++;buckets.set(key,value);}
  return 0;
 }};
}

