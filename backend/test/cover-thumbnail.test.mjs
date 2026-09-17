import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, writeFile, stat, readdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { execFileSync } from 'node:child_process';
import { findTool } from '../src/processor.mjs';
import { coverThumbnail } from '../src/cover-thumbnail.mjs';
const { app } = await import(process.env.HILDORS_TEST_SERVER_URL || '../src/server.mjs');

const id = '12345678-1234-1234-1234-123456789abc';
test('real cover derivative: dimensions, cache, concurrent requests, publication and original intact', async () => {
 const directory = await mkdtemp(join(tmpdir(), 'hildors-cover-'));
 const cover = {id, extension:'png', contentType:'image/png'};
 const item = {id:'package', status:'draft', cover, clips:[{id:'one',bundledAsset:'test.mp4'}]};
 const server = app({list:()=>[item],get:()=>item}, {mediaDirectory:directory});
 try {
  execFileSync(findTool('ffmpeg'), ['-v','error','-f','lavfi','-i','testsrc2=size=1254x800,noise=alls=30:allf=t','-frames:v','1',join(directory,`${id}.png`)], {windowsHide:true});
  const original = await readFile(join(directory,`${id}.png`));
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const url = `http://127.0.0.1:${server.address().port}/v1/covers/${id}/thumbnail`;
  assert.equal((await fetch(url)).status,404);
  assert.deepEqual(await readdir(directory),[`${id}.png`]);
  item.status='published';
  const catalogItem = await (await fetch(`http://127.0.0.1:${server.address().port}/v1/packages/package`)).json();
  assert.equal(catalogItem.coverPath, `/v1/covers/${id}`);
  assert.equal(catalogItem.coverThumbnailPath, `/v1/covers/${id}/thumbnail`);
  const responses = await Promise.all(Array.from({length:8},()=>fetch(url)));
  const buffers = await Promise.all(responses.map(async r=>{
   assert.equal(r.status,200); assert.equal(r.headers.get('content-type'),'image/jpeg');
   assert.equal(r.headers.get('cache-control'),'public, max-age=3600');
   return Buffer.from(await r.arrayBuffer());
  }));
  buffers.forEach(b=>assert.deepEqual(b,buffers[0]));
  assert.equal(buffers[0][0],255); assert.equal(buffers[0][1],216);
  assert.ok(buffers[0].length < original.length);
  const output = await coverThumbnail(directory,cover);
  const info = JSON.parse(execFileSync(findTool('ffprobe'),['-v','error','-show_streams','-of','json',output]));
  assert.equal(info.streams[0].width,384); assert.ok(info.streams[0].height<=384);
  assert.ok(Math.abs(info.streams[0].width/info.streams[0].height-1254/800)<0.02);
  const before = await stat(output);
  assert.equal((await fetch(url,{headers:{'If-None-Match':responses[0].headers.get('etag')}})).status,304);
  assert.equal((await stat(output)).mtimeMs,before.mtimeMs);
  assert.deepEqual(await readFile(join(directory,`${id}.png`)),original);
  assert.deepEqual(await readdir(join(directory,'cover-thumbnails')),[`${id}.jpg`]);
  item.status='draft'; assert.equal((await fetch(url)).status,404);
  await assert.rejects(coverThumbnail(directory,{...cover,id:'../escape'}),/INVALID_IMAGE/);
  await assert.rejects(coverThumbnail(directory,{...cover,extension:'../png'}),/INVALID_IMAGE/);
 } finally {
  await new Promise(resolve=>server.close(resolve));
  await rm(directory,{recursive:true,force:true});
 }
});

test('invalid and oversized image sources fail without a derivative',async()=>{
 const directory=await mkdtemp(join(tmpdir(),'hildors-cover-invalid-'));
 try {
  await writeFile(join(directory,`${id}.png`),Buffer.alloc(100));
  await assert.rejects(coverThumbnail(directory,{id,extension:'png'}));
  execFileSync(findTool('ffmpeg'),['-v','error','-y','-f','lavfi','-i','color=size=9000x2','-frames:v','1',join(directory,`${id}.png`)],{windowsHide:true});
  await assert.rejects(coverThumbnail(directory,{id,extension:'png'}),/INVALID_IMAGE/);
  assert.deepEqual(await readdir(directory),[`${id}.png`]);
 } finally { await rm(directory,{recursive:true,force:true}); }
});
