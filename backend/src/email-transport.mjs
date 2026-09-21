import {readFileSync} from 'node:fs';

function secret(env,name) {
  if(env[name] && env[`${name}_FILE`]) throw new Error('Configure only one mail credential source');
  return env[`${name}_FILE`] ? readFileSync(env[`${name}_FILE`],'utf8').trim() : env[name] || '';
}
export function emailConfig(env) {
  const provider=env.HILDORS_MAIL_PROVIDER||'disabled';
  if(!['disabled','resend'].includes(provider)) throw new Error('Unsupported mail provider');
  const requirement=env.HILDORS_REQUIRE_ORDER_EMAIL??'0';
  if(!['0','1'].includes(requirement)) throw new Error('Invalid order email requirement');
  if(provider==='disabled') {
    if(requirement==='1') throw new Error('Order email requires a configured mail provider');
    return {provider,enabled:false,requireOrderEmail:false};
  }
  const apiKey=secret(env,'HILDORS_MAIL_API_KEY'),codeSecret=secret(env,'HILDORS_EMAIL_CODE_SECRET');
  const from=env.HILDORS_MAIL_FROM||'';
  if(!apiKey || /[\r\n]/.test(apiKey) || codeSecret.length<32 || !from || from.length>254 || /[\r\n]/.test(from) || !from.includes('@')) throw new Error('Mail provider requires valid credentials, code secret and sender');
  return {provider,enabled:true,requireOrderEmail:requirement==='1',apiKey,codeSecret,from};
}

export function createMailer(config,{fetchImpl=fetch}={}) {
  return {enabled:config.enabled===true,async send({to,subject,text,idempotencyKey}={}) {
    if(!config.enabled) throw new Error('EMAIL_SERVICE_UNAVAILABLE');
    let response;
    try {
      response=await fetchImpl('https://api.resend.com/emails',{
        method:'POST',redirect:'error',signal:AbortSignal.timeout(10000),
        headers:{Authorization:`Bearer ${config.apiKey}`,'Content-Type':'application/json','Idempotency-Key':idempotencyKey},
        body:JSON.stringify({from:config.from,to:[to],subject,text}),
      });
    } catch {const error=new Error('EMAIL_SEND_FAILED');error.retryable=true;throw error;}
    if(!response.ok) {
      await response.body?.cancel();
      const error=new Error('EMAIL_SEND_FAILED');error.retryable=response.status===429||response.status>=500;throw error;
    }
    // Provider response bodies are not logged, forwarded or persisted.
    await response.body?.cancel();
  }};
}
