import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createHash, randomUUID } from 'node:crypto';
import { createStore } from '../src/store.mjs';
import { app } from '../src/server.mjs';

test('delivery is opt-in, authenticated, entitlement-gated and range-capable', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'hildors-delivery-'));
  const store = createStore();
  const owner = store.createUser(), stranger = store.createUser();
  const token = store.createSession(owner), other = store.createSession(stranger);
  const bytes = Buffer.from('deterministic-delivery-test-fixture');
  const id = randomUUID(), sha256 = createHash('sha256').update(bytes).digest('hex');
  await writeFile(join(directory, `${id}.mp4`), bytes);
  const item = store.create({ title: 'test', source: 'hildors', format: 'single', tags: [], clips: [{ id: 'clip' }] });
  store.attachMedia(item.id, 'clip', 1, { id, bytes: bytes.length, sha256 });
  store.setInspection(item.id, 'clip', id, { status: 'checked' });
  store.review(item.id, 3, 'approved', 'test fixture only', 'test reference');
  store.transition(item.id, 4, 'published');
  store.setEntitlement(owner, item.id, 'active', 'test grant');
  const server = app(store, { mediaDirectory: directory, enableDownloads: true });
  const disabled = app(store, { mediaDirectory: directory });
  await Promise.all([server, disabled].map(s => new Promise(r => s.listen(0, '127.0.0.1', r))));
  const path = `/v1/me/packages/${item.id}/clips/clip/`;
  const request = (suffix, bearer = token, headers = {}, target = server) => fetch(`http://127.0.0.1:${target.address().port}${path}${suffix}`, {
    headers: { ...(bearer ? { Authorization: `Bearer ${bearer}` } : {}), ...headers },
  });
  try {
    assert.equal((await request('manifest', token, {}, disabled)).status, 503);
    assert.equal((await request('download', null)).status, 401);
    assert.equal((await request('download', other)).status, 404);
    const manifest = await (await request('manifest')).json();
    assert.equal(manifest.sha256, sha256); assert.equal(manifest.hardwareReady, false);
    assert.equal(manifest.authorizationRequired, true); assert.equal(manifest.id, undefined);
    assert.deepEqual(Buffer.from(await (await request('download')).arrayBuffer()), bytes);
    const partial = await request('download', token, { Range: 'bytes=2-5' });
    assert.equal(partial.status, 206); assert.deepEqual(Buffer.from(await partial.arrayBuffer()), bytes.subarray(2, 6));
    assert.equal((await request('download', token, { Range: 'bytes=999-' })).status, 416);
    store.setEntitlement(owner, item.id, 'revoked', 'test revoke');
    assert.equal((await request('download')).status, 404);
    store.setEntitlement(owner, item.id, 'active', 'test restore');
    await writeFile(join(directory, `${id}.mp4`), 'short');
    assert.equal((await request('manifest')).status, 409);
    await writeFile(join(directory, `${id}.mp4`), bytes);
    store.transition(item.id, 5, 'withdrawn');
    assert.equal((await request('download')).status, 404);
    store.revokeSession(token);
    assert.equal((await request('manifest')).status, 401);
  } finally {
    await Promise.all([server, disabled].map(s => new Promise(r => s.close(r))));
    store.close(); await rm(directory, { recursive: true, force: true });
  }
});
