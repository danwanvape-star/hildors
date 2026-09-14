import test from 'node:test';
import assert from 'node:assert/strict';
import { createStore, seedDemos } from '../src/store.mjs';
import { app } from '../src/server.mjs';

test('user sessions isolate entitlements, revoke access and reject admin credentials', async () => {
  const store = createStore(); seedDemos(store);
  const alice = store.createUser(), bob = store.createUser();
  const token = store.createSession(alice), other = store.createSession(bob);
  store.setEntitlement(alice, 'hildors_demo_01', 'active', 'local-test-grant');
  const server = app(store, { adminToken: 'admin-test-only' });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  const request = (path, bearer, method = 'GET') => fetch(base + path, { method, headers: bearer ? { Authorization: `Bearer ${bearer}` } : {} });
  try {
    assert.equal((await request('/v1/me', null)).status, 401);
    assert.equal((await request('/v1/me', 'admin-test-only')).status, 401);
    assert.equal((await request('/admin/packages', token)).status, 401);
    assert.deepEqual(await (await request('/v1/me', token)).json(), { id: alice });
    assert.deepEqual((await (await request('/v1/me/entitlements', other)).json()).items, []);
    let items = (await (await request('/v1/me/entitlements?userId=' + bob, token)).json()).items;
    assert.equal(items.length, 1); assert.equal(items[0].available, true);
    assert.equal(items[0].cloudDownload, false); assert.equal(items[0].reference, undefined);
    store.transition('hildors_demo_01', 2, 'withdrawn');
    items = (await (await request('/v1/me/entitlements', token)).json()).items;
    assert.equal(items[0].available, false);
    store.setEntitlement(alice, 'hildors_demo_01', 'revoked', 'test-revoke');
    assert.equal(store.entitlements(alice)[0].status, 'revoked');
    assert.throws(() => store.setEntitlement(alice, 'hildors_demo_01', 'active', 'test'), /CONFLICT/);
    assert.equal((await request('/v1/me/session', token, 'DELETE')).status, 200);
    assert.equal((await request('/v1/me', token)).status, 401);
    assert.equal((await request('/v1/me', other)).status, 200);
    assert.throws(() => store.createSession(bob, 0), /INVALID_LIFETIME/);
  } finally { await new Promise(resolve => server.close(resolve)); store.close(); }
});
