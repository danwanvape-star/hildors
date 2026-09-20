import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFileSync} from 'node:fs';
const source=readFileSync(new URL('../public/app.js',import.meta.url),'utf8');
function fixture(){
 const nodes=new Map(),get=id=>{if(!nodes.has(id))nodes.set(id,{hidden:false,textContent:''});return nodes.get(id);};
 const states=[];
 const context=vm.createContext({$:get,window:{location:{hash:'#content'}},refreshAdminIdentity:async()=>({actor:{isRoot:true},permissions:[]}),canAdmin:()=>true,showConnection:value=>states.push(value),showView:()=>{},openOwnPassword:()=>{},loadAdminView:async()=>{},endAdminSession:()=>states.push(false)});
 vm.runInContext("let epoch=0,activeView='content';const adminViews={content:'content.view'};",context);
 const start=source.slice(source.indexOf('async function startAdminSession()'),source.indexOf('async function refresh()'));
 vm.runInContext(start,context);
 return {context,states,get,run:code=>vm.runInContext(code,context)};
}
test('verified session is shown before the business request finishes',async()=>{
 const f=fixture();let done;f.context.loadAdminView=()=>new Promise(resolve=>{done=resolve;});
 const work=f.run('startAdminSession()');await new Promise(resolve=>setImmediate(resolve));
 assert.deepEqual(f.states,[true]);done();await work;
});
for(const status of [403,500,undefined])test('business failure '+status+' does not request login',async()=>{
 const f=fixture();f.context.loadAdminView=async()=>{throw Object.assign(new Error('request failed'),{status});};
 await f.run('restoreAdminSession()');
 assert.ok(f.states.includes(true));assert.equal(f.states.includes(false),false);
 assert.equal(f.get('session-retry').hidden,false);
});
test('expired session returns to login and stale startup failures cannot log out a newer session',async()=>{
 const f=fixture();f.context.refreshAdminIdentity=async()=>{throw Object.assign(new Error('expired'),{status:401});};
 await f.run('restoreAdminSession()');assert.deepEqual(f.states,[false]);
 f.states.length=0;let reject;f.context.refreshAdminIdentity=()=>new Promise((_,r)=>{reject=r;});
 const work=f.run('restoreAdminSession()');f.run('epoch++');reject(Object.assign(new Error('expired'),{status:401}));await work;
 assert.deepEqual(f.states,[]);
});

test('API errors preserve HTTP status for session decisions',async()=>{
 const apiSource=source.slice(source.indexOf('async function api('),source.indexOf('function text('));
 const context=vm.createContext({messages:{},fetch:async()=>({ok:false,status:403,json:async()=>({code:'PERMISSION_DENIED'})})});
 vm.runInContext(apiSource,context);
 await assert.rejects(vm.runInContext("api('/admin/packages')",context),error=>error.status===403&&error.code==='PERMISSION_DENIED');
});
