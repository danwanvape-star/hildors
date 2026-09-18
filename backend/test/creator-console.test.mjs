import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { readFileSync } from 'node:fs';

function fixture() {
  class Element {
    constructor(tag = '') { this.tagName = tag; this.children = []; this.value = ''; this.dataset = {}; this.classList = { add() {}, toggle() {} }; }
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
const emptyPage = { items: [], total: 0, page: 1, summary: { total: 24, pending: 16, approved: 8, suspended: 0 } };

test('creator filters request server pages and render server totals', async () => {
  const { get, run, context } = fixture();
  context.result = { ...emptyPage, total: 24, page: 2 };
  get('creator-search').value = '青岚'; get('creator-status').value = 'approved'; get('creator-tier').value = 'partner';
  get('creator-ability').value = 'diamond';
  await run("creatorPage = 2; api = async path => { globalThis.requested = path; return result; }; refreshCreators();");
  const url = new URL(context.requested, 'http://test');
  assert.equal(url.searchParams.get('q'), '青岚'); assert.equal(url.searchParams.get('page'), '2');
  assert.equal(url.searchParams.get('tier'), 'partner'); assert.equal(url.searchParams.get('status'), 'approved');
  assert.equal(url.searchParams.get('abilityLevel'), 'diamond');
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

const videoApplicant = { id: 'creator/one', version: 3, displayName: '青岚', applicationVersion: 2, status: 'pending',
  characterTags: ['仙侠'], skillTags: ['简单动作', '歌舞表演', '特效炫技', '角色成长'],
  portfolioUrl: 'https://example.com/legacy', management: { tier: 'partner' },
  applicationVideos: [{ id: 'video/one', name: '表演.mp4', bytes: 1048576, inspection: { status: 'checked', validation: 'decoded' } }] };
const contents = node => [node.textContent || '', ...(node.children || []).map(contents)].join(' ');

test('video applications render private manual playback, categories and independent human grades', () => {
  const { get, run, context } = fixture(); context.applicant = videoApplicant;
  run('renderCreatorDetail({creator:applicant,works:[]})');
  const root = get('creator-detail-body'), video = root.querySelector('video');
  assert.equal(video.src, '/admin/creators/creator%2Fone/application-videos/video%2Fone');
  assert.equal(video.controls, true); assert.equal(video.preload, 'none'); assert.notEqual(video.autoplay, true);
  assert.match(contents(root), /擅长角色.*仙侠.*擅长内容方向.*简单动作.*歌舞表演.*特效炫技.*角色成长/);
  assert.equal(root.querySelectorAll('a').length, 0);
  const grade = root.querySelectorAll('select').find(select => select.name === 'abilityLevel');
  assert.deepEqual(grade.children.map(option => option.textContent), ['未评级', '白银', '黄金', '钻石', '宗师', '大神']);
  assert.ok(grade.children[0].selected);
  assert.ok(root.querySelectorAll('select').find(select => select.name === 'tier').children.find(option => option.value === 'partner').selected);
  run('clearCreatorDetail()'); assert.equal(video.paused, true); assert.equal(video.src, undefined); assert.equal(video.reloaded, true);
});

test('legacy portfolios remain visible without inferring an ability grade', () => {
  const { get, run, context } = fixture(); context.applicant = { ...videoApplicant, applicationVersion: 1, applicationVideos: [] };
  run('renderCreatorDetail({creator:applicant,works:[]})');
  assert.equal(get('creator-detail-body').querySelector('a').href, videoApplicant.portfolioUrl);
  assert.match(contents(get('creator-detail-body')), /未评级/);
});

test('approval requires submission, checked videos and a selected human grade', async () => {
  for (const [patch, form, message] of [
    [{ status: 'draft' }, { abilityLevel: 'gold' }, /尚未正式提交/],
    [{ applicationVideos: [] }, { abilityLevel: 'gold' }, /申请视频/],
    [{ applicationVideos: [...videoApplicant.applicationVideos, { inspection: { status: 'failed' } }] }, { abilityLevel: 'gold' }, /技术检查/],
    [{ applicationVideos: [{ inspection: { status: 'checked', validation: 'container_only' } }] }, { abilityLevel: 'gold' }, /技术检查/],
    [{}, {}, /请选择能力等级/],
  ]) {
    const { get, run, context } = fixture(); context.applicant = { ...videoApplicant, ...patch }; context.form = { status: 'approved', note: '已审核', ...form };
    await run('selectedCreator = applicant; let mutations = 0; api = async () => { mutations++; }; saveCreator({preventDefault(){},target:form},applicant,document.getElementById("fields"),document.getElementById("error"))');
    assert.equal(run('mutations'), 0); assert.match(get('error').textContent, message);
  }
});

test('save submits grade separately from cooperation tier and blocks duplicate saves', async () => {
  const { run, context, get } = fixture(); context.applicant = videoApplicant;
  const initialNotice = get('notice').textContent;
  run('selectedCreator = applicant; let finishSave; let mutations = 0; api = (path, body) => { if (body) { mutations++; globalThis.saved = body; return new Promise(resolve => finishSave = resolve); } return Promise.resolve({items:[],total:0,page:1,summary:{}}); };');
  const save = () => run('saveCreator({preventDefault(){},target:{status:"approved",abilityLevel:"diamond",tier:"partner",note:"质量、创意符合钻石等级",commissionRate:"15",canPublish:true}},applicant,document.getElementById("fields"),document.getElementById("error"))');
  const first = save(); await save(); assert.equal(run('mutations'), 1);
  assert.equal(context.saved.abilityLevel, 'diamond'); assert.equal(context.saved.tier, 'partner'); assert.equal(context.saved.canPublish, true);
  assert.equal(get('fields').disabled, true);
  run('epoch++; clearCreatorManagement(); finishSave({});'); await first;
  assert.equal(get('creator-detail-body').children.length, 0); assert.equal(get('notice').textContent, initialNotice);
});
