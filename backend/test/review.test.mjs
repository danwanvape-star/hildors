import test from 'node:test';
import assert from 'node:assert/strict';
import { createStore } from '../src/store.mjs';
import { app } from '../src/server.mjs';

test('recheck immediately invalidates approval and stale results cannot approve replacement', async () => {
  const store = createStore();
  let notifyStarted, finish;
  const started = new Promise(resolve => { notifyStarted = resolve; });
  const server = app(store, { adminToken: 'test', inspector: () => {
    notifyStarted(); return new Promise(resolve => { finish = resolve; });
  } });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  const headers = { Authorization: 'Bearer test' };
  try {
    const p = store.create({ title: 'recheck', clips: [{ id: 'c' }] });
    store.attachMedia(p.id, 'c', 1, { id: 'old-media' });
    store.setInspection(p.id, 'c', 'old-media', { status: 'checked' });
    store.review(p.id, 3, 'approved', 'test', 'test-only');
    const endpoint = base + `/admin/packages/${p.id}/clips/c/inspect`;
    const pending = fetch(endpoint, { method: 'POST', headers });
    await started;
    const checking = store.get(p.id);
    assert.equal(checking.review, undefined);
    assert.equal(checking.clips[0].media.inspection.status, 'processing');
    const published = await fetch(base + `/admin/packages/${p.id}/publish`, { method: 'POST', headers, body: JSON.stringify({ version: checking.version }) });
    assert.equal(published.status, 409);
    const duplicate = await fetch(endpoint, { method: 'POST', headers });
    assert.equal((await duplicate.json()).code, 'PROCESSOR_BUSY');
    store.attachMedia(p.id, 'c', checking.version, { id: 'replacement' });
    finish({ status: 'checked' });
    assert.equal((await pending).status, 409);
    assert.equal(store.get(p.id).clips[0].media.inspection, undefined);
  } finally {
    finish?.({ status: 'failed' });
    await new Promise(resolve => server.close(resolve)); store.close();
  }
});

test('review requires checked media, explicit rights reference, version; public response excludes private review', async () => {
  const store = createStore();
  const server = app(store, { adminToken: 'test' });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  async function post(path, body) {
    const res = await fetch(base + path, { method: 'POST', headers: { Authorization: 'Bearer test' }, body: JSON.stringify(body) });
    return { status: res.status, data: await res.json() };
  }
  try {
    const p = store.create({ title: '测试包', format: 'single', source: 'creator', tags: [], clips: [{ id: 'c', title: '待机' }] });
    const url = `/admin/packages/${p.id}`;
    const approval = { version: 1, decision: 'approved', note: '已核对', rightsReference: 'private-record-001', rightsConfirmed: true };
    assert.equal((await post(url + '/review', { ...approval, rightsConfirmed: false })).status, 400);
    assert.equal((await post(url + '/review', approval)).data.code, 'MEDIA_REVIEW_REQUIRED');
    store.attachMedia(p.id, 'c', 1, { id: 'media-first' });
    store.setInspection(p.id, 'c', 'media-first', { status: 'checked', durationSeconds: 10 });
    assert.equal((await post(url + '/review', approval)).status, 409);
    let approved = await post(url + '/review', { ...approval, version: 3 });
    assert.equal(approved.status, 200);
    store.attachMedia(p.id, 'c', approved.data.version, { id: 'media-replaced' });
    assert.equal(store.get(p.id).review, undefined);
    assert.equal((await post(url + '/publish', { version: 5 })).status, 409);
    store.setInspection(p.id, 'c', 'media-replaced', { status: 'checked', durationSeconds: 12 });
    approved = await post(url + '/review', { ...approval, version: 6 });
    assert.equal((await post(url + '/publish', { version: approved.data.version })).status, 200);
    const publicItem = await (await fetch(base + '/v1/packages/' + p.id)).json();
    assert.equal(publicItem.review, undefined);
    assert.equal(publicItem.clips[0].media, undefined);
    assert.equal(publicItem.clips[0].hardwareReady, false);
    assert.equal(publicItem.clips[0].durationSeconds, 12);
    assert.equal((await fetch(base + '/admin/audit')).status, 401);
    const audit = await (await fetch(base + '/admin/audit', { headers: { Authorization: 'Bearer test' } })).json();
    assert.ok(audit.items.some(e => e.action === 'review_approved'));
    assert.ok(audit.items.some(e => e.action === 'published'));
  } finally { await new Promise(resolve => server.close(resolve)); store.close(); }
});
