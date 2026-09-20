import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createStore } from '../src/store.mjs';
import { app } from '../src/server.mjs';

async function fixture(t) {
  const directory = await mkdtemp(join(tmpdir(), 'content-workflow-'));
  const store = createStore();
  const server = app(store, { adminToken: 'admin', mediaDirectory: directory,
    inspector: async () => ({ status: 'checked', durationSeconds: 10 }) });
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  t.after(async () => { await new Promise(r => server.close(r)); store.close(); await rm(directory, { recursive: true }); });
  const call = async (path, value, token = 'admin', method) => {
    const response = await fetch(`http://127.0.0.1:${server.address().port}${path}`, {
      method: method ?? (value === undefined ? 'GET' : 'POST'),
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: value === undefined ? undefined : JSON.stringify(value) });
    return { status: response.status, data: await response.json() };
  };
  const creator = (name, approved = true) => {
    const user = store.createUser(); const profile = store.upsertCreatorProfile(user, { displayName: name, email: `${name}@example.com` });
    if (approved) store.reviewCreatorProfile(profile.id, profile.version, 'approved');
    return { user, token: store.createSession(user), profile };
  };
  return { store, call, creator, base: `http://127.0.0.1:${server.address().port}` };
}
const document = { title: 'New content', source: 'creator', description: 'A background story', format: 'single', tags: ['科幻未来'], clips: [{ id: 'main', title: 'Main' }] };

test('admin source is derived, story required, shared tags validated and disabled legacy tags retained', async t => {
  const { call } = await fixture(t);
  assert.equal((await call('/admin/packages', document)).data.source, 'hildors');
  assert.equal((await call('/admin/packages', { ...document, description: '' })).status, 400);
  const managed = await call('/admin/content-tags', { items: [{ name: 'Fantasy', active: true }] });
  assert.equal(managed.status, 200);
  const tag = managed.data.items.find(x => x.name === 'Fantasy');
  assert.ok(tag.id);
  assert.deepEqual((await call('/v1/content-tags')).data.items, managed.data.items);
  let item = (await call('/admin/packages', { ...document, tags: ['Fantasy'] })).data;
  assert.equal((await call('/admin/packages', { ...document, tags: ['Unknown'] })).status, 400);
  await call('/admin/content-tags', { items: [{ ...tag, active: false }] });
  assert.equal((await call('/admin/packages', { ...document, tags: ['Fantasy'] })).status, 400);
  item = (await call(`/admin/packages/${item.id}/metadata`, { version: item.version, title: 'Renamed', tags: item.tags, description: item.description })).data;
  assert.deepEqual(item.tags, ['Fantasy']);
  assert.equal(item.source, 'hildors');
  assert.equal((await call(`/admin/packages/${item.id}/metadata`, {version:item.version,title:item.title,tags:item.tags,description:'   '})).status, 400);
});

test('creator ownership, uploads, rejection, resubmission, approval and separate publication', async t => {
  const { call, creator, base } = await fixture(t);
  const alice = creator('alice'), bob = creator('bob'), pending = creator('pending', false);
  assert.equal((await call('/v1/me/content', undefined, '')).status, 401);
  assert.equal((await call('/v1/me/content', undefined, pending.token)).status, 403);
  let result = await call('/v1/me/content', { ...document, source: 'hildors', ownerId: bob.user }, alice.token);
  assert.equal(result.status, 201);
  let item = result.data; const path = `/v1/me/content/${item.id}`;
  assert.equal(item.ownerId, alice.user); assert.equal(item.source, 'creator'); assert.equal(item.submissionStatus, 'draft');
  assert.equal(item.creator.name, 'alice');
  assert.equal((await call(path, undefined, bob.token)).status, 404);
  assert.deepEqual((await call('/v1/me/content', undefined, bob.token)).data.items, []);
  assert.equal((await call(path + '/metadata', { ...document, version: item.version }, bob.token)).status, 404);
  assert.equal((await call(path + '/submit', { version: item.version }, alice.token)).status, 409);
  const video = await readFile(new URL('../../assets/videos/showcase/showcase_02.mp4', import.meta.url));
  const upload = async token => fetch(base + path + '/clips/main/media', { method: 'PUT', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'video/mp4', 'If-Match': String(item.version) }, body: video });
  assert.equal((await upload(bob.token)).status, 404);
  const uploaded = await upload(alice.token); assert.equal(uploaded.status, 200); item = await uploaded.json();
  assert.equal((await call(path + '/metadata', { ...document, version: 1 }, alice.token)).status, 409);
  item = (await call(path + '/clips/main/inspect', { version: item.version }, alice.token)).data;
  item = (await call(path + '/submit', { version: item.version }, alice.token)).data;
  assert.equal(item.submissionStatus, 'pending');
  assert.equal((await call(path + '/metadata', { ...document, version: item.version }, alice.token)).status, 409);
  assert.equal((await upload(alice.token)).status, 409);
  item = (await call(`/admin/packages/${item.id}/review`, { version: item.version, decision: 'rejected', note: 'Revise story' })).data;
  assert.equal(item.submissionStatus, 'rejected');
  item = (await call(path + '/metadata', { ...document, version: item.version, description: 'Revised story' }, alice.token)).data;
  item = (await call(path + '/submit', { version: item.version }, alice.token)).data;
  item = (await call(`/admin/packages/${item.id}/review`, { version: item.version, decision: 'approved', note: 'Approved', rightsConfirmed: true, rightsReference: 'License' })).data;
  assert.equal(item.submissionStatus, 'approved'); assert.equal(item.status, 'draft');
  assert.equal((await call(`/v1/packages/${item.id}`)).status, 404);
  assert.equal((await call(path + '/metadata', { ...document, version: item.version }, alice.token)).status, 409);
  item = (await call(`/admin/packages/${item.id}/publish`, { version: item.version })).data;
  const publicItem = (await call(`/v1/packages/${item.id}`)).data;
  assert.equal(publicItem.description, 'Revised story'); assert.equal(publicItem.creator.name, 'alice');
  for (const key of ['ownerId','review','submissionStatus']) assert.equal(key in publicItem, false);
});

test('tags persist with stable ids and cannot be deleted by omission', async t => {
  const dir = await mkdtemp(join(tmpdir(), 'content-tags-')); let store = createStore(join(dir, 'db.sqlite'));
  t.after(async () => { store.close(); await rm(dir, { recursive: true }); });
  const tag = store.saveContentTags([{ name: 'Persisted', active: true }]).find(x => x.name === 'Persisted');
  store.saveContentTags([]); store.close(); store = createStore(join(dir, 'db.sqlite'));
  assert.deepEqual(store.contentTags().find(x => x.id === tag.id), { ...tag, active: false });
});

test('metadata invalidates draft approval, legacy backfill and anonymous creator projection are safe', async t => {
  const { call, store } = await fixture(t);
  let item = store.create({ ...document, creator: { id: 'private-id', name: 'Secret', email: 'secret@example.com', anonymous: true } });
  item = store.attachMedia(item.id, 'main', item.version, { id: 'media', inspection: { status: 'checked' } });
  item = store.review(item.id, item.version, 'approved', 'ok', 'license');
  item = (await call(`/admin/packages/${item.id}/metadata`, { ...document, version: item.version, description: 'Edited' })).data;
  assert.equal(item.review, undefined);
  assert.equal((await call(`/admin/packages/${item.id}/publish`, { version: item.version })).status, 409);
  item = store.review(item.id, item.version, 'approved', 'ok', 'license');
  item = store.transition(item.id, item.version, 'published');
  item = (await call(`/admin/packages/${item.id}/metadata`, { ...document, version: item.version, description: 'Backfilled' })).data;
  assert.equal(item.status, 'published');
  const publicItem = (await call(`/v1/packages/${item.id}`)).data;
  assert.equal(publicItem.description, 'Backfilled');
  assert.deepEqual(publicItem.creator, { name: '匿名创作者', anonymous: true });
});

test('creator package cover upload, inspection versions and management permissions', async t => {
  const { call, store, creator, base } = await fixture(t);
  const alice = creator('coverowner'), bob = creator('coverother');
  let item = (await call('/v1/me/content', { ...document, format: 'package' }, alice.token)).data;
  const path = `/v1/me/content/${item.id}`;
  item = store.attachMedia(item.id, 'main', item.version, { id: 'media', inspection: { status: 'checked' } });
  assert.equal((await call(path + '/submit', { version: item.version }, alice.token)).data.code, 'PACKAGE_COVER_REQUIRED');
  assert.equal((await call(path + '/clips/main/inspect', { version: 1 }, alice.token)).status, 409);
  const bytes = await readFile(new URL('../../assets/images/video_thumbnails/showcase_02.jpg', import.meta.url));
  const cover = async token => fetch(base + path + '/cover', { method: 'PUT', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'image/jpeg', 'If-Match': String(item.version) }, body: bytes });
  assert.equal((await cover(bob.token)).status, 404);
  const response = await cover(alice.token); assert.equal(response.status, 200); item = await response.json();
  assert.equal((await fetch(base + path + '/cover', { headers: { Authorization: `Bearer ${bob.token}` } })).status, 404);
  assert.equal((await fetch(base + path + '/cover', { headers: { Authorization: `Bearer ${alice.token}` } })).status, 200);
  assert.equal((await call(`/v1/covers/${item.cover.id}`)).status, 404);
  item = (await call(path + '/submit', { version: item.version }, alice.token)).data;
  assert.equal(item.submissionStatus, 'pending');
  assert.equal((await call(`/admin/packages/${item.id}/metadata`, { ...document, version: item.version })).status, 409);
  assert.throws(() => store.attachCover(item.id, item.version, item.cover), /CONFLICT/);
  let profile = store.getCreatorProfile(alice.user);
  store.manageCreatorProfile(profile.id, profile.version, { status: 'approved', canPublish: false });
  assert.equal((await call('/v1/me/content', undefined, alice.token)).status, 200);
  profile = store.getCreatorProfile(alice.user);
  store.manageCreatorProfile(profile.id, profile.version, { status: 'suspended', note: '暂停投稿资格' });
  assert.equal((await call('/v1/me/content', undefined, alice.token)).status, 403);
});

test('tag names cannot collide across stable ids and rename retains legacy name', async t => {
  const { call } = await fixture(t);
  const tags = (await call('/admin/content-tags', { items: [{ name: 'First', active: true }, { name: 'Second', active: true }] })).data.items;
  assert.equal((await call('/admin/content-tags', { items: [{ ...tags[0], name: 'Second' }] })).status, 400);
  const result = await call('/admin/content-tags', { items: [{ ...tags[0], name: 'Renamed' }, tags[1]] });
  assert.equal(result.status, 200);
  assert.ok(result.data.items.some(x => x.name === 'First' && !x.active));
  assert.ok(result.data.items.some(x => x.name === 'Renamed' && x.id === tags[0].id));
});
