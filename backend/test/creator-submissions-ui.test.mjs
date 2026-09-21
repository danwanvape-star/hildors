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

test('creator review shortcut clears stale filters, refreshes and only shows pending creator submissions', async () => {
  const { get, run, context } = fixture();
  context.records = ['pending', 'draft', 'approved', 'rejected'].map((submissionStatus, i) => ({id: String(i), title: submissionStatus, ownerId: 'user', source: 'creator', status: 'draft', submissionStatus, tags: [], clips: [], format: 'single'}));
  context.records.push({id:'official', title:'official', source:'hildors', status:'draft', submissionStatus:'pending', tags:[], clips:[], format:'single'});
  get('search').value = 'old'; get('format-filter').value = 'package'; get('tag-filter').value = 'old';
  run("api = async path => ({items:path === '/admin/packages' ? records : []}); contentPage = 8;");
  assert.equal(typeof get('creator-submissions').onclick, 'function');
  await get('creator-submissions').onclick();
  assert.equal(get('source-filter').value, 'creator'); assert.equal(get('status').value, 'pending');
  assert.equal(get('search').value, ''); assert.equal(get('format-filter').value, ''); assert.equal(get('tag-filter').value, '');
  assert.equal(run('contentPage'), 1); assert.equal(run('activeView'), 'content');
  assert.equal(get('cards').children.length, 1);
  assert.equal(get('cards').children[0].querySelectorAll('button')[0].textContent, '查看并审核');
  assert.equal(get('creator-pending-count').textContent, '1');
});

test('empty creator queue explains upload versus submit and refresh failure is visible', async () => {
  const { get, run } = fixture();
  run("items = []; api = async () => ({items:[]});");
  await get('creator-submissions').onclick();
  assert.match(get('cards').children[0].textContent, /提交审核/);
  run("api = async () => { throw new Error('登录已过期'); };");
  await get('creator-submissions').onclick();
  assert.match(get('notice').textContent, /登录已过期/);
});

test('unsubmitted creator media does not misleadingly say it can be reviewed', () => {
  const { get, run, context } = fixture();
  context.record = {id:'draft', title:'Draft', ownerId:'user', source:'creator', format:'single', status:'draft', submissionStatus:'draft', tags:[], clips:[]};
  run('renderDetail(record)');
  const paragraphs = get('detail-body').querySelectorAll('p').map(el => el.textContent).join(' ');
  assert.match(paragraphs, /尚未提交审核/);
  assert.equal(get('detail-body').querySelectorAll('button').some(el => el.textContent === '审核内容'), false);
});
