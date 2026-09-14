import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, copyFile, rm, writeFile, stat } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { inspectVideo } from '../src/processor.mjs';
import { createStore } from '../src/store.mjs';

test('inspection results cannot attach to replaced media or published packages', () => {
  const store = createStore();
  try {
    const p = store.create({ demo: true, clips: [{ id: 'c' }] });
    store.attachMedia(p.id, 'c', 1, { id: 'new' });
    assert.throws(() => store.setInspection(p.id, 'c', 'old', { status: 'checked' }), /CONFLICT/);
    const checked = store.setInspection(p.id, 'c', 'new', { status: 'failed', code: 'TOOLS_UNAVAILABLE' });
    assert.equal(checked.clips[0].media.inspection.status, 'failed');
    assert.equal(checked.status, 'draft');
    store.transition(p.id, checked.version, 'published');
    assert.throws(() => store.setInspection(p.id, 'c', 'new', { status: 'checked' }), /CONFLICT/);
  } finally { store.close(); }
});

test('missing tools produce an explicit retryable failure', async () => {
  const previous = process.env.HILDORS_FFPROBE;
  process.env.HILDORS_FFPROBE = join(tmpdir(), 'hildors-tool-does-not-exist.exe');
  try { assert.equal((await inspectVideo(tmpdir(), 'missing')).code, 'TOOLS_UNAVAILABLE'); }
  finally { if (previous === undefined) delete process.env.HILDORS_FFPROBE; else process.env.HILDORS_FFPROBE = previous; }
});

test('actual demo decode and square thumbnail', { skip: process.env.HILDORS_MEDIA_INTEGRATION !== '1' }, async () => {
  const directory = await mkdtemp(join(tmpdir(), 'hildors-inspect-'));
  try {
    await copyFile(new URL('../../assets/videos/showcase/showcase_02.mp4', import.meta.url), join(directory, 'demo.mp4'));
    const result = await inspectVideo(directory, 'demo');
    assert.equal(result.status, 'checked');
    assert.ok(result.durationSeconds > 0); assert.ok((await stat(join(directory, 'demo.jpg'))).size > 100);
    await writeFile(join(directory, 'broken.mp4'), Buffer.from('invalid'));
    assert.equal((await inspectVideo(directory, 'broken')).code, 'INVALID_VIDEO');
  } finally { await rm(directory, { recursive: true }); }
});
