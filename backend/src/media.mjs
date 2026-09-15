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

export async function serveMedia(req, res, directory, id, { publicCache = false } = {}) {
  const path = resolve(directory, `${id}.mp4`);
  const info = await stat(path);
  let start = 0, end = info.size - 1, status = 200;
  if (req.headers.range) {
    const match = /^bytes=(\d+)-(\d*)$/.exec(req.headers.range);
    if (!match) { res.writeHead(416, { 'Content-Range': `bytes */${info.size}` }); return res.end(); }
    start = Number(match[1]); end = match[2] ? Math.min(Number(match[2]), end) : end;
    if (start > end || !Number.isSafeInteger(start)) { res.writeHead(416, { 'Content-Range': `bytes */${info.size}` }); return res.end(); }
    status = 206;
  }
  const headers = { 'Content-Type': 'video/mp4', 'Content-Length': end - start + 1,
    'Cache-Control': publicCache ? 'public, max-age=3600' : 'no-store',
    'Accept-Ranges': 'bytes', 'X-Content-Type-Options': 'nosniff' };
  if (status === 206) headers['Content-Range'] = `bytes ${start}-${end}/${info.size}`;
  res.writeHead(status, headers);
  const stream = createReadStream(path, { start, end });
  stream.on('error', () => res.destroy()); res.on('close', () => stream.destroy()); stream.pipe(res);
}
