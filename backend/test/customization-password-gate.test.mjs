import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFileSync} from 'node:fs';

for(const [file,permission,endpoint] of [
 ['customization-orders-v2.js','orders.view','/admin/customization-orders'],
 ['customization-plans.js','plans.view','/admin/customization-plans'],
 ['governance.js','governance.view','/admin/reports'],
 ['account-deletions-admin.js','account_deletions.view','/admin/account-deletions'],
]) {
 async function page(mustChangePassword){
  const elements=new Map(),calls=[];
  const make=()=>({children:[],append(...nodes){this.children.push(...nodes);},replaceChildren(...nodes){this.children=nodes;},style:{}});
  const get=id=>{if(!elements.has(id))elements.set(id,make());return elements.get(id);};
  const context=vm.createContext({document:{getElementById:get,querySelector:selector=>get(selector.slice(1)),createElement:make,querySelectorAll:()=>[]},URLSearchParams,fetch:async path=>{
   calls.push(path);return {ok:true,json:async()=>path==='/admin/me'?{actor:{id:'limited',isRoot:false,mustChangePassword},permissions:[permission]}:{items:[],page:1,pageSize:20,total:0}};
  }});
  vm.runInContext(readFileSync(new URL('../public/'+file,import.meta.url),'utf8').replace('export function','function'),context);
  await new Promise(resolve=>setImmediate(resolve));
  return {calls,get};
 }
 test(file+': temporary password explains next step without requesting business data',async()=>{
  const {calls,get}=await page(true);
  assert.deepEqual(calls,['/admin/me']);
  assert.match(get('message').textContent,/修改本人密码/);
 });
 test(file+': existing authorized account continues to load its module',async()=>{
  const {calls}=await page(false);assert.ok(calls.some(path=>path.startsWith(endpoint)));
 });
}
