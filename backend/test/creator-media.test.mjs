import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, copyFile, readFile, stat, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { randomUUID } from 'node:crypto';
import { watch } from 'node:fs';
import { createStore } from '../src/store.mjs';
import { app } from '../src/server.mjs';

async function fixture(t) {
  const directory = await mkdtemp(join(tmpdir(), 'creator-media-'));
  const store = createStore();
  function creator() {
    const user = store.createUser(), token = store.createSession(user);
    const profile = store.upsertCreatorProfile(user, { email: `${user}@example.test`, displayName: 'Creator' });
    store.manageCreatorProfile(profile.id, profile.version, { status: 'approved', tier: 'partner' });
    return { user, token };
  }
  const owner = creator(), other = creator(), mediaId = randomUUID();
  await copyFile(new URL('../../assets/videos/showcase/showcase_02.mp4', import.meta.url), join(directory, `${mediaId}.mp4`));
  let item = store.create({ title: 'Private paid draft', source: 'creator', ownerId: owner.user, submissionStatus: 'draft',
    format: 'single', clips: [{ id: 'one', title: 'Clip', pricing: { mode: 'paid', currency: 'USD', amountMinor: 199 } }] });
  item = store.attachMedia(item.id, 'one', item.version, { id: mediaId });
  const server = app(store, { mediaDirectory: directory });
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  t.after(async () => { await new Promise(r => server.close(r)); store.close(); await rm(directory, { recursive: true, force: true }); });
  const path = `/v1/me/content/${item.id}/clips/one`;
  const request = (url, token = owner.token, options = {}) => fetch(`http://127.0.0.1:${server.address().port}${url}`, {
    ...options, headers: { Authorization: `Bearer ${token}`, ...options.headers },
  });
  return { directory, store, server, owner, other, mediaId, item, path, request };
}

test('creator inspection prepares private thumbnail and faststart preview before first playback', async t => {
  const f = await fixture(t);
  const inspected = await f.request(`${f.path}/inspect`, f.owner.token, { method: 'POST',
    headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ version: f.item.version }) });
  assert.equal(inspected.status, 200);
  assert.equal((await inspected.json()).clips[0].media.inspection.status, 'checked');
  const derivative = join(f.directory, 'video-previews-v1', `${f.mediaId}.mp4`);
  const before = await stat(derivative), bytes = await readFile(derivative);
  assert.ok(bytes.indexOf(Buffer.from('moov')) < bytes.indexOf(Buffer.from('mdat')));
  assert.ok(bytes.length < (await stat(join(f.directory, `${f.mediaId}.mp4`))).size);
  const thumbnail = await f.request(`${f.path}/thumbnail`);
  assert.equal(thumbnail.status, 200);
  assert.equal(thumbnail.headers.get('content-type'), 'image/jpeg');
  assert.match(thumbnail.headers.get('cache-control'), /private/);
  assert.deepEqual(Buffer.from(await thumbnail.arrayBuffer()), await readFile(join(f.directory, `${f.mediaId}.jpg`)));
  const thumbnailTag = thumbnail.headers.get('etag'); assert.ok(thumbnailTag);
  assert.equal((await f.request(`${f.path}/thumbnail`, f.owner.token, { headers: { 'If-None-Match': thumbnailTag } })).status, 304);
  const preview = await f.request(`${f.path}/preview`, f.owner.token, { headers: { Range: 'bytes=0-63' } });
  assert.equal(preview.status, 206);
  assert.equal(preview.headers.get('content-range'), `bytes 0-63/${bytes.length}`);
  assert.match(preview.headers.get('cache-control'), /private/);
  assert.deepEqual(Buffer.from(await preview.arrayBuffer()), bytes.subarray(0, 64));
  const etag = preview.headers.get('etag'); assert.ok(etag);
  assert.equal((await f.request(`${f.path}/preview`, f.owner.token, { headers: { 'If-None-Match': etag } })).status, 304);
  assert.equal((await f.request(`${f.path}/preview`, f.owner.token, { headers: { Range: 'bytes=999999999-' } })).status, 416);
  assert.equal((await stat(derivative)).mtimeMs, before.mtimeMs);
  for (const suffix of ['thumbnail', 'preview']) {
    assert.equal((await f.request(`${f.path}/${suffix}`, f.other.token)).status, 404);
    assert.equal((await f.request(`${f.path}/${suffix}`, '')).status, 401);
    assert.equal((await f.request(`/v1/media/${f.mediaId}/${suffix}`)).status, 404);
  }
  f.store.revokeSession(f.owner.token);
  for (const [suffix, tag] of [['thumbnail', thumbnailTag], ['preview', etag]]) {
    assert.equal((await f.request(`${f.path}/${suffix}`, f.owner.token, { headers: { 'If-None-Match': tag } })).status, 401);
  }
});

test('missing clip media and unchecked thumbnails return 404', async t => {
  const f = await fixture(t);
  assert.equal((await f.request(`${f.path}/thumbnail`)).status, 404);
  assert.equal((await f.request(f.path.replace('/one', '/missing') + '/preview')).status, 404);
});

test('sign-out while first preview is being generated prevents video and conditional responses', async t => {
  const f = await fixture(t);
  // Revoke after probing, when generation creates its output directory.
  const watcher = watch(f.directory, (_event, name) => {
    if (name === 'video-previews-v1') { watcher.close(); f.store.revokeSession(f.owner.token); }
  });
  t.after(() => watcher.close());
  const response = await f.request(`${f.path}/preview`, f.owner.token, {
    headers: { 'If-None-Match': `"video-${f.mediaId}-preview-v1"` },
  });
  assert.equal(response.status, 401);
  assert.equal((await response.json()).code, 'USER_AUTH_REQUIRED');
  assert.ok((await stat(join(f.directory, 'video-previews-v1', `${f.mediaId}.mp4`))).size > 24);
});
