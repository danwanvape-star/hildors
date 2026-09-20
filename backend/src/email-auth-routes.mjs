import {isIP} from 'node:net';

export async function emailAuthRoute({req,url,store,send,fail,readJson,mailer,requireOrderEmail,trustLocalProxy=false}) {
  if(!url.pathname.startsWith('/v1/email-auth/')) return false;
  const path=url.pathname;
  if(req.method==='GET' && path==='/v1/email-auth/config') {
    send(200,{enabled:mailer?.enabled===true,requireOrderEmail});return true;
  }
  if(req.method!=='POST'||!['/v1/email-auth/start','/v1/email-auth/verify'].includes(path)) {fail(404,'NOT_FOUND');return true;}
  if(mailer?.enabled!==true) {fail(503,'EMAIL_SERVICE_UNAVAILABLE');return true;}
  const value=await readJson();
  const token=/^Bearer ([A-Za-z0-9_-]{43})$/.exec(req.headers.authorization||'')?.[1];
  const userId=store.authenticate(token);
  try {
    if(path.endsWith('/start')) {
      const remote=req.socket.remoteAddress||'';
      const proxy=trustLocalProxy&&['127.0.0.1','::1','::ffff:127.0.0.1'].includes(remote);
      const forwarded=req.headers['x-real-ip'];
      const ip=proxy&&typeof forwarded==='string'&&isIP(forwarded)?forwarded:remote;
      const challenge=store.startEmailChallenge(value?.email,{userId,ip});
      try {
        await mailer.send({to:challenge.email,subject:'Your Hildors verification code',
          text:`Your Hildors verification code is ${challenge.code}.\n\nIt expires in 10 minutes. Use it to verify your email and securely access your orders. Do not share this code. If you did not request it, ignore this email.`,
          idempotencyKey:`verify/${challenge.challengeId}`});
      } catch {
        store.invalidateEmailChallenge(challenge.challengeId);fail(503,'EMAIL_SEND_FAILED');return true;
      }
      send(200,{challengeId:challenge.challengeId,expiresIn:challenge.expiresIn,resendAfter:challenge.resendAfter});
    } else {
      send(200,store.verifyEmailChallenge(value?.challengeId,value?.code,{userId,requireExisting:value?.existingAccountOnly===true}));
    }
  } catch(error) {
    if(error.message==='EMAIL_RATE_LIMITED') {fail(429,'EMAIL_RATE_LIMITED');return true;}
    if(['INVALID_EMAIL','INVALID_EMAIL_CHALLENGE'].includes(error.message)) {fail(400,error.message);return true;}
    throw error;
  }
  return true;
}
