import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { readFileSync } from 'node:fs';

function fixture() {
  class Element {
    constructor() { this.children = []; this.value = ''; this.dataset = {}; this.classList = { add() {}, toggle() {} }; }
    append(...nodes) { this.children.push(...nodes); }
    prepend(...nodes) { this.children.unshift(...nodes); }
    replaceChildren(...nodes) { this.children = nodes; }
    setAttribute() {}
    addEventListener() {}
    querySelectorAll() { return []; }
    close() { this.open = false; }
    showModal() { this.open = true; }
  }
  const elements = new Map(), get = id => { if (!elements.has(id)) elements.set(id, new Element()); return elements.get(id); };
  const context = vm.createContext({ document: { getElementById: get, createElement: () => new Element(), querySelectorAll: () => [] },
    window: { addEventListener() {} }, URL, URLSearchParams, setTimeout, clearTimeout, console,
    FormData: class { constructor(data) { this.data = data; } get(key) { return this.data[key] ?? ''; } has(key) { return key in this.data; } },
    fetch: () => new Promise(() => {}), confirm: () => true });
  const html = readFileSync(new URL('../public/index.html', import.meta.url), 'utf8');
  for (const match of html.matchAll(/<script src="\/console\/([^\"]+)"/g)) vm.runInContext(readFileSync(new URL(`../public/${match[1]}`, import.meta.url), 'utf8'), context);
  const run = source => vm.runInContext(source, context);
  return { get, run, context };
}
const emptyPage = { items: [], total: 0, page: 1, summary: { total: 24, pending: 16, approved: 8, suspended: 0 } };

test('creator filters request server pages and render server totals', async () => {
  const { get, run, context } = fixture();
  context.result = { ...emptyPage, total: 24, page: 2 };
  get('creator-search').value = '青岚'; get('creator-status').value = 'approved'; get('creator-tier').value = 'partner';
  await run("creatorPage = 2; api = async path => { globalThis.requested = path; return result; }; refreshCreators();");
  const url = new URL(context.requested, 'http://test');
  assert.equal(url.searchParams.get('q'), '青岚'); assert.equal(url.searchParams.get('page'), '2');
  assert.equal(url.searchParams.get('tier'), 'partner'); assert.equal(url.searchParams.get('status'), 'approved');
  assert.match(get('creators-page').textContent, /2 \/ 2.*24/); assert.equal(get('creators-next').disabled, true);
});

test('late creator page response cannot replace a new filter or resurrect data after logout', async () => {
  const { get, run, context } = fixture(); context.oldPage = { ...emptyPage, total: 99 }; context.newPage = emptyPage;
  run('const pending = []; api = () => new Promise(resolve => pending.push(resolve));');
  const first = run('refreshCreators()'), second = run('refreshCreators()');
  run('pending[1](newPage)'); await second;
  run('pending[0](oldPage)'); await first;
  assert.match(get('creators-page').textContent, /共 0 位/);
  const late = run('refreshCreators()'); run('epoch++; clearCreatorManagement(); pending[2](oldPage);'); await late;
  assert.equal(get('creator-cards').children.length, 0); assert.equal(run('creatorTotal'), 0);
});

test('creator detail close ignores a late response and failed refresh clears stale data', async () => {
  const { get, run } = fixture();
  run('let finishDetail; api = () => new Promise(resolve => { finishDetail = resolve; });');
  const pending = run("openCreatorDetail('one')");
  run("clearCreatorDetail(); finishDetail({creator:{id:'one'},works:[]});"); await pending;
  assert.equal(get('creator-detail').open, false); assert.equal(get('creator-detail-body').children.length, 0);
  await run("api = async () => { throw new Error('登录已过期'); }; refreshCreators();");
  assert.match(get('creators-error').textContent, /登录已过期/); assert.equal(get('creator-cards').children.length, 0);
});

test('creator save rejects blank reasons before sending a mutation', async () => {
  const { get, run } = fixture();
  await run("selectedCreator = {id:'one'}; let mutations = 0; api = async () => { mutations++; }; saveCreator({preventDefault(){},target:{note:'  '}},selectedCreator,document.getElementById('fields'),document.getElementById('error'));");
  assert.equal(run('mutations'), 0); assert.match(get('error').textContent, /原因/);
});
