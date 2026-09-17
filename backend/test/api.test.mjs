import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createStore, seedDemos } from '../src/store.mjs';
import { app } from '../src/server.mjs';

test('catalog, access control, draft gating and withdrawal', async t => {
  const store = createStore(); seedDemos(store); seedDemos(store);
  const server = app(store, { adminToken: 'test-only-token', adminUsername: 'admin', adminPassword: 'strong-test-password' });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(async () => { await new Promise(resolve => server.close(resolve)); store.close(); });
  const base = `http://127.0.0.1:${server.address().port}`;
  const consolePage = await fetch(base + '/console');
  assert.equal(consolePage.status, 200);
  assert.match(consolePage.headers.get('content-security-policy'), /frame-ancestors 'none'/);
  const consoleHtml = await consolePage.text();
  assert.match(consoleHtml, /内容管理/);
  assert.match(consoleHtml, /管理员登录/);
  const consoleScript = await fetch(base + '/console/app.js');
  assert.equal(consoleScript.status, 200);
  const scriptText = await consoleScript.text();
  assert.match(scriptText, /admin\/login/);
  assert.match(scriptText, /发布到 App/);
  assert.equal((await fetch(base + '/console/style.css')).status, 200);
  assert.equal((await fetch(base + '/console/connection.css')).status, 200);
  assert.equal((await fetch(base + '/console/secret.env')).status, 404);
  const call = async (path, body, authorized = true) => {
    const res = await fetch(base + path, { method: body === undefined ? 'GET' : 'POST',
      headers: authorized ? { Authorization: 'Bearer test-only-token' } : {},
      body: body === undefined ? undefined : JSON.stringify(body) });
    return { status: res.status, data: await res.json() };
  };
  assert.equal((await call('/admin/packages', undefined, false)).status, 401);
  const badLogin = await fetch(base + '/admin/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ username: 'admin', password: 'wrong' }) });
  assert.equal(badLogin.status, 401);
  const login = await fetch(base + '/admin/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ username: 'admin', password: 'strong-test-password' }) });
  assert.equal(login.status, 200); const cookie = login.headers.get('set-cookie').split(';')[0];
  assert.equal((await fetch(base + '/admin/packages', { headers: { Cookie: cookie } })).status, 200);
  const first = await call('/v1/catalog?limit=2');
  assert.equal(first.data.items.length, 2);
  assert.equal((await call('/v1/catalog?limit=2&cursor=' + first.data.nextCursor)).data.items.length, 2);
  assert.equal((await call('/v1/catalog?limit=-1')).status, 400);
  assert.equal((await call('/v1/catalog?tag=' + encodeURIComponent('音乐'))).data.items.length, 2);
  for (const p of (await call('/v1/catalog')).data.items) {
    assert.equal(p.clips[0].hardwareReady, false);
    assert.ok(existsSync(new URL('../../' + p.clips[0].bundledAsset, import.meta.url)));
  }
  await call('/admin/content-tags', { items: [{ name: '神话', active: true }] });
  const draft = await call('/admin/packages', { title: '测试角色包', description: '角色的背景故事', source: 'creator', format: 'package', tags: ['神话'], clips: [{ id: 'clip-1', title: '待机' }], demo: true });
  assert.equal(draft.status, 201);
  assert.equal(draft.data.demo, false);
  assert.equal((await call('/v1/packages/' + draft.data.id)).status, 404);
  assert.equal((await call('/admin/packages/' + draft.data.id + '/publish', { version: 1 })).data.code, 'MEDIA_REVIEW_REQUIRED');
  assert.equal((await call('/admin/packages', { title: 'bad' })).status, 400);
  assert.equal((await call('/admin/packages/hildors_demo_01/withdraw', { version: 1 })).status, 409);
  assert.equal((await call('/admin/packages/hildors_demo_01/withdraw', { version: 2 })).status, 200);
  assert.equal((await call('/v1/packages/hildors_demo_01')).status, 404);
  assert.equal((await call('/v1/catalog')).data.items.length, 3);
});

test('catalog persists across restarts without resurrecting withdrawn demos', () => {
  const directory = mkdtempSync(join(tmpdir(), 'hildors-api-'));
  let store;
  try {
    store = createStore(join(directory, 'test.sqlite')); seedDemos(store);
    store.transition('hildors_demo_01', 2, 'withdrawn'); store.close(); store = undefined;
    store = createStore(join(directory, 'test.sqlite')); seedDemos(store);
    assert.equal(store.get('hildors_demo_01').status, 'withdrawn');
    assert.equal(store.list().length, 4);
  } finally { store?.close(); rmSync(directory, { recursive: true }); }
});
