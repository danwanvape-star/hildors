import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { mkdir, stat, rename, unlink } from 'node:fs/promises';
import { resolve } from 'node:path';
import { randomUUID } from 'node:crypto';
import { findTool } from './processor.mjs';
import { serveMedia } from './media.mjs';

const exec = promisify(execFile);
const pending = new Map();
let active = false;
const waiting = [];
async function bounded(task) {
  if (active) {
    if (waiting.length >= 16) throw new Error('PREVIEW_BUSY');
    await new Promise(resolve => waiting.push(resolve));
  } else active = true;
  try { return await task(); }
  finally { const next = waiting.shift(); if (next) next(); else active = false; }
}
const run = (name, args) => exec(findTool(name), args, {
  timeout: name === 'ffprobe' ? 15000 : 120000, killSignal: 'SIGKILL', maxBuffer: 512 * 1024, windowsHide: true,
});
export async function videoPreview(directory, id) {
  if (!/^[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}$/.test(id ?? '')) throw new Error('INVALID_VIDEO');
  const outputDirectory = resolve(directory, 'video-previews-v1');
  const target = resolve(outputDirectory, `${id}.mp4`);
  if (pending.has(target)) return pending.get(target);
  const work = (async () => {
    try { const info = await stat(target); if (info.isFile() && info.size > 24) return target; }
    catch (error) { if (error.code !== 'ENOENT') throw error; }
    return bounded(async () => {
      const input = resolve(directory, `${id}.mp4`);
      const source = await stat(input);
      if (!source.isFile() || source.size < 24 || source.size > 256 * 1024 * 1024) throw new Error('INVALID_VIDEO');
      const inputArgs = ['-protocol_whitelist', 'file', '-f', 'mov', '-i', input];
      const { stdout } = await run('ffprobe', ['-v', 'error', '-max_alloc', '134217728', ...inputArgs,
        '-show_streams', '-show_format', '-of', 'json']);
      const probe = JSON.parse(stdout);
      const video = probe.streams?.find(s => s.codec_type === 'video' && !s.disposition?.attached_pic);
      const duration = Number(probe.format?.duration);
      if (!video || !Number.isFinite(duration) || duration <= 0 || duration > 600 ||
          !Number.isInteger(video.width) || !Number.isInteger(video.height) ||
          video.width < 2 || video.height < 2 || video.width > 4096 || video.height > 4096) throw new Error('INVALID_VIDEO');
      await mkdir(outputDirectory, { recursive: true });
      const temporary = `${target}.${randomUUID()}.part`;
      try {
        await run('ffmpeg', ['-nostdin', '-hide_banner', '-loglevel', 'error', '-xerror', '-max_alloc', '134217728',
          '-threads', '1', ...inputArgs, '-map', `0:${video.index}`, '-map', '0:a:0?', '-map_metadata', '-1', '-map_chapters', '-1',
          '-sn', '-dn', '-vf', "scale=w='min(480,iw)':h='min(480,ih)':force_original_aspect_ratio=decrease:force_divisible_by=2,setsar=1",
          '-r', '24', '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '28', '-maxrate', '600k', '-bufsize', '1200k',
          '-pix_fmt', 'yuv420p', '-threads', '1', '-c:a', 'aac', '-b:a', '64k', '-ac', '2',
          '-t', '600', '-movflags', '+faststart', '-f', 'mp4', temporary]);
        const output = await stat(temporary);
        if (output.size < 24 || output.size > 64 * 1024 * 1024) throw new Error('INVALID_VIDEO');
        await rename(temporary, target);
        return target;
      } finally { await unlink(temporary).catch(() => {}); }
    });
  })();
  pending.set(target, work);
  try { return await work; } finally { pending.delete(target); }
}
export async function serveVideoPreview(req, res, directory, id, preflight, { cacheControl = 'public, max-age=0, must-revalidate' } = {}) {
  await videoPreview(directory, id);
  return serveMedia(req, res, resolve(directory, 'video-previews-v1'), id, {
    preflight, cacheControl, etag: `"video-${id}-preview-v1"`,
  });
}
