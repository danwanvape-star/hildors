// Isolated loopback fixture. Credentials are ephemeral and sent only over the parent pipe.
import { mkdtemp, rm, readFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { randomBytes } from 'node:crypto';
import { createStore } from '../src/store.mjs';
import { app } from '../src/server.mjs';

const directory = await mkdtemp(join(tmpdir(), 'hildors-app-e2e-'));
const store = createStore();
const adminToken = randomBytes(32).toString('base64url');
const server = app(store, { adminToken, mediaDirectory: directory, enableDownloads: true });
let stopping = false;
async function stop() {
  if (stopping) return;
  stopping = true;
  await new Promise(resolve => server.close(resolve));
  store.close(); await rm(directory, { recursive: true, force: true });
}
try {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  const call = async (path, method, body, extra = {}) => {
    const response = await fetch(base + path, { method,
      headers: { Authorization: `Bearer ${adminToken}`, ...extra }, body });
    if (!response.ok) throw new Error('FIXTURE_REQUEST_FAILED');
    return response.json();
  };
  await call('/admin/content-tags', 'POST', JSON.stringify({ items: [{ name: 'Integration', active: true }] }));
  let item = await call('/admin/packages', 'POST', JSON.stringify({
    title: 'Isolated App E2E', description: 'Isolated download integration fixture', source: 'hildors', format: 'single', tags: ['Integration'],
    clips: [{ id: 'clip', title: 'Real showcase video' }],
  }));
  const path = `/admin/packages/${item.id}`;
  const video = await readFile(new URL('../../assets/videos/showcase/showcase_02.mp4', import.meta.url));
  await call(path + '/clips/clip/media', 'PUT', video, { 'If-Match': '1', 'Content-Type': 'video/mp4' });
  item = await call(path + '/clips/clip/inspect', 'POST', '{}');
  if (item.clips[0].media.inspection.status !== 'checked') throw new Error('FIXTURE_DECODE_FAILED');
  item = await call(path + '/review', 'POST', JSON.stringify({ version: item.version,
    decision: 'approved', note: 'Isolated test only', rightsConfirmed: true,
    rightsReference: 'TEST-ONLY-NOT-A-LICENSE' }));
  item = await call(path + '/publish', 'POST', JSON.stringify({ version: item.version }));
  const user = store.createUser();
  store.setEntitlement(user, item.id, 'active', 'TEST-ONLY');
  const token = store.createSession(user);
  process.stdout.write(JSON.stringify({ base, packageId: item.id, version: item.version,
    token, adminToken }) + '\n');
  process.stdin.resume();
  process.stdin.on('end', () => stop().catch(() => { process.exitCode = 1; }));
  process.on('SIGTERM', () => stop().catch(() => { process.exitCode = 1; }));
} catch {
  process.stderr.write('App E2E fixture failed; check Node and FFmpeg availability.\n');
  await stop(); process.exitCode = 1;
}
