import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { runtimeConfig } from '../src/runtime-config.mjs';
import { createStore } from '../src/store.mjs';
import { app } from '../src/server.mjs';

test('runtime is loopback-only and staging fails closed without explicit storage/credential', () => {
  const directory = join(tmpdir(), 'hildors-config-test');
  assert.equal(runtimeConfig({}, directory).seedDemos, true);
  for (const env of [{ HILDORS_PORT: 'bad' }, { HILDORS_PORT: '80' }, { HILDORS_MODE: 'production' },
    { HILDORS_MODE: 'team-staging' }, { HILDORS_MODE: 'team-staging', HILDORS_DATA_DIR: 'relative' },
    { HILDORS_MODE: 'team-staging', HILDORS_DATA_DIR: directory, HILDORS_ADMIN_TOKEN: 'weak' }]) {
    assert.throws(() => runtimeConfig(env, directory));
  }
  const config = runtimeConfig({ HILDORS_MODE: 'team-staging', HILDORS_DATA_DIR: directory,
    HILDORS_ADMIN_TOKEN: 'a'.repeat(43), HILDORS_HOST: '0.0.0.0', HILDORS_PORT: '8877' }, directory);
  assert.equal(config.host, '127.0.0.1'); assert.equal(config.port, 8877); assert.equal(config.seedDemos, false);
});

test('credential file supported, ambiguous credentials rejected', () => {
  const directory = mkdtempSync(join(tmpdir(), 'hildors-secret-test-'));
  try {
    const path = join(directory, 'token'); writeFileSync(path, 'a'.repeat(43) + '\n');
    assert.equal(runtimeConfig({ HILDORS_ADMIN_TOKEN_FILE: path }, directory).adminToken.length, 43);
    assert.throws(() => runtimeConfig({ HILDORS_ADMIN_TOKEN_FILE: path, HILDORS_ADMIN_TOKEN: 'other' }, directory));
  } finally { rmSync(directory, { recursive: true }); }
});

test('readiness checks database and does not reveal credentials or paths', async () => {
  const store = createStore();
  const server = app(store);
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  try {
    const url = `http://127.0.0.1:${server.address().port}/ready`;
    const response = await fetch(url);
    assert.equal(response.status, 200); assert.deepEqual(await response.json(), { status: 'ready' });
    store.close();
    assert.equal((await fetch(url)).status, 503);
  } finally { await new Promise(r => server.close(r)); }
});
