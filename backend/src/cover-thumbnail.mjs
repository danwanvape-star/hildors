import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { mkdir, stat, readFile, rename, unlink } from 'node:fs/promises';
import { resolve } from 'node:path';
import { randomUUID } from 'node:crypto';
import { findTool } from './processor.mjs';

const exec = promisify(execFile);
const pending = new Map();
let active = 0;
const waiting = [];
async function bounded(task) {
  if (active >= 2) {
    if (waiting.length >= 16) throw new Error('THUMBNAIL_BUSY');
    await new Promise(resolve => waiting.push(resolve));
  } else active++;
  try { return await task(); }
  finally { const next = waiting.shift(); if (next) next(); else active--; }
}
const run = (name, args) => exec(findTool(name), args, {
  timeout: 10000, killSignal: 'SIGKILL', maxBuffer: 256 * 1024, windowsHide: true,
});

export async function coverThumbnail(directory, cover, variant = 'thumbnail') {
  const edge = { thumbnail: 384, preview: 1024 }[variant];
  if (!edge) throw new Error('INVALID_IMAGE_VARIANT');
  if (!/^[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}$/.test(cover?.id ?? '') ||
      !['png', 'jpg', 'webp', 'heic', 'heif'].includes(cover.extension)) throw new Error('INVALID_IMAGE');
  const target = resolve(directory, variant === 'thumbnail' ? 'cover-thumbnails' : 'image-previews', `${cover.id}.jpg`);
  if (pending.has(target)) return pending.get(target);
  const work = (async () => {
    try { const info = await stat(target); if (info.isFile() && info.size > 0) return target; }
    catch (error) { if (error.code !== 'ENOENT') throw error; }
    return bounded(async () => {
      const input = resolve(directory, `${cover.id}.${cover.extension}`);
      const source = await stat(input);
      if (!source.isFile() || source.size < 32 || source.size > 8 * 1024 * 1024) throw new Error('INVALID_IMAGE');
      // Restrict demuxers as well as protocols: image-looking uploads cannot open playlists.
      const format = { png: 'png_pipe', jpg: 'jpeg_pipe', webp: 'webp_pipe', heic: 'mov', heif: 'mov' }[cover.extension];
      const inputArgs = ['-protocol_whitelist', 'file', '-f', format, '-i', input];
      const { stdout } = await run('ffprobe', ['-v', 'error', '-max_alloc', '134217728', ...inputArgs,
        '-select_streams', 'v:0', '-show_entries', 'stream=width,height', '-of', 'json']);
      const stream = JSON.parse(stdout).streams?.[0];
      if (!stream || !Number.isInteger(stream.width) || !Number.isInteger(stream.height) ||
          stream.width < 1 || stream.height < 1 || stream.width > 8192 || stream.height > 8192 ||
          stream.width * stream.height > 32000000) throw new Error('INVALID_IMAGE');
      await mkdir(resolve(directory, variant === 'thumbnail' ? 'cover-thumbnails' : 'image-previews'), { recursive: true });
      const temporary = `${target}.${randomUUID()}.part`;
      try {
        await run('ffmpeg', ['-nostdin', '-hide_banner', '-loglevel', 'error', '-max_alloc', '134217728',
          '-threads', '1', ...inputArgs, '-map', '0:v:0', '-frames:v', '1', '-an', '-sn',
          '-vf', `scale=w='min(${edge},iw)':h='min(${edge},ih)':force_original_aspect_ratio=decrease`,
          '-threads', '1', '-q:v', '4', '-f', 'image2', '-vcodec', 'mjpeg', '-update', '1', temporary]);
        const output = await stat(temporary);
        if (output.size < 4 || output.size > (variant === 'preview' ? 2 : 1) * 1024 * 1024) throw new Error('INVALID_IMAGE');
        await rename(temporary, target);
        return target;
      } finally { await unlink(temporary).catch(() => {}); }
    });
  })();
  pending.set(target, work);
  try { return await work; } finally { pending.delete(target); }
}

export async function serveImageVariant(req, res, directory, cover, { variant = 'thumbnail', publicCache = false, preflight } = {}) {
  const path = await coverThumbnail(directory, cover, variant);
  const bytes = await readFile(path);
  if (preflight && !preflight()) return;
  const etag = `"image-${cover.id}-${variant}-v1"`;
  const headers = { 'Content-Type': 'image/jpeg', 'Cache-Control': publicCache ? 'public, max-age=3600' : 'no-store',
    'X-Content-Type-Options': 'nosniff', ETag: etag };
  if (publicCache && req.headers['if-none-match'] === etag) { res.writeHead(304, headers); return res.end(); }
  res.writeHead(200, { ...headers, 'Content-Length': bytes.length });
  res.end(bytes);
}

export function serveCoverThumbnail(req, res, directory, cover, preflight) {
  return serveImageVariant(req, res, directory, cover, { publicCache: true, preflight });
}
