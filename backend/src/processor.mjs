import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { existsSync, readdirSync } from 'node:fs';
import { rename, unlink } from 'node:fs/promises';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const exec = promisify(execFile);
export function findTool(name) {
  const configured = process.env[`HILDORS_${name.toUpperCase()}`];
  if (configured) return configured;
  const root = fileURLToPath(new URL('../data/tools/', import.meta.url));
  if (existsSync(root)) {
    for (const entry of readdirSync(root, { withFileTypes: true })) {
      const path = resolve(root, entry.name, 'bin', `${name}.exe`);
      if (entry.isDirectory() && existsSync(path)) return path;
    }
  }
  return name;
}

export async function inspectVideo(directory, id) {
  const input = resolve(directory, `${id}.mp4`);
  const temporary = resolve(directory, `${id}.processing.jpg`);
  const run = (name, args) => exec(findTool(name), args, {
    timeout: 120000, maxBuffer: 2 * 1024 * 1024, windowsHide: true,
  });
  try {
    const { stdout } = await run('ffprobe', ['-v', 'error', '-protocol_whitelist', 'file',
      '-show_streams', '-show_format', '-of', 'json', input]);
    const probe = JSON.parse(stdout);
    const video = probe.streams?.find(s => s.codec_type === 'video' && !s.disposition?.attached_pic);
    const duration = Number(probe.format?.duration);
    if (!video || !Number.isFinite(duration) || duration <= 0 || !video.width || !video.height) throw new Error('INVALID_VIDEO');
    // Bounded prototype workload; larger input can be handled by future workers.
    if (duration > 600 || video.width > 4096 || video.height > 4096) throw new Error('PROCESSING_LIMIT');
    await run('ffmpeg', ['-nostdin', '-v', 'error', '-xerror', '-threads', '2',
      '-protocol_whitelist', 'file', '-i', input, '-map', `0:${video.index}`, '-map', '0:a?', '-f', 'null', '-']);
    await run('ffmpeg', ['-nostdin', '-v', 'error', '-y', '-threads', '2',
      '-protocol_whitelist', 'file', '-ss', String(Math.min(1, duration / 2)), '-i', input,
      '-map', `0:${video.index}`, '-frames:v', '1', '-vf', 'scale=480:480:force_original_aspect_ratio=decrease,pad=480:480:(ow-iw)/2:(oh-ih)/2:black,setsar=1', temporary]);
    await rename(temporary, resolve(directory, `${id}.jpg`));
    return { status: 'checked', width: video.width, height: video.height,
      durationSeconds: duration, videoDurationSeconds: Number.isFinite(Number(video.duration)) && Number(video.duration)>0 ? Number(video.duration) : null, videoCodec: video.codec_name,
      audioCodec: probe.streams.find(s => s.codec_type === 'audio')?.codec_name ?? null,
      thumbnail: true, checkedAt: new Date().toISOString(), validation: 'decoded' };
  } catch (error) {
    await unlink(temporary).catch(() => {});
    return { status: 'failed', code: error.code === 'ENOENT' ? 'TOOLS_UNAVAILABLE'
      : error.killed ? 'PROCESSING_TIMEOUT'
      : error.message === 'PROCESSING_LIMIT' ? 'PROCESSING_LIMIT' : 'INVALID_VIDEO',
      checkedAt: new Date().toISOString() };
  }
}
