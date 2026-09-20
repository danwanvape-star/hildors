import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
export async function operatorLogin(base,credentials){
 const post=(path,body,cookie)=>fetch(base+path,{method:'POST',headers:{'Content-Type':'application/json',...(cookie?{cookie}:{})},body:JSON.stringify(body)});
 let response=await post('/admin/login',credentials);
 assert.equal(response.status,200);
 const data=await response.clone().json();
 if(data.actor?.mustChangePassword){
  const password=randomBytes(24).toString('base64url');
  const changed=await post('/admin/me/password',{currentPassword:credentials.password,password},response.headers.get('set-cookie').split(';')[0]);
  assert.equal(changed.status,200);
  response=await post('/admin/login',{username:credentials.username,password});
  assert.equal(response.status,200);
 }
 return response;
}
