import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm, writeFile, mkdir, copyFile } from 'node:fs/promises';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { createStore } from '../src/store.mjs';
import { app } from '../src/server.mjs';

test('four real demos: upload, decode, thumbnail, review and metadata publication',
  { skip: process.env.HILDORS_MEDIA_INTEGRATION !== '1' }, async () => {
    const directory = await mkdtemp(join(tmpdir(), 'hildors-pipeline-'));
    const store = createStore();
    const server = app(store, { adminToken: 'pipeline-test-only', mediaDirectory: directory });
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
    const base = `http://127.0.0.1:${server.address().port}`;
    const headers = { Authorization: 'Bearer pipeline-test-only' };
    const report = [];
    const output = fileURLToPath(new URL('../data/acceptance/', import.meta.url));
    const post = async (path, body) => {
      const result = await fetch(base + path, { method: 'POST', headers, body: JSON.stringify(body) });
      const json = await result.json();
      assert.equal(result.status, 200, JSON.stringify(json)); return json;
    };
    try {
      for (let index = 1; index <= 4; index++) {
        const name = `showcase_${String(index).padStart(2, '0')}.mp4`;
        const data = await readFile(new URL(`../../assets/videos/showcase/${name}`, import.meta.url));
        const draft = store.create({ title: `验收 ${name}`, source: 'hildors', format: 'single', tags: [],
          clips: [{ id: 'clip', title: '演示视频', hardwareReady: false }] });
        const path = `/admin/packages/${draft.id}`;
        const upload = await fetch(base + path + '/clips/clip/media?process=auto', { method: 'PUT',
          headers: { ...headers, 'Content-Type': 'video/mp4', 'If-Match': '1' }, body: data });
        assert.equal(upload.status, 200);
        let item = await upload.json();
        const media = item.clips[0].media;
        assert.equal(media.inspection.status, 'checked', JSON.stringify(media.inspection));
        const image = await fetch(base + `/admin/media/${media.id}/thumbnail`, { headers });
        assert.equal(image.status, 200); assert.equal(image.headers.get('content-type'), 'image/jpeg');
        const thumbnail = Buffer.from(await image.arrayBuffer());
        assert.equal(thumbnail.readUInt16BE(0), 0xffd8);
        await mkdir(output, { recursive: true });
        await copyFile(join(directory, `${media.id}.jpg`), join(output, name.replace('.mp4', '.jpg')));
        // Internal test approval is isolated in an in-memory database, not a real rights claim.
        item = await post(path + '/review', { version: item.version, decision: 'approved',
          note: '自动验收隔离数据', rightsConfirmed: true, rightsReference: 'TEST-ONLY-NOT-A-LICENSE' });
        await post(path + '/publish', { version: item.version });
        const published = await (await fetch(base + '/v1/packages/' + draft.id)).json();
        assert.equal(published.status, 'published'); assert.equal(published.review, undefined);
        assert.equal(published.clips[0].hardwareReady, false); assert.equal(published.clips[0].media, undefined);
        assert.equal(published.clips[0].previewPath, `/v1/media/${media.id}`);
        assert.equal((await fetch(base + published.clips[0].thumbnailPath)).status, 200);
        assert.equal((await fetch(base + published.clips[0].previewPath, { headers: { Range: 'bytes=0-11' } })).status, 206);
        report.push({ file: name, ...media.inspection, bytes: media.bytes, thumbnailBytes: thumbnail.length });
      }
      await mkdir(output, { recursive: true });
      await writeFile(join(output, 'pipeline.json'), JSON.stringify({ checkedAt: new Date().toISOString(), results: report }, null, 2));
    } finally {
      await new Promise(resolve => server.close(resolve)); store.close();
      await rm(directory, { recursive: true });
    }
  });
