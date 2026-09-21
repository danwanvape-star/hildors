import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { readFileSync } from 'node:fs';

function fixture() {
  class Element {
    constructor(tag = '') { this.tagName = tag; this.children = []; this.dataset = {}; this.value = ''; }
    append(...nodes) { this.children.push(...nodes); }
    replaceChildren(...nodes) { this.children = nodes; }
    setAttribute() {}
    addEventListener() {}
    querySelectorAll(tag) { return this.children.flatMap(node => [...(node.tagName === tag ? [node] : []), ...node.querySelectorAll(tag)]); }
    close() { this.open = false; }
    showModal() { this.open = true; }
  }
  const elements = new Map(), get = id => { if (!elements.has(id)) elements.set(id, new Element()); return elements.get(id); };
  const guarded = new Element('button'); guarded.dataset.permission = 'content.delete';
  const context = vm.createContext({ document: { createElement: tag => new Element(tag), querySelectorAll: () => [guarded] },
    $: get, text: (tag, value, className) => Object.assign(new Element(tag), {textContent:value, className}),
    api: async () => ({}), confirm: () => true });
  vm.runInContext(readFileSync(new URL('../public/operators.js', import.meta.url), 'utf8'), context);
  const run = source => vm.runInContext(source, context);
  return {get, run, context, guarded};
}

test('identity starts denied and failed identity refresh removes formerly granted permissions', async () => {
  const {run, context, guarded} = fixture();
  assert.equal(run("canAdmin('content.delete')"), false);
  context.api = async () => ({actor:{id:'one',isRoot:false},permissions:['content.delete']});
  await run('refreshAdminIdentity()'); assert.equal(guarded.hidden, false);
  context.api = async () => { throw new Error('expired'); };
  await assert.rejects(run('refreshAdminIdentity()'), /expired/);
  assert.equal(run("canAdmin('content.delete')"), false); assert.equal(guarded.hidden, true);
});

test('identity response arriving after logout cannot grant access', async () => {
  const {run, context} = fixture(); let resolve;
  context.api = () => new Promise(done => {resolve = done;});
  const pending = run('refreshAdminIdentity()'); run('clearOperatorManagement()');
  resolve({actor:{id:'root',isRoot:true},permissions:['operators.manage']});
  await pending; assert.equal(run("canAdmin('operators.manage')"), false);
});

test('operators endpoint is never loaded without management permission', async () => {
  const {run, context} = fixture(); let calls = 0; context.api = async () => { calls++; return {}; };
  await run('refreshOperators()'); assert.equal(calls, 0);
});

test('presets select exact permissions and manual adjustments are reflected in review', () => {
  const {run, get} = fixture();
  run("operatorCatalog = [{id:'content.view',label:'查看内容',group:'内容'},{id:'content.delete',label:'删除内容',group:'内容'}]; operatorPresets = [{id:'reader',label:'查看员',permissions:['content.view']}]; renderOperatorPermissions(['content.delete']); applyOperatorPreset('reader');");
  assert.deepEqual(Array.from(run('selectedOperatorPermissions()')), ['content.view']);
  run("operatorPermissionInputs.get('content.delete').checked = true; updateOperatorPermissionReview();");
  assert.match(get('operator-permission-review').textContent, /删除内容/);
});

test('create submits the reviewed permission set and clears passwords after success', async () => {
  const {run, get, context} = fixture(); const requests = [];
  context.api = async (path, body) => {
    requests.push({path, body:body ? JSON.parse(JSON.stringify(body)) : undefined});
    if (path === '/admin/me') return {actor:{id:'root',isRoot:true},permissions:[]};
    if (path === '/admin/operators' && !body) return {items:[]};
    if (path === '/admin/permissions') return {catalog:[{id:'content.view',label:'查看内容',group:'内容'}],presets:[]};
    return {item:{id:'new'}};
  };
  await run('refreshAdminIdentity();'); await run('refreshOperators();'); run('openOperatorEditor();');
  get('operator-username').value = 'content.viewer'; get('operator-display-name').value = '审核助理';
  get('operator-password').value = get('operator-password-confirm').value = 'a-strong-password';
  run("operatorPermissionInputs.get('content.view').checked = true;");
  await run('saveOperator({preventDefault(){}})');
  const saved = requests.find(item => item.body);
  assert.deepEqual(saved.body, {username:'content.viewer',displayName:'审核助理',active:true,permissions:['content.view'],password:'a-strong-password'});
  assert.equal(get('operator-password').value, ''); assert.equal(get('operator-password-confirm').value, '');
  assert.equal(get('operator-editor').open, false);
});

test('password reset uses current version, never submits permission edits and clears password on failure', async () => {
  const {run, get, context} = fixture(); let saved;
  run("adminActor = {id:'root',isRoot:true}; operatorCatalog = [{id:'content.view',label:'查看内容',group:'内容'}]; openOperatorEditor({id:'one',username:'operator',displayName:'运营',active:true,version:8,permissions:[]}, true);");
  get('operator-password').value = get('operator-password-confirm').value = 'new-strong-password';
  context.api = async (path, body) => { saved = {path,body:JSON.parse(JSON.stringify(body))}; throw new Error('账号版本冲突'); };
  await run('saveOperator({preventDefault(){}})');
  assert.deepEqual(saved, {path:'/admin/operators/one/password',body:{version:8,password:'new-strong-password'}});
  assert.equal(get('operator-password').value, ''); assert.match(get('operator-form-error').textContent, /账号版本冲突/);
});

test('disabling account requires confirmation and refuses cancelled change', async () => {
  const {run, context} = fixture(); let calls = 0;
  run("adminActor = {id:'root',isRoot:true};");
  context.confirm = () => false; context.api = async () => { calls++; };
  await run("toggleOperatorActive({id:'one',username:'运营',version:3,active:true,permissions:[]})");
  assert.equal(calls, 0);
});

test('short and mismatched passwords fail before any network write', async () => {
  const {run, get, context} = fixture(); let calls = 0;
  run("adminActor = {id:'root',isRoot:true};"); context.api = async () => {calls++;};
  get('operator-password').value = get('operator-password-confirm').value = 'short';
  await run('saveOperator({preventDefault(){}})'); assert.equal(calls, 0);
  get('operator-password').value = 'strong-password'; get('operator-password-confirm').value = 'different-password';
  await run('saveOperator({preventDefault(){}})'); assert.equal(calls, 0);
  assert.match(get('operator-form-error').textContent, /两次输入必须一致/);
});
