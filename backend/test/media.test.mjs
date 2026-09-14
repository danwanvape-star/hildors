import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, readdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createStore } from '../src/store.mjs';
import { app } from '../src/server.mjs';

test('real MP4 upload, authorization, validation, range and draft visibility', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'hildors-media-'));
  const store = createStore();
  const draft = store.create({ title: '素材测试', source: 'creator', format: 'single', tags: [], clips: [{ id: 'one', title: '待机', hardwareReady: false }] });
  const server = app(store, { adminToken: 'test', mediaDirectory: directory, uploadLimit: 20 * 1024 * 1024,
    inspector: async () => ({ status: 'failed', code: 'TOOLS_UNAVAILABLE' }) });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  const path = `/admin/packages/${draft.id}/clips/one/media`;
  const headers = { Authorization: 'Bearer test', 'Content-Type': 'video/mp4', 'If-Match': '1' };
  try {
    assert.equal((await fetch(base + path, { method: 'PUT', body: 'bad' })).status, 401);
    assert.equal((await fetch(base + path, { method: 'PUT', headers, body: 'not a video' })).status, 415);
    assert.deepEqual(await readdir(directory), []);
    const bytes = await readFile(new URL('../../assets/videos/showcase/showcase_02.mp4', import.meta.url));
    const result = await fetch(base + path, { method: 'PUT', headers, body: bytes });
    assert.equal(result.status, 200);
    const item = await result.json(); const media = item.clips[0].media;
    assert.equal(item.status, 'draft'); assert.equal(media.bytes, bytes.length);
    assert.equal(item.clips[0].hardwareReady, false);
    assert.equal((await fetch(base + '/admin/media/' + media.id)).status, 401);
    const response = await fetch(base + '/admin/media/' + media.id, { headers: { Authorization: 'Bearer test', Range: 'bytes=0-11' } });
    assert.equal(response.status, 206);
    assert.deepEqual(Buffer.from(await response.arrayBuffer()), bytes.subarray(0, 12));
    assert.equal((await fetch(base + '/v1/packages/' + draft.id)).status, 404);
    const inspectionPath = `/admin/packages/${draft.id}/clips/one/inspect`;
    assert.equal((await fetch(base + inspectionPath, { method: 'POST' })).status, 401);
    const inspectionResponse = await fetch(base + inspectionPath, { method: 'POST', headers });
    assert.equal(inspectionResponse.status, 200);
    const inspected = await inspectionResponse.json();
    assert.equal(inspected.clips[0].media.inspection.code, 'TOOLS_UNAVAILABLE');
    assert.equal((await fetch(base + '/admin/media/' + media.id + '/thumbnail', { headers })).status, 404);
    assert.equal((await fetch(base + path, { method: 'PUT', headers, body: bytes })).status, 409);
  } finally {
    await new Promise(resolve => server.close(resolve)); store.close();
    await rm(directory, { recursive: true });
  }
});
