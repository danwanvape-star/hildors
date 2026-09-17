import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { readFileSync } from 'node:fs';



function consoleApp() {
  class Element {
    constructor(tag = 'div') { this.tagName = tag; this.children = []; this.value = ''; this.classList = { add() {}, toggle() {} }; this.dataset = {}; }
    append(...nodes) { this.children.push(...nodes); }
    prepend(...nodes) { this.children.unshift(...nodes); }
    replaceChildren(...nodes) { this.children = nodes; }
    setAttribute() {}
    addEventListener() {}
    close() { this.open = false; }
    showModal() { this.open = true; }
    querySelectorAll() { return []; }
  }
  const elements = new Map(), calls = [];
  const get = id => { if (!elements.has(id)) elements.set(id, new Element()); return elements.get(id); };
  const context = vm.createContext({
    document: { getElementById: get, createElement: tag => new Element(tag), querySelectorAll: () => [] },
    window: { addEventListener() {} }, URL, URLSearchParams, setTimeout, clearTimeout, console, crypto: { randomUUID: () => 'id' },
    FormData: class { constructor(target) { this.data = target; } get(key) { return this.data[key] ?? ''; } has(key) { return key in this.data; } },
    fetch: () => new Promise(() => {}), confirm: () => true,
  });
  const html = readFileSync(new URL('../public/index.html', import.meta.url), 'utf8');
  for (const match of html.matchAll(/<script src="\/console\/([^\"]+)"/g)) {
    vm.runInContext(readFileSync(new URL(`../public/${match[1]}`, import.meta.url), 'utf8'), context);
  }
  context.calls = calls;
  return { context, get, calls };
}

test('review approval saves approval without publishing content', async () => {
  const { context, get, calls } = consoleApp();
  vm.runInContext(`reviewing = {id:'creator-draft',version:3}; api = async (path, body) => {calls.push({path,body}); return {version:4}}; refresh = async () => {};`, context);
  await get('review-form').onsubmit({ preventDefault() {}, target: { decision: 'approved' } });
  assert.deepEqual(calls.map(x => x.path), ['/admin/packages/creator-draft/review']);
});

test('package creation needs neither video names nor a count and starts empty', async () => {
  const {context,get,calls}=consoleApp();
  get('format').value='package'; get('format').onchange();
  assert.equal(get('clip-names-field').hidden,true);
  assert.equal(get('clip-names').required,false);
  assert.equal(get('clip-names').disabled,true);
  assert.equal(get('package-upload-hint').hidden,false);
  vm.runInContext(`api=async(path,body)=>{calls.push({path,body});return {...body,id:'new',status:'draft'}}; refresh=async()=>{}; selectedTags=()=>['科幻未来'];`,context);
  await get('create').onsubmit({preventDefault(){},target:{title:'角色包',description:'故事',format:'package'}});
  assert.equal(calls.length,1);
  assert.equal(calls[0].body.clips.length,0);
  assert.equal(get('content-detail').open,true);
  assert.equal(vm.runInContext('selectedItemId',context),'new');
  get('format').value='single'; get('format').onchange();
  assert.equal(get('clip-names').required,true);
  assert.equal(get('clip-names').disabled,false);
  assert.equal(get('package-upload-hint').hidden,true);
  assert.doesNotMatch(readFileSync(new URL('../public/index.html',import.meta.url),'utf8'), /name="clipCount"/);
});

test('creation blocks missing genre and rejection alone requires a reason', async () => {
  const {context,get,calls}=consoleApp();
  vm.runInContext(`api=async(path,body)=>{calls.push({path,body});return {}};`,context);
  await get('create').onsubmit({preventDefault(){},target:{title:'包',description:'故事',format:'package'}});
  assert.equal(calls.length,0);assert.match(get('form-error').textContent,/题材/);
  get('review-decision').value='rejected';get('review-decision').onchange();
  assert.equal(get('review-reason').required,true);
  get('review-decision').value='approved';get('review-decision').onchange();
  assert.equal(get('review-reason').disabled,true);
  const html=readFileSync(new URL('../public/index.html',import.meta.url),'utf8');
  assert.doesNotMatch(html,/name="rightsReference"/);
});

test('content list paginates and does not create all upload forms eagerly', () => {
  const { context, get } = consoleApp();
  vm.runInContext(`items = Array.from({length:45},(_,i)=>({id:String(i),title:'角色'+i,format:'single',source:'hildors',status:'draft',tags:[],clips:[{id:'c',title:'待机'}]})); render();`, context);
  assert.equal(get('cards').children.length, 20);
  assert.match(get('page-info').textContent, /1.*3/);
  assert.equal(get('detail-body').children.length, 0);
});

test('content search combines moderation, source, format and tags', () => {
  const {context,get}=consoleApp();
  vm.runInContext(`items = [
    {id:'pending',title:'星河角色',creator:{name:'Nova'},source:'creator',status:'draft',submissionStatus:'pending',format:'package',tags:['科幻未来'],clips:[{id:'c'}]},
    {id:'approved',title:'星河角色',source:'creator',status:'draft',submissionStatus:'approved',format:'package',tags:['科幻未来'],clips:[{id:'c'}]},
    {id:'official',title:'星河角色',source:'hildors',status:'draft',format:'single',tags:['科幻未来'],clips:[{id:'c'}]}
  ];`,context);
  get('status').value='pending'; get('source-filter').value='creator'; get('format-filter').value='package'; get('tag-filter').value='科幻未来'; get('search').value='Nova';
  vm.runInContext('render()',context);
  assert.equal(get('cards').children.length,1);
  assert.equal(get('result-count').textContent,'共 1 条内容');
  get('search').value='missing'; vm.runInContext('resetPage()',context);
  assert.equal(get('result-count').textContent,'共 0 条内容');
});

test('pending creator detail provides moderation but no media or metadata editing', () => {
  const {context,get}=consoleApp();
  vm.runInContext(`renderDetail({id:'pending',title:'角色',description:'背景故事',source:'creator',ownerId:'owner',status:'draft',submissionStatus:'pending',format:'single',tags:[],clips:[{id:'c',title:'Clip'}]})`,context);
  const flatten=node=>[node,...(node.children??[]).flatMap(flatten)];
  const nodes=flatten(get('detail-body'));
  assert.ok(nodes.some(node=>node.textContent==='审核内容'));
  assert.ok(!nodes.some(node=>node.type==='file'));
  assert.ok(!nodes.some(node=>node.textContent==='编辑名称、题材与介绍'));
  assert.ok(nodes.some(node=>node.textContent==='待审核'));
});
