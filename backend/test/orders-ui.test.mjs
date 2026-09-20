import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { readFile } from 'node:fs/promises';

const source=await readFile(new URL('../public/orders.js',import.meta.url),'utf8');
test('admin detail shows server verified order contact without treating legacy email as verified',()=>{
  const h=harness(async()=>{});
  h.run("renderOrderDetail({id:'one',version:1,status:'free_review',verifiedContactEmail:'buyer@example.com'})");
  const values=[];function walk(n){values.push(n.textContent);for(const c of n.children)walk(c);}walk(h.$('order-detail-body'));
  assert(values.includes('已验证联系邮箱：buyer@example.com'));
});

test('order gallery loads thumbnails and offers preview separately from original',()=>{
  const h=harness(async()=>{});
  h.run("renderOrderDetail({id:'one',version:1,status:'free_review',materials:[{id:'photo',contentType:'image/png',name:'reference.png',bytes:1250000}]})");
  const flatten=node=>[node,...node.children.flatMap(flatten)];
  const nodes=flatten(h.$('order-detail-body'));
  assert.equal(nodes.find(node=>node.tag==='img').src,'/admin/customization-orders/one/materials/photo?variant=thumbnail');
  assert(nodes.some(node=>node.tag==='a'&&node.href==='/admin/customization-orders/one/materials/photo?variant=preview'));
  assert(nodes.some(node=>node.tag==='a'&&node.textContent==='查看原图'&&node.href==='/admin/customization-orders/one/materials/photo'));
});

test('legacy unassigned production offers recovery and recovered order explains required upload',()=>{
  const h=harness(async()=>{});
  const labels=()=>{const nodes=[];function walk(n){nodes.push(n.textContent);for(const c of n.children)walk(c);}walk(h.$('order-detail-body'));return nodes;};
  h.run("renderOrderDetail({id:'legacy',version:6,status:'in_production'})");
  assert(labels().includes('退回补充资料并重走派单'));
  h.run("renderOrderDetail({id:'legacy',version:7,status:'needs_info',legacyRecoveryAt:'2026-09-17',materials:[]})");
  assert(labels().some(x=>x.includes('等待用户上传真实素材')));
});
function harness(api, permissions = null) {
  class Element {
    constructor(tag='div',value='') {this.tag=tag;this.textContent=value;this.children=[];this.value='';this.open=false;this.isConnected=true;this.listeners={};}
    append(...children){this.children.push(...children);}
    prepend(...children){this.children.unshift(...children);}
    querySelectorAll(selector){return this.children.flatMap(n=>[...(selector==='[name]'?n.name?[n]:[]:selector.split(',').includes(n.tag)?[n]:[]),...n.querySelectorAll(selector)]);}
    get elements(){return Object.fromEntries(this.querySelectorAll('[name]').map(n=>[n.name,n]));}
    replaceChildren(...children){this.children=children;}
    setAttribute(){}
    addEventListener(name,fn){this.listeners[name]=fn;}
    showModal(){this.open=true;}
    close(){this.open=false;this.listeners.close?.();}
  }
  const elements=new Map();const $=id=>{if(!elements.has(id))elements.set(id,new Element());return elements.get(id);};
  const context=vm.createContext({canAdmin:key=>permissions===null || permissions.includes(key),document:{getElementById:$,createElement:tag=>new Element(tag)},$,text:(tag,value)=>new Element(tag,value),api,epoch:0,orders:[],orderLabels:{free_review:'待预审',quoted:'待用户确认报价'},orderTransitions:{quoted:['in_production','needs_info']},URLSearchParams,setTimeout,clearTimeout,Date,console});
  vm.runInContext(source,context);
  return {context,$,run:code=>vm.runInContext(code,context)};
}

test('view-only order detail retains information but has no dispatch, recovery or transition writes', () => {
  const h = harness(async()=>{}, ['orders.view']);
  h.run("orderTransitions.approved_for_quote=['quoted','needs_info']; renderOrderDetail({id:'one',version:1,status:'approved_for_quote'})");
  assert.equal(h.$('order-detail-body').querySelectorAll('button').length, 0);
  h.run("renderOrderDetail({id:'one',version:1,status:'in_production'})");
  assert.equal(h.$('order-detail-body').querySelectorAll('button').length, 0);
});

test('order status permissions distinguish quote, delivery, cancellation and review', () => {
  const h = harness(async()=>{}, ['orders.review']);
  assert.equal(h.run("canOrderAction('needs_info')"), true);
  for (const state of ['quoted','in_production','withdrawn']) assert.equal(h.run(`canOrderAction('${state}')`), false);
});

test('order approvals hide prose while rejection and returned QC require it',async()=>{
  let calls=0;const h=harness(async()=>{calls++;});
  h.run("orderFields=()=>document.createElement('div')");
  for(const [from,to,required] of [['free_review','approved_for_quote',false],['quality_review','user_acceptance',false],['free_review','rejected',true],['free_review','needs_info',true],['quality_review','in_production',true],['user_acceptance','quality_review',true]]) {
    h.run(`showOrderAction({id:'one',status:'${from}',version:1},'${to}',document.getElementById('action'))`);
    const form=h.$('action').children.find(n=>n.tag==='form'),note=form.elements.note;
    assert.equal(note.required,required);assert.equal(note.disabled,!required);
    const label=form.children.find(n=>n.children.includes(note));assert.equal(label.hidden,!required);
    if(required) {note.value='  ';form.onsubmit({preventDefault(){}});assert.equal(calls,0);}
  }
});
test('server filters and pagination use server totals rather than page length',async()=>{
  let path;const h=harness(async value=>{path=value;return {items:[],total:35,page:1,counts:{total:70,free_review:11,in_production:9}};});
  h.$('order-search').value='角色 & 名称';h.$('order-status').value='quoted';h.$('order-dispatch').value='direct';
  await h.run('refreshOrders()');
  const query=new URL(path,'http://localhost').searchParams;
  assert.equal(query.get('q'),'角色 & 名称');assert.equal(query.get('status'),'quoted');assert.equal(query.get('dispatchMode'),'direct');assert.equal(query.get('pageSize'),'20');
  assert.equal(h.$('orders-total').textContent,70);assert.equal(h.$('orders-review').textContent,11);assert.equal(h.$('orders-next').disabled,false);
});
test('late page responses cannot replace current search results',async()=>{
  const pending=[];const h=harness(()=>new Promise(resolve=>pending.push(resolve)));
  const first=h.run('refreshOrders()'), second=h.run('refreshOrders()');
  pending[1]({items:[],total:2,page:1,counts:{total:2}});await second;
  pending[0]({items:[],total:99,page:1,counts:{total:99}});await first;
  assert.equal(h.$('orders-total').textContent,2);
});
test('load failure replaces stale results with a retry control',async()=>{
  const h=harness(async()=>{throw new Error('登录已过期');});
  await assert.rejects(h.run('refreshOrders()'),/登录已过期/);
  assert.equal(h.$('orders-page').textContent,'订单加载失败');assert.equal(h.$('order-cards').children[1].textContent,'重试');assert.equal(h.$('orders-next').disabled,true);
});
test('closing detail invalidates late private order response',async()=>{
  let resolve;const h=harness(()=>new Promise(done=>resolve=done));
  const pending=h.run("openOrderDetail('one')");h.run('clearOrderDetail()');resolve({id:'one',requirements:'私密需求'});await pending;
  assert.equal(h.$('order-detail').open,false);assert.equal(h.$('order-detail-body').children.length,0);
});
test('dispatched quotes wait for real user acceptance and legacy uploads are honest',()=>{
  const h=harness(async()=>{});
  h.run("renderOrderDetail({id:'one',version:1,status:'quoted',dispatchMode:'direct',materialsUploaded:true,materialCount:3})");
  const nodes=[];function walk(node){nodes.push(node);for(const child of node.children)walk(child);}walk(h.$('order-detail-body'));
  assert(nodes.some(node=>node.textContent.includes('没有可查看的原始图片')));
  assert(nodes.some(node=>node.textContent.includes('后台不能代替用户确认')));
  assert(!nodes.some(node=>node.tag==='button'&&node.textContent==='开始制作'));
});
test('next-step labels describe actions and distinguish returning work from starting production',()=>{
  const h=harness(async()=>{});
  assert.equal(h.run("orderActionLabel('approved_for_quote','free_review')"),'通过预审');
  assert.equal(h.run("orderActionLabel('needs_info','free_review')"),'退回补充资料');
  assert.equal(h.run("orderActionLabel('in_production','quoted')"),'开始制作');
  assert.equal(h.run("orderActionLabel('in_production','quality_review')"),'退回制作');
  assert.equal(h.run("orderActionLabel('quality_review','user_acceptance')"),'重新质检');
});
test('assigned orders at quote stage can be reassigned or reopened for applicants',()=>{
  const h=harness(async()=>{});
  h.run("renderOrderDetail({id:'one',version:2,status:'approved_for_quote',dispatchMode:'applications',assignedCreatorId:'creator-one'})");
  const labels=[];function walk(node){if(node.tag==='button')labels.push(node.textContent);for(const child of node.children)walk(child);}walk(h.$('order-detail-body'));
  assert(labels.includes('改派给创作者'));assert(labels.includes('重新开放报名'));assert(labels.includes('选择已报名创作者'));
});
