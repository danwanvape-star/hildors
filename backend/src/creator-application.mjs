import { resolve } from 'node:path';
import { unlink } from 'node:fs/promises';
import { receiveMedia, serveMedia } from './media.mjs';

async function removeVideoFiles(directory, id) {
  await Promise.all(['.mp4', '.jpg', '.processing.jpg'].map(extension => unlink(resolve(directory, id + extension)).catch(error => {
    if (error.code !== 'ENOENT') throw error;
  })));
}

export async function creatorApplicationRoute({req, res, url, store, send, fail, readJson, mediaDirectory,
  userId = null, authorized = () => false, inspector, uploadLimit}) {
  const path = url.pathname, base = '/v1/me/creator-application';
  const adminVideo = /^\/admin\/creators\/([^/]+)\/application-videos\/([^/]+)$/.exec(path);
  if (path !== base && !path.startsWith(base + '/') && !adminVideo) return false;
  const directory = resolve(mediaDirectory, 'creator-applications');
  const checkSession = () => {
    if (authorized()) return true;
    fail(401, userId ? 'USER_AUTH_REQUIRED' : 'UNAUTHORIZED'); return false;
  };
  if (!checkSession()) return true;
  if (adminVideo || (req.method === 'GET' && path.startsWith(base + '/videos/'))) {
    if (req.method !== 'GET') { fail(404, 'NOT_FOUND'); return true; }
    const profileId = adminVideo ? decodeURIComponent(adminVideo[1]) : userId;
    const videoId = decodeURIComponent(adminVideo ? adminVideo[2] : path.slice((base + '/videos/').length));
    const lookup = () => store.getCreatorProfile(profileId)?.applicationVideos?.find(video => video.id === videoId);
    const video = lookup();
    if (!video) { fail(404, 'NOT_FOUND'); return true; }
    await serveMedia(req, res, directory, video.id, {preflight: () => {
      if (!checkSession()) return false;
      if (!lookup()) { fail(404, 'NOT_FOUND'); return false; }
      return true;
    }}); return true;
  }
  if (path === base && req.method === 'GET') {
    const profile = store.getCreatorProfile(userId);
    if (profile) send(200, profile); else fail(404, 'NOT_FOUND');
    return true;
  }
  if (path === base && req.method === 'POST') {
    const value = await readJson(); if (!checkSession()) return true;
    send(200, store.saveCreatorApplication(userId, value)); return true;
  }
  if (path === base + '/submit' && req.method === 'POST') {
    const value = await readJson(); if (!checkSession()) return true;
    send(200, store.submitCreatorApplication(userId, value?.version)); return true;
  }
  if (path === base + '/videos' && req.method === 'PUT') {
    const version = Number(req.headers['if-match']);
    const profile = store.checkCreatorApplicationEditable(userId, version);
    if ((profile.applicationVideos ?? []).length >= 10) throw new Error('CREATOR_APPLICATION_VIDEO_LIMIT');
    const name = (url.searchParams.get('name') || '申请视频').trim();
    if (!name || name.length > 240) throw new Error('INVALID_CREATOR_APPLICATION');
    if (req.headers['content-type'] !== 'video/mp4') { fail(415, 'MP4_REQUIRED'); return true; }
    const limit = Math.min(uploadLimit ?? 15_000_000, 15_000_000);
    if (Number(req.headers['content-length']) > limit) { fail(413, 'UPLOAD_TOO_LARGE'); return true; }
    const video = await receiveMedia(req, directory, limit);
    let attached = false;
    try {
      if (!authorized()) throw new Error('USER_AUTH_REQUIRED');
      store.checkCreatorApplicationEditable(userId, version);
      const inspection = await inspector(directory, video.id);
      if (!authorized()) throw new Error('USER_AUTH_REQUIRED');
      store.checkCreatorApplicationEditable(userId, version);
      if (inspection?.status !== 'checked' || inspection.validation !== 'decoded') {
        throw new Error('CREATOR_APPLICATION_VIDEO_INVALID');
      }
      const result = store.attachCreatorApplicationVideo(userId, version, {...video, name, inspection});
      attached = true; send(200, result);
    } finally { if (!attached) await removeVideoFiles(directory, video.id); }
    return true;
  }
  const deletion = new RegExp('^' + base + '/videos/([^/]+)$').exec(path);
  if (deletion && req.method === 'DELETE') {
    const id = decodeURIComponent(deletion[1]), version = Number(url.searchParams.get('version'));
    const profile = store.checkCreatorApplicationEditable(userId, version);
    const video = profile.applicationVideos?.find(video => video.id === id);
    if (!video) { fail(404, 'NOT_FOUND'); return true; }
    const result = store.removeCreatorApplicationVideo(userId, version, id);
    await removeVideoFiles(directory, video.id);
    send(200, result); return true;
  }
  fail(404, 'NOT_FOUND'); return true;
}
