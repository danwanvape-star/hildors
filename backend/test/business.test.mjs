import test from 'node:test';
import assert from 'node:assert/strict';
import { createStore } from '../src/store.mjs';
import { app } from '../src/server.mjs';

test('customization intake and creator registration are user-scoped and admin-managed', async t => {
  const store = createStore();
  const server = app(store, { adminToken: 'admin-test' });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(async () => { await new Promise(resolve => server.close(resolve)); store.close(); });
  const base = `http://127.0.0.1:${server.address().port}`;
  const session = await fetch(base + '/v1/device-session', { method: 'POST' });
  assert.equal(session.status, 201);
  const token = (await session.json()).token;
  const userHeaders = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };
  const adminHeaders = { Authorization: 'Bearer admin-test', 'Content-Type': 'application/json' };
  const order = await fetch(base + '/v1/me/customization-orders', { method: 'POST', headers: userHeaders,
    body: JSON.stringify({ characterName: '星际狐狸', sourceType: '原创角色', requestedFeatures: ['待机'],
      materialCount: 3, marketRegion: 'us', privacyConsentVersion: 'privacy-v1' }) });
  assert.equal(order.status, 201); const orderItem = await order.json();
  assert.equal(orderItem.materialsUploaded, false);
  assert.equal((await (await fetch(base + '/v1/me/customization-orders', { headers: userHeaders })).json()).items.length, 1);
  const adminOrders = await (await fetch(base + '/admin/customization-orders', { headers: adminHeaders })).json();
  assert.equal(adminOrders.items[0].characterName, '星际狐狸');
  const updated = await fetch(base + `/admin/customization-orders/${orderItem.id}`, { method: 'POST', headers: adminHeaders,
    body: JSON.stringify({ version: orderItem.version, status: 'approved_for_quote', note: '可报价' }) });
  const updatedItem = await updated.json();
  assert.equal(updatedItem.status, 'approved_for_quote');
  assert.equal(updatedItem.workflowHistory[0].from, 'free_review');
  assert.equal(updatedItem.workflowHistory[0].to, 'approved_for_quote');
  const skipped = await fetch(base + `/admin/customization-orders/${orderItem.id}`, { method: 'POST', headers: adminHeaders,
    body: JSON.stringify({ version: updatedItem.version, status: 'delivered', note: '跳过流程' }) });
  assert.equal(skipped.status, 409);
  assert.equal((await skipped.json()).code, 'INVALID_ORDER_TRANSITION');
  const creator = await fetch(base + '/v1/me/creator-profile', { method: 'POST', headers: userHeaders,
    body: JSON.stringify({ displayName: 'Creator A', email: 'creator-a@example.test', portfolioUrl: 'https://example.test/work',
      skillTags: ['3D'], marketRegion: 'us', agreementVersion: 'creator-v1' }) });
  assert.equal(creator.status, 200); const creatorItem = await creator.json();
  assert.equal(creatorItem.status, 'pending');
  const reviewed = await fetch(base + `/admin/creators/${creatorItem.id}`, { method: 'POST', headers: adminHeaders,
    body: JSON.stringify({ version: creatorItem.version, status: 'approved', note: '作品审核通过' }) });
  assert.equal((await reviewed.json()).status, 'approved');
  assert.equal((await fetch(base + '/admin/customization-orders')).status, 401);
});

test('app layout supports guarded draft, publication and rollback', async t => {
  const store = createStore();
  const server = app(store, { adminToken: 'admin-test' });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(async () => { await new Promise(resolve => server.close(resolve)); store.close(); });
  const base = `http://127.0.0.1:${server.address().port}`;
  const adminHeaders = { Authorization: 'Bearer admin-test', 'Content-Type': 'application/json' };
  const initial = await (await fetch(base + '/admin/layout', { headers: adminHeaders })).json();
  assert.equal(initial.draft.pages.collection[0].type, 'hildors');
  const changed = structuredClone(initial.draft);
  changed.pages.collection.reverse();
  const saved = await (await fetch(base + '/admin/layout/draft', { method: 'POST', headers: adminHeaders,
    body: JSON.stringify({ version: initial.version, layout: changed }) })).json();
  assert.equal(saved.published.pages.collection[0].type, 'hildors');
  const published = await (await fetch(base + '/admin/layout/publish', { method: 'POST', headers: adminHeaders,
    body: JSON.stringify({ version: saved.version }) })).json();
  const publicLayout = await (await fetch(base + '/v1/layout')).json();
  assert.equal(publicLayout.layout.pages.collection[0].type, 'creators');
  const rolledBack = await (await fetch(base + '/admin/layout/rollback', { method: 'POST', headers: adminHeaders,
    body: JSON.stringify({ version: published.version }) })).json();
  assert.equal(rolledBack.published.pages.collection[0].type, 'hildors');
  changed.pages.collection[0].type = 'unsafe_widget';
  assert.equal((await fetch(base + '/admin/layout/draft', { method: 'POST', headers: adminHeaders,
    body: JSON.stringify({ version: rolledBack.version, layout: changed }) })).status, 400);
});
