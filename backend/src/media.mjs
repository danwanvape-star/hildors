import { mkdir, open, rename, unlink, stat } from 'node:fs/promises';
import { createReadStream } from 'node:fs';
import { createHash, randomUUID } from 'node:crypto';
import { resolve } from 'node:path';

// MP4 container check only. Codec/QC and manufacturer conversion remain pending.
export async function receiveMedia(req, directory, limit = 256 * 1024 * 1024) {
  await mkdir(directory, { recursive: true });
  const id = randomUUID(); const path = resolve(directory, `${id}.mp4`);
  const temporary = `${path}.part`; let handle; let bytes = 0; let header = Buffer.alloc(0);
  const hash = createHash('sha256');
  try {
    handle = await open(temporary, 'wx');
    for await (const chunk of req) {
      bytes += chunk.length;
      if (bytes > limit) throw new Error('UPLOAD_TOO_LARGE');
      if (header.length < 12) header = Buffer.concat([header, chunk.subarray(0, 12 - header.length)]);
      hash.update(chunk);
      let offset = 0;
      while (offset < chunk.length) offset += (await handle.write(chunk, offset, chunk.length - offset)).bytesWritten;
    }
    if (header.length < 12 || header.toString('ascii', 4, 8) !== 'ftyp' || bytes < 24) throw new Error('INVALID_MP4');
    await handle.close(); handle = undefined;
    await rename(temporary, path);
    return { id, bytes, sha256: hash.digest('hex'), validation: 'container_only', uploadedAt: new Date().toISOString() };
  } catch (error) { await handle?.close(); await unlink(temporary).catch(() => {}); throw error; }
}

export async function receiveImage(req, directory, contentType, limit = 8 * 1024 * 1024) {
  await mkdir(directory, { recursive: true });
  const extension = ({'image/png':'png','image/jpeg':'jpg','image/webp':'webp','image/heic':'heic','image/heif':'heif'})[contentType];
  if (!extension) throw new Error('INVALID_IMAGE');
  const id = randomUUID(); const path = resolve(directory, `${id}.${extension}`);
  const temporary = `${path}.part`; let handle; let bytes = 0; let header = Buffer.alloc(0);
  try {
    handle = await open(temporary, 'wx');
    for await (const chunk of req) {
      bytes += chunk.length;
      if (bytes > limit) throw new Error('UPLOAD_TOO_LARGE');
      if (header.length < 12) header = Buffer.concat([header, chunk.subarray(0, 12 - header.length)]);
      let offset = 0;
      while (offset < chunk.length) offset += (await handle.write(chunk, offset, chunk.length - offset)).bytesWritten;
    }
    const jpeg = header[0] === 0xff && header[1] === 0xd8 && header[2] === 0xff;
    const png = header.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10]));
    const webp = header.toString('ascii',0,4)==='RIFF' && header.toString('ascii',8,12)==='WEBP';
    const heif = header.toString('ascii',4,8)==='ftyp' && ['heic','heix','hevc','hevx','mif1','msf1'].includes(header.toString('ascii',8,12));
    if (bytes < 32 || !({jpg:jpeg,png,webp,heic:heif,heif})[extension]) throw new Error('INVALID_IMAGE');
    await handle.close(); handle = undefined; await rename(temporary, path);
    return { id, bytes, extension, contentType, uploadedAt: new Date().toISOString() };
  } catch (error) { await handle?.close(); await unlink(temporary).catch(() => {}); throw error; }
}

export async function serveImage(res, directory, image, { publicCache = false } = {}) {
  const path = resolve(directory, `${image.id}.${image.extension}`);
  const info = await stat(path);
  res.writeHead(200, { 'Content-Type': image.contentType, 'Content-Length': info.size,
    'Cache-Control': publicCache ? 'public, max-age=3600' : 'no-store', 'X-Content-Type-Options': 'nosniff' });
  const stream = createReadStream(path); stream.on('error', () => res.destroy());
  res.on('close', () => stream.destroy()); stream.pipe(res);
}

export async function serveMedia(req, res, directory, id, { publicCache = false, preflight, cacheControl, etag } = {}) {
  const path = resolve(directory, `${id}.mp4`);
  const info = await stat(path);
  if (preflight && !preflight()) return;
  if (etag && req.headers['if-none-match'] === etag) { res.writeHead(304, { ETag: etag, 'Cache-Control': cacheControl }); return res.end(); }
  let start = 0, end = info.size - 1, status = 200;
  if (req.headers.range) {
    const match = /^bytes=(\d+)-(\d*)$/.exec(req.headers.range);
    if (!match) { res.writeHead(416, { 'Content-Range': `bytes */${info.size}` }); return res.end(); }
    start = Number(match[1]); end = match[2] ? Math.min(Number(match[2]), end) : end;
    if (start > end || !Number.isSafeInteger(start)) { res.writeHead(416, { 'Content-Range': `bytes */${info.size}` }); return res.end(); }
    status = 206;
  }
  const headers = { 'Content-Type': 'video/mp4', 'Content-Length': end - start + 1,
    'Cache-Control': cacheControl ?? (publicCache ? 'public, max-age=3600' : 'no-store'), ...(etag ? { ETag: etag } : {}),
    'Accept-Ranges': 'bytes', 'X-Content-Type-Options': 'nosniff' };
  if (status === 206) headers['Content-Range'] = `bytes ${start}-${end}/${info.size}`;
  res.writeHead(status, headers);
  const stream = createReadStream(path, { start, end });
  stream.on('error', () => res.destroy()); res.on('close', () => stream.destroy()); stream.pipe(res);
}
