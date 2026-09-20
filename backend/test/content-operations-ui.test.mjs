import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { readFileSync } from 'node:fs';

function fixture() {
  class Element {
    constructor(tag = '') { this.tagName = tag; this.children = []; this.dataset = {}; this.classList = { add() {}, toggle() {} }; }
    get value() { return this._value ?? (this.tagName === 'select' ? this.children.find(option => option.selected)?.value : '') ?? ''; }
    set value(value) { this._value = value; }
    append(...nodes) { this.children.push(...nodes); }
    prepend(...nodes) { this.children.unshift(...nodes); }
    replaceChildren(...nodes) { this.children = nodes; }
    setAttribute() {}
    addEventListener() {}
    querySelectorAll(tag) { return this.children.flatMap(node => node instanceof Element ? [...(node.tagName === tag ? [node] : []), ...node.querySelectorAll(tag)] : []); }
    querySelector(tag) { return this.querySelectorAll(tag)[0]; }
    removeAttribute(key) { delete this[key]; }
    pause() { this.paused = true; }
    load() { this.reloaded = true; }
    close() { this.open = false; }
    showModal() { this.open = true; }
    focus() {}
  }
  const elements = new Map(), get = id => { if (!elements.has(id)) elements.set(id, new Element()); return elements.get(id); };
  const context = vm.createContext({ document: { getElementById: get, createElement: tag => new Element(tag), querySelectorAll: () => [] },
    window: { addEventListener() {} }, URL, URLSearchParams, setTimeout, clearTimeout, console,
    FormData: class { constructor(data) { this.data = data; } get(key) { return this.data[key] ?? ''; } has(key) { return key in this.data; } },
    fetch: () => new Promise(() => {}), confirm: () => true });
  const html = readFileSync(new URL('../public/index.html', import.meta.url), 'utf8');
  for (const match of html.matchAll(/<script src="\/console\/([^\"]+)"/g)) vm.runInContext(readFileSync(new URL(`../public/${match[1]}`, import.meta.url), 'utf8'), context);
  const run = source => vm.runInContext(source, context);
  return { get, run, context };
}

test('state tabs count separately and recycle bin stays outside default list', () => {
  const {get,run,context}=fixture();
  context.records=['draft','pending','approved','published','withdrawn','rejected','deleted'].map((state,i)=>({id:`item-${i}`,title:state,tags:[],clips:[],source:'hildors',format:'single',status:['published','withdrawn'].includes(state)?state:'draft',submissionStatus:state,deletedAt:state==='deleted'?'2026-09-19':undefined,version:1}));
  run('items=records; render();');
  assert.equal(get('cards').children.length,6);
  assert.equal(get('content-state-tabs').children.length,8);
  get('content-state-tabs').children.find(x=>x.dataset.state==='withdrawn').onclick();
  assert.equal(get('status').value,'withdrawn');
  assert.equal(get('cards').children.length,1);
  const buttons=get('cards').querySelectorAll('button').map(x=>x.textContent);
  assert.ok(buttons.includes('重新上架')); assert.ok(buttons.includes('删除'));
  get('content-state-tabs').children.find(x=>x.dataset.state==='deleted').onclick();
  assert.equal(get('cards').children.length,1);
  assert.ok(get('cards').querySelectorAll('button').some(x=>x.textContent==='恢复内容'));
});

test('content lifecycle actions require confirmation and current version', async () => {
  const {run,context,get}=fixture();
  context.record={id:'one',title:'测试视频',status:'withdrawn',version:12,tags:[],clips:[]};
  run('globalThis.calls=[]; api=async (path,body)=>{calls.push({path,body});return {items:[]};}; confirm=()=>false;');
  await run("runContentAction(record,'publish')");
  assert.equal(context.calls.length,0);
  run('confirm=()=>true; refresh=async()=>{};');
  await run("runContentAction(record,'publish')");
  assert.equal(context.calls[0].path,'/admin/packages/one/publish');
  assert.equal(context.calls[0].body.version,12);
  assert.match(get('notice').textContent,/上架/);
});



test('limited operator enters permitted module without fetching content or tags', async () => {
  const {run,context,get}=fixture();
  run("globalThis.requests=[]; api=async path=>{requests.push(path); if(path==='/admin/me')return {actor:{id:'op',isRoot:false},permissions:['operators.manage']}; throw new Error('unexpected '+path);}; refreshOperators=async()=>{requests.push('load-operators');};");
  await run('startAdminSession()');
  assert.equal(run('activeView'),'operators'); assert.equal(get('login').hidden,true);
  assert.deepEqual(Array.from(context.requests),['/admin/me','load-operators']);
});
test('account without module permissions still logs in without privileged reads', async () => {
  const {run,get}=fixture();
  run("api=async path=>{if(path==='/admin/me')return {actor:{id:'empty',isRoot:false},permissions:[]}; throw new Error('unexpected read');};");
  await run('startAdminSession()');
  assert.equal(run('activeView'),'empty'); assert.equal(get('login').hidden,true);
  assert.match(get('notice').textContent,/暂无可用/);
});
