import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFileSync} from 'node:fs';

class Element {
  constructor(tag='div',textContent=''){this.tagName=tag;this.textContent=textContent;this.children=[];this.style={};this.value='';}
  append(...children){this.children.push(...children);}
  replaceChildren(...children){this.children=children;}
  setAttribute(){}
  querySelectorAll(tag){return this.children.flatMap(n=>[...(n.tagName===tag?[n]:[]),...n.querySelectorAll(tag)]);}
}
function harness(file, permissions, records=[]) {
  const elements=new Map(), calls=[], get=id=>{if(!elements.has(id))elements.set(id,new Element());return elements.get(id);};
  const data=path=>path==='/admin/me'?{actor:{id:'one',isRoot:false},permissions}:path==='/admin/reports'?{items:records}:{operations:records};
  const context=vm.createContext({document:{querySelector:get,createElement:tag=>new Element(tag)},$:get,text:(tag,value)=>new Element(tag,value),canAdmin:key=>permissions.includes(key),
    fetch:async(path,options)=>{calls.push({path,options});return{ok:true,json:async()=>data(path)};},api:async path=>{calls.push({path});return data(path);}});
  const ready=vm.runInContext(readFileSync(new URL(`../public/${file}`,import.meta.url),'utf8'),context);
  return {get,calls,context,ready,run:code=>vm.runInContext(code,context)};
}
test('governance without view reads identity but never reports',async()=>{
  const h=harness('governance.js',[]);await h.ready;
  assert.deepEqual(h.calls.map(c=>c.path),['/admin/me']);assert.match(h.get('#message').textContent,/权限/);
});
test('governance viewer sees resolution without editable controls',async()=>{
  const h=harness('governance.js',['governance.view'],[{id:'r',reason:'举报',status:'received',resolution:'已核实',details:'<script>bad</script>'}]);await h.ready;
  assert.equal(h.get('#reports').querySelectorAll('button').length,0);assert.equal(h.get('#reports').querySelectorAll('textarea').length,0);
  assert(h.get('#reports').querySelectorAll('p').some(n=>n.textContent.includes('已核实')));
});
test('governance managers retain handling form',async()=>{
  const h=harness('governance.js',['governance.view','governance.manage'],[{id:'r',reason:'举报',status:'received'}]);await h.ready;
  assert.equal(h.get('#reports').querySelectorAll('button').length,1);
});
test('audit is denied by default and renders only operations safely for permitted viewer',async()=>{
  const denied=harness('audit.js',[]);await denied.run('refreshAudit()');assert.equal(denied.calls.length,0);
  const allowed=harness('audit.js',['audit.view'],[{id:'one',actor:'<img onerror=alert(1)>',action:'publishPackage',targetId:'p',createdAt:'2026-09-20T00:00:00Z',permissions:['content.publish']}]);
  await allowed.run('refreshAudit()');assert.equal(allowed.calls[0].path,'/admin/audit');
  assert(allowed.get('audit-records').querySelectorAll('td').some(n=>n.textContent==='<img onerror=alert(1)>'));
  assert.equal(allowed.get('audit-records').querySelectorAll('img').length,0);
});

test('governance identity failure clears previously displayed records before fetching reports',async()=>{
  const h=harness('governance.js',['governance.view'],[{id:'one',reason:'举报',status:'received'}]);await h.ready;
  assert.equal(h.get('#reports').children.length,1);let calls=0;
  h.context.fetch=async()=>{calls++;return{ok:false,status:401};};
  await h.run('load()');assert.equal(calls,1);assert.equal(h.get('#reports').children.length,0);
  assert.match(h.get('#message').textContent,/登录/);
});

test('audit response after logout cannot repopulate records',async()=>{
  const h=harness('audit.js',['audit.view']);let resolve;
  h.context.api=()=>new Promise(done=>{resolve=done;});
  const pending=h.run('refreshAudit()');h.run('clearAudit()');
  resolve({operations:[{actor:'old session',action:'operator.create'}]});await pending;
  assert.equal(h.get('audit-records').children.length,0);assert.equal(h.get('audit-message').textContent,'');
});
