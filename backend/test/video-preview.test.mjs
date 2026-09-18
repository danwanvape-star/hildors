import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, copyFile, rm, readFile, stat } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { randomUUID } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { videoPreview, serveVideoPreview } from '../src/video-preview.mjs';
import { findTool } from '../src/processor.mjs';

test('real preview is bounded faststart H264 and preserves original; deduplicates and rechecks access', async t => {
 const directory=await mkdtemp(join(tmpdir(),'video-preview-')); t.after(()=>rm(directory,{recursive:true,force:true}));
 const id=randomUUID(); const source=join(directory,`${id}.mp4`);
 await copyFile(new URL('../../assets/videos/showcase/showcase_02.mp4',import.meta.url),source);
 const original=await readFile(source);
 const paths=await Promise.all([videoPreview(directory,id),videoPreview(directory,id)]);
 assert.equal(paths[0],paths[1]);
 const bytes=await readFile(paths[0]); assert.ok(bytes.length<original.length);
 assert.ok(bytes.indexOf(Buffer.from('moov'))<bytes.indexOf(Buffer.from('mdat')));
 const probe=JSON.parse(execFileSync(findTool('ffprobe'),['-v','error','-show_streams','-of','json',paths[0]],{encoding:'utf8',windowsHide:true}));
 const video=probe.streams.find(s=>s.codec_type==='video');
 assert.equal(video.codec_name,'h264'); assert.equal(video.pix_fmt,'yuv420p');
 assert.ok(video.width<=480 && video.height<=480); assert.equal(video.width%2,0); assert.equal(video.height%2,0);
 assert.equal(video.r_frame_rate,'24/1'); assert.deepEqual(await readFile(source),original);
 let checked=false;
 await serveVideoPreview({headers:{}},{writeHead(){throw Error('unauthorized bytes');}},directory,id,()=>{checked=true;return false;});
 assert.equal(checked,true); assert.ok((await stat(paths[0])).size>0);
});
import { createStore } from '../src/store.mjs';
import { app } from '../src/server.mjs';
import { writeFile } from 'node:fs/promises';

test('preview HTTP range, ETag and catalog contract; price/alias revocation denies cached bytes',async t=>{
 const directory=await mkdtemp(join(tmpdir(),'preview-api-')); const store=createStore(); const id=randomUUID();
 await copyFile(new URL('../../assets/videos/showcase/showcase_02.mp4',import.meta.url),join(directory,`${id}.mp4`));
 let item=store.create({title:'preview',source:'hildors',format:'single',tags:[],clips:[{id:'c',title:'preview'}]});
 item=store.attachMedia(item.id,'c',item.version,{id}); item=store.setInspection(item.id,'c',id,{status:'checked'});
 item=store.review(item.id,item.version,'approved','test','test'); item=store.transition(item.id,item.version,'published');
 const server=app(store,{mediaDirectory:directory}); await new Promise(r=>server.listen(0,'127.0.0.1',r));
 t.after(async()=>{await new Promise(r=>server.close(r));store.close();await rm(directory,{recursive:true,force:true});});
 const get=(path,headers={})=>fetch(`http://127.0.0.1:${server.address().port}${path}`,{headers}); const path=`/v1/media/${id}/preview?v=1`;
 assert.equal((await (await get('/v1/catalog')).json()).items[0].clips[0].previewPath,path);
 let response=await get(path,{Range:'bytes=0-63'}); assert.equal(response.status,206);assert.equal((await response.arrayBuffer()).byteLength,64);
 assert.equal(response.headers.get('cache-control'),'public, max-age=0, must-revalidate'); const etag=response.headers.get('etag');assert.ok(etag);
 assert.equal((await get(path,{'If-None-Match':etag})).status,304);
 assert.equal((await get(path,{Range:'bytes=999999999-'})).status,416);
 item=store.updateClipPricing(item.id,'c',item.version,{mode:'paid',currency:'USD',amountMinor:100});
 assert.equal((await get(path,{'If-None-Match':etag})).status,404);
 item=store.updateClipPricing(item.id,'c',item.version,{mode:'free',currency:'USD',amountMinor:0});
 const alias=store.create({title:'invalid alias',clips:[{id:'alias',pricing:{mode:'broken'}}]});
 store.attachMedia(alias.id,'alias',alias.version,{id});assert.equal((await get(path)).status,404);
});

test('malformed video has no original fallback and rejected IDs never reach filesystem',async t=>{
 const directory=await mkdtemp(join(tmpdir(),'preview-bad-'));t.after(()=>rm(directory,{recursive:true,force:true}));
 const id=randomUUID();await writeFile(join(directory,`${id}.mp4`),Buffer.alloc(50));
 await assert.rejects(videoPreview(directory,id)); await assert.rejects(videoPreview(directory,'../unsafe'),/INVALID_VIDEO/);
 await assert.rejects(stat(join(directory,'video-previews-v1',`${id}.mp4`)),{code:'ENOENT'});
});

test('revocation while derivative is being generated prevents response headers', async t=>{
 const directory=await mkdtemp(join(tmpdir(),'preview-race-'));t.after(()=>rm(directory,{recursive:true,force:true}));
 const id=randomUUID(); await copyFile(new URL('../../assets/videos/showcase/showcase_02.mp4',import.meta.url),join(directory,`${id}.mp4`));
 let permitted=true,checked=false;
 const response={writeHead(){throw Error('revoked preview leaked');},end(){throw Error('revoked preview ended');}};
 const serving=serveVideoPreview({headers:{}},response,directory,id,()=>{checked=true;return permitted;});
 permitted=false; await serving;assert.equal(checked,true);
 assert.ok((await stat(join(directory,'video-previews-v1',`${id}.mp4`))).size>24);
});
