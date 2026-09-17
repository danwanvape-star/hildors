import test from 'node:test';
import assert from 'node:assert/strict';
import { createStore } from '../src/store.mjs';
import { app } from '../src/server.mjs';

async function fixture(t) {
  const store = createStore();
  const server = app(store, { adminToken: 'creator-admin-test' });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(async () => { await new Promise(resolve => server.close(resolve)); store.close(); });
  const userId = store.createUser(), token = store.createSession(userId);
  const profile = { displayName: '青岚', email: 'qing@example.test', portfolioUrl: 'https://example.test/art',
    skillTags: ['3D'], marketRegion: 'CN', agreementVersion: 'v1' };
  const creator = store.upsertCreatorProfile(userId, profile);
  const request = async (path, body, auth = 'creator-admin-test') => {
    const response = await fetch(`http://127.0.0.1:${server.address().port}${path}`, {
      method: body === undefined ? 'GET' : 'POST', headers: { Authorization: `Bearer ${auth}`, 'Content-Type': 'application/json' },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    return { status: response.status, data: await response.json() };
  };
  return { store, request, creator, userId, token, profile };
}

test('creator list searches name and email, filters tier and paginates summaries', async t => {
  const { store, request, creator } = await fixture(t);
  store.manageCreatorProfile(creator.id, creator.version, { status: 'approved', tier: 'partner', note: '资质通过' });
  for (let i = 0; i < 23; i++) store.upsertCreatorProfile(store.createUser(), { displayName: `作者${i}`, email: `artist${i}@example.test` });
  const r = await request('/admin/creators?page=2&pageSize=10&status=pending');
  assert.equal(r.status, 200); assert.equal(r.data.items.length, 10); assert.equal(r.data.total, 23);
  assert.equal(r.data.page, 2); assert.equal(r.data.summary.total, 24); assert.equal(r.data.summary.approved, 1);
  assert.equal(r.data.items[0].managementHistory, undefined);
  assert.equal((await request('/admin/creators?q=QING&status=approved&tier=partner&page=1')).data.items[0].id, creator.id);
  assert.equal((await request('/admin/creators?q=青岚&page=1')).data.total, 1);
  assert.equal((await request('/admin/creators?q=missing&page=99')).data.total, 0);
  assert.equal((await request('/admin/creators?page=1&pageSize=-5')).status, 400);
});

test('creator detail returns only related works and requires admin authentication', async t => {
  const { store, request, creator, userId, token } = await fixture(t);
  const own = store.create({ title: '青岚角色', source: 'creator', ownerId: userId, format: 'single', tags: [], clips: [], submissionStatus: 'pending' });
  const attributed = store.create({ title: '历史作品', source: 'creator', creator: { id: creator.id }, format: 'single', tags: [], clips: [] });
  store.create({ title: '其他作品', source: 'creator', ownerId: store.createUser(), format: 'single', tags: [], clips: [] });
  const r = await request(`/admin/creators/${creator.id}`);
  assert.equal(r.status, 200); assert.equal(r.data.creator.email, 'qing@example.test');
  assert.deepEqual(new Set(r.data.works.map(x => x.id)), new Set([own.id, attributed.id]));
  assert.equal(r.data.works.find(x => x.id === own.id).submissionStatus, 'pending');
  assert.equal((await request(`/admin/creators/${creator.id}`, undefined, token)).status, 401);
  assert.equal((await request('/admin/creators/missing')).status, 404);
});

test('review requires reason, validates fields and keeps previous settings when omitted', async t => {
  const { request, creator } = await fixture(t);
  const path = `/admin/creators/${creator.id}`;
  assert.equal((await request(path, { version: 1, status: 'rejected', note: '  ' })).status, 400);
  assert.equal((await request(path, { version: 1, status: 'approved', note: '通过', tier: 'invalid' })).status, 400);
  assert.equal((await request(path, { version: 1, status: 'approved', note: '通过', canPublish: 'true' })).status, 400);
  assert.equal((await request(path, { version: 1, status: 'approved', note: '通过', commissionRate: 'bad' })).status, 400);
  let r = await request(path, { version: 1, status: 'approved', note: '核验通过', tier: 'partner', commissionRate: 15, manager: '运营甲', canPublish: true, canReceiveOrders: true });
  assert.equal(r.status, 200);
  r = await request(path, { version: r.data.version, status: 'suspended', note: '暂停合作' });
  assert.equal(r.status, 200); assert.equal(r.data.management.tier, 'partner'); assert.equal(r.data.management.commissionRate, 15);
  assert.equal(r.data.management.canPublish, true);
  assert.equal(r.data.managementHistory.length, 2);
  assert.equal(r.data.managementHistory[1].previousStatus, 'approved');
  assert.equal(r.data.managementHistory[1].actor, 'admin-token');
  assert.equal(r.data.managementHistory[0].changes.canPublish.to, true);
  assert.equal((await request(path, { version: 1, status: 'approved', note: '过期操作' })).status, 409);
  assert.equal((await request('/admin/creators/missing', { version: 1, status: 'approved', note: '通过' })).status, 404);
});

test('approval does not implicitly grant posting permission', async t => {
  const { request, creator, token } = await fixture(t);
  const result = await request(`/admin/creators/${creator.id}`, { version: 1, status: 'approved', note: '仅通过资质' });
  assert.equal(result.status, 200);
  assert.equal(result.data.management.canPublish, false);
  assert.equal((await request('/v1/me/content', undefined, token)).status, 403);
});

test('suspension blocks content and tasks, restoration keeps permissions, resubmission preserves audit', async t => {
  const { store, request, creator, token, profile } = await fixture(t);
  const path = `/admin/creators/${creator.id}`;
  let r = await request(path, { version: 1, status: 'approved', note: '核验通过', canPublish: true, canReceiveOrders: true, manager: '运营甲' });
  assert.equal((await request('/v1/me/content', undefined, token)).status, 200);
  r = await request(path, { version: r.data.version, status: 'suspended', note: '暂停合作' });
  assert.equal((await request('/v1/me/content', undefined, token)).status, 403);
  assert.equal((await request('/v1/me/creator-tasks', undefined, token)).data.code, 'ORDER_CREATOR_INELIGIBLE');
  let submission = await request('/v1/me/creator-profile', { ...profile, displayName: '青岚新名' }, token);
  assert.equal(submission.status, 200); assert.equal(submission.data.status, 'suspended');
  assert.equal(store.getCreatorProfile(creator.id).managementHistory.length, 2);
  r = await request(path, { version: submission.data.version, status: 'approved', note: '恢复合作' });
  assert.equal(r.status, 200); assert.equal(r.data.management.manager, '运营甲');
  assert.equal((await request('/v1/me/content', undefined, token)).status, 200);
  r = await request(path, { version: r.data.version, status: 'approved', canPublish: false, canReceiveOrders: false, note: '关闭业务权限' });
  assert.equal((await request('/v1/me/content', undefined, token)).status, 403);
  assert.equal((await request('/v1/me/creator-tasks', undefined, token)).data.code, 'ORDER_CREATOR_INELIGIBLE');
  submission = await request('/v1/me/creator-profile', profile, token);
  assert.equal(submission.data.status, 'pending');
  assert.equal(store.getCreatorProfile(creator.id).management.canPublish, false);
  assert.equal(store.getCreatorProfile(creator.id).managementHistory.length, 4);
});
