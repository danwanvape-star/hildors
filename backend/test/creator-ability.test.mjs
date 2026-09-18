import test from 'node:test';
import assert from 'node:assert/strict';
import { creatorManagementUpdate, creatorRoute } from '../src/creator-management.mjs';

const applicant = { applicationVersion: 2, status: 'pending', applicationVideos: [
  { id: 'video', inspection: { status: 'checked', validation: 'decoded' } },
] };

test('video certification requires a submitted application, checked works and an explicit ability grade', () => {
  const approve = { status: 'approved', note: '作品通过' };
  assert.throws(() => creatorManagementUpdate(applicant, approve), /INVALID_CREATOR_PROFILE/);
  for (const abilityLevel of ['silver', 'gold', 'diamond', 'master', 'legend']) {
    const result = creatorManagementUpdate(applicant, { ...approve, abilityLevel });
    assert.equal(result.abilityLevel, abilityLevel);
    assert.equal(result.management.tier, 'standard');
    assert.deepEqual(result.managementHistory[0].changes.abilityLevel, { from: null, to: abilityLevel });
  }
  for (const patch of [{ status: 'draft' }, { applicationVideos: [] },
    { applicationVideos: [{ inspection: { status: 'failed' } }] },
    { applicationVideos: [{ inspection: { status: 'checked', validation: 'container_only' } }] }]) {
    assert.throws(() => creatorManagementUpdate({ ...applicant, ...patch }, { ...approve, abilityLevel: 'gold' }), /INVALID_CREATOR_PROFILE/);
  }
  assert.throws(() => creatorManagementUpdate(applicant, { ...approve, abilityLevel: 'bronze' }), /INVALID_CREATOR_PROFILE/);
});

test('ability persists independently of cooperation tier and legacy approved creators are not assigned a grade', () => {
  const result = creatorManagementUpdate({ ...applicant, status: 'approved', abilityLevel: 'diamond' },
    { status: 'suspended', tier: 'partner', note: '暂停' });
  assert.equal(result.abilityLevel, 'diamond');
  assert.equal(result.management.tier, 'partner');
  assert.equal(creatorManagementUpdate({ status: 'approved' }, { status: 'approved', note: '更新' }).abilityLevel, null);
  assert.throws(() => creatorManagementUpdate(applicant, { status: 'draft', note: '撤回' }), /INVALID_CREATOR_STATUS/);
});

test('admin list filters ability grade and includes draft counts and role tags', async () => {
  const items = [{ ...applicant, id: 'a', abilityLevel: 'gold', characterTags: ['科幻未来'] },
    { id: 'b', status: 'draft' }];
  let result;
  const invoke = query => creatorRoute({ req: { method: 'GET' }, url: new URL('http://local/admin/creators?' + query),
    store: { listCreatorProfiles: () => items }, send: (status, data) => { result = { status, data }; },
    fail: (status, code) => { result = { status, code }; } });
  await invoke('abilityLevel=gold&page=1');
  assert.equal(result.data.total, 1);
  assert.equal(result.data.summary.draft, 1);
  assert.deepEqual(result.data.items[0].characterTags, ['科幻未来']);
  assert.equal(result.data.items[0].abilityLevel, 'gold');
  await invoke('abilityLevel=bronze');
  assert.equal(result.status, 400);
});

test('review rechecks admin authorization after reading the request body', async () => {
  let authorized = true, modified = false, response;
  await creatorRoute({ req: { method: 'POST' }, url: new URL('http://local/admin/creators/a'),
    store: { getCreatorProfile: () => ({ ...applicant, id: 'a' }), manageCreatorProfile: () => { modified = true; } },
    readJson: async () => { authorized = false; return { version: 1, status: 'approved', abilityLevel: 'gold', note: '通过' }; },
    authorized: () => authorized, send: (status, data) => { response = status; },
    fail: status => { response = status; } });
  assert.equal(modified, false);
  assert.equal(response, 401);
});
