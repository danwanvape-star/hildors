import test from 'node:test';
import assert from 'node:assert/strict';
import { createStore } from '../src/store.mjs';
import { app } from '../src/server.mjs';

async function start(t) {
  const store = createStore();
  const server = app(store, { adminToken: 'test-token' });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(async () => { await new Promise(resolve => server.close(resolve)); store.close(); });
  const base = `http://127.0.0.1:${server.address().port}`;
  const request = async (path, body) => {
    const response = await fetch(base + path, { method: body === undefined ? 'GET' : 'POST',
      headers: { Authorization: 'Bearer test-token', 'Content-Type': 'application/json' },
      body: body === undefined ? undefined : JSON.stringify(body) });
    return { status: response.status, data: await response.json() };
  };
  return { store, request };
}

const draft = (overrides = {}) => ({ title: '云端舞者', source: 'creator', format: 'single', tags: ['舞蹈'],
  clips: [{ id: 'main', title: '展示视频' }], ...overrides });

test('package create and metadata update persist normalized attribution with version checks', async t => {
  const { store, request } = await start(t);
  const created = await request('/admin/packages', draft({ description: '  一段公开介绍。  ',
    creator: { id: 'creator-42', name: '  林岚  ', anonymous: false } }));
  assert.equal(created.status, 201);
  assert.equal(created.data.description, '一段公开介绍。');
  assert.deepEqual(created.data.creator, { id: 'creator-42', name: '林岚', anonymous: false });
  assert.deepEqual(store.get(created.data.id).creator, { id: 'creator-42', name: '林岚', anonymous: false });
  const updated = await request(`/admin/packages/${created.data.id}/metadata`, { version: created.data.version,
    description: '更新后的介绍', creator: { id: 'creator-99', name: '新作者', anonymous: false } });
  assert.equal(updated.status, 200);
  assert.equal(updated.data.version, 2);
  assert.equal(updated.data.description, '更新后的介绍');
  assert.deepEqual(updated.data.creator, { id: 'creator-99', name: '新作者', anonymous: false });
  assert.equal(updated.data.clips[0].title, '展示视频');
  const stale = await request(`/admin/packages/${created.data.id}/metadata`, { version: created.data.version,
    description: '不应覆盖', creator: { anonymous: true } });
  assert.equal(stale.status, 409);
  assert.equal(stale.data.code, 'VERSION_OR_STATE_CONFLICT');
  assert.equal(store.get(created.data.id).description, '更新后的介绍');
});

test('package metadata validates identified creators while hildors ignores attribution', async t => {
  const { request } = await start(t);
  assert.equal((await request('/admin/packages', draft({ description: 'x'.repeat(2001) }))).status, 400);
  assert.equal((await request('/admin/packages', draft({ description: null }))).status, 400);
  assert.equal((await request('/admin/packages', draft({ creator: { id: 'display name', name: '作者', anonymous: false } }))).status, 400);
  assert.equal((await request('/admin/packages', draft({ creator: { id: 'creator-1', name: '', anonymous: false } }))).status, 400);
  assert.equal((await request('/admin/packages', draft({ creator: { id: 'creator-1', name: '作者', anonymous: 'false' } }))).status, 400);
  const legacy = await request('/admin/packages', draft({ description: '' }));
  assert.equal(legacy.status, 201);
  assert.equal(legacy.data.description, undefined);
  assert.equal(legacy.data.creator, undefined);
  const hildors = await request('/admin/packages', draft({ source: 'hildors',
    creator: { id: '<private>', name: '<script>alert(1)</script>', anonymous: 'invalid' } }));
  assert.equal(hildors.status, 201);
  assert.equal(hildors.data.creator, undefined);
  const invalidUpdate = await request(`/admin/packages/${legacy.data.id}/metadata`, { version: legacy.data.version,
    description: 'x'.repeat(2001), creator: { anonymous: true } });
  assert.equal(invalidUpdate.status, 400);
  assert.equal(invalidUpdate.data.code, 'INVALID_PACKAGE_METADATA');
});

test('public packages expose descriptions and safe creator attribution with legacy fallback', async t => {
  const { store, request } = await start(t);
  const publishDemo = (id, document) => {
    store.create({ title: id, source: 'creator', format: 'single', tags: [], demo: true,
      clips: [{ id: 'main', title: '展示', hardwareReady: false }], ...document }, id);
    store.transition(id, 1, 'published');
  };
  publishDemo('identified', { description: '作者公开介绍',
    creator: { id: 'stable-creator-id', name: '公开作者', anonymous: false } });
  publishDemo('anonymous', { creator: { id: 'private-creator-id', name: '不应公开的名字', anonymous: true } });
  publishDemo('legacy', {});
  store.create({ title: 'hildors', source: 'hildors', format: 'single', tags: [], demo: true,
    creator: { id: 'internal-id', name: '<script>alert(1)</script>', anonymous: false },
    clips: [{ id: 'main', title: '展示', hardwareReady: false }] }, 'hildors');
  store.transition('hildors', 1, 'published');
  const catalog = await request('/v1/catalog');
  const items = Object.fromEntries(catalog.data.items.map(item => [item.id, item]));
  assert.equal(items.identified.description, '作者公开介绍');
  assert.deepEqual(items.identified.creator, { id: 'stable-creator-id', name: '公开作者', anonymous: false });
  assert.deepEqual(items.anonymous.creator, { anonymous: true });
  assert.equal(JSON.stringify(items.anonymous).includes('private-creator-id'), false);
  assert.equal(JSON.stringify(items.anonymous).includes('不应公开的名字'), false);
  assert.deepEqual(items.legacy.creator, { anonymous: true });
  assert.equal(items.legacy.description, undefined);
  assert.equal(items.hildors.creator, undefined);
  assert.equal(JSON.stringify(items.hildors).includes('internal-id'), false);
  assert.equal(JSON.stringify(items.hildors).includes('<script>'), false);
  const detail = await request('/v1/packages/identified');
  assert.equal(detail.data.description, '作者公开介绍');
  assert.deepEqual(detail.data.creator, { id: 'stable-creator-id', name: '公开作者', anonymous: false });
});
