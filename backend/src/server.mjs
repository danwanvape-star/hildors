import { serveCoverThumbnail } from './cover-thumbnail.mjs';
import { validPricing, publicPricing, publicFullPreview } from './clip-pricing.mjs';
import { createServer } from 'node:http';
import { randomBytes, randomUUID, timingSafeEqual } from 'node:crypto';
import { mkdirSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';
import { createStore, seedDemos } from './store.mjs';
import { receiveMedia, receiveImage, serveImage, serveMedia } from './media.mjs';
import { unlink } from 'node:fs/promises';
import { inspectVideo } from './processor.mjs';
import { authorizedClip } from './delivery.mjs';
import { stat } from 'node:fs/promises';
import { runtimeConfig } from './runtime-config.mjs';

function validDocument(value) {
  return value && typeof value.title === 'string' && value.title.trim().length > 0 && value.title.length <= 120
    && ['hildors', 'creator'].includes(value.source)
    && ['single', 'package'].includes(value.format)
    && Array.isArray(value.tags) && value.tags.length <= 12
    && value.tags.every(t => typeof t === 'string' && t.length > 0 && t.length <= 32)
    && Array.isArray(value.clips) && value.clips.length > 0 && value.clips.length <= 100
    && (value.format !== 'single' || value.clips.length === 1)
    && new Set(value.clips.map(c => c?.id)).size === value.clips.length
    && value.clips.every(c => c && typeof c.id === 'string' && c.id.length > 0 && c.id.length <= 100
      && typeof c.title === 'string' && c.title.length > 0 && c.title.length <= 120);
}

function publicPackage(item) {
  return { id: item.id, title: item.title, version: item.version, status: item.status,
    source: item.source, format: item.format, tags: item.tags, demo: item.demo,
    ...(item.cover ? { coverPath: `/v1/covers/${item.cover.id}`, coverThumbnailPath: `/v1/covers/${item.cover.id}/thumbnail` } : {}),
    clips: item.clips.map(c => ({ id: c.id, title: c.title, hardwareReady: false,
      ...(validPricing(c.pricing) ? { pricing: publicPricing(c.pricing) } : {}),
      durationSeconds: c.media?.inspection?.durationSeconds ?? c.durationSeconds,
      ...(item.demo ? { bundledAsset: c.bundledAsset, thumbnail: c.thumbnail } : {}),
      ...(!item.demo && c.media?.inspection?.status === 'checked' ? {
        ...(publicFullPreview(c) ? { previewPath: `/v1/media/${c.media.id}` } : {}),
        thumbnailPath: `/v1/media/${c.media.id}/thumbnail`,
      } : {}) })) };
}

function validLayout(value) {
  const allowed = {
    collection: new Set(['hildors', 'creators']),
    discover: new Set(['customization', 'character_portal', 'creator_join']),
  };
  if (!value || value.schemaVersion !== 1 || !value.pages || typeof value.pages !== 'object') return false;
  return Object.entries(allowed).every(([page, types]) => {
    const blocks = value.pages[page];
    return Array.isArray(blocks) && blocks.length >= 1 && blocks.length <= 12
      && new Set(blocks.map(block => block?.id)).size === blocks.length
      && blocks.every(block => block && typeof block.id === 'string' && /^[a-z0-9-]{3,60}$/.test(block.id)
        && types.has(block.type) && typeof block.title === 'string' && block.title.trim().length > 0
        && block.title.length <= 40 && typeof block.visible === 'boolean'
        && Number.isInteger(block.columns) && block.columns >= 1 && block.columns <= 3);
  });
}

export function app(store, { adminToken = '', adminUsername = '', adminPassword = '', mediaDirectory = fileURLToPath(new URL('../data/media/', import.meta.url)), uploadLimit, inspector = inspectVideo, enableDownloads = false, mode = 'local' } = {}) {
  let processing = false;
  const sessions = new Map();
  const sessionLifetime = 8 * 60 * 60 * 1000;
  return createServer(async (req, res) => {
    const requestId = randomUUID();
    function send(status, data) {
      res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8',
        'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' });
      res.end(JSON.stringify(data));
    }
    const fail = (status, code) => send(status, { code, requestId });
    try {
      const url = new URL(req.url, 'http://localhost');
      const path = url.pathname;
      const staticFiles = { '/console/clip-pricing.js': ['clip-pricing.js', 'text/javascript'], '/console': ['index.html', 'text/html'], '/console/app.js': ['app.js', 'text/javascript'], '/console/style.css': ['style.css', 'text/css'], '/console/media.css': ['media.css', 'text/css'], '/console/connection.css': ['connection.css', 'text/css'], '/console/admin-nav.css': ['admin-nav.css', 'text/css'], '/console/layout.css': ['layout.css', 'text/css'], '/console/orders.css': ['orders.css', 'text/css'] };
      if (req.method === 'GET' && Object.hasOwn(staticFiles, path)) {
        const [name, type] = staticFiles[path];
        res.writeHead(200, { 'Content-Type': `${type}; charset=utf-8`, 'Cache-Control': 'no-store',
          'X-Content-Type-Options': 'nosniff', 'Content-Security-Policy': "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' blob:; media-src 'self' blob:; frame-ancestors 'none'; base-uri 'none'; form-action 'self'" });
        return res.end(readFileSync(new URL(`../public/${name}`, import.meta.url)));
      }
      if (req.method === 'POST' && path === '/admin/login') {
        const chunks = []; let bytes = 0;
        for await (const chunk of req) { bytes += chunk.length; if (bytes > 4096) return fail(413, 'BODY_TOO_LARGE'); chunks.push(chunk); }
        let credentials;
        try { credentials = JSON.parse(Buffer.concat(chunks).toString('utf8')); } catch { return fail(400, 'INVALID_JSON'); }
        const same = (a, b) => { const left = Buffer.from(String(a || '')), right = Buffer.from(String(b || '')); return left.length === right.length && timingSafeEqual(left, right); };
        if (!adminUsername || !adminPassword || !same(credentials.username, adminUsername) || !same(credentials.password, adminPassword)) return fail(401, 'INVALID_CREDENTIALS');
        const session = randomBytes(32).toString('base64url'); sessions.set(session, Date.now() + sessionLifetime);
        res.setHeader('Set-Cookie', `hildors_admin=${session}; HttpOnly; SameSite=Strict; Path=/; Max-Age=${sessionLifetime / 1000}`);
        return send(200, { authenticated: true });
      }
      if (req.method === 'POST' && path === '/admin/logout') {
        const session = /(?:^|;\s*)hildors_admin=([^;]+)/.exec(req.headers.cookie || '')?.[1];
        if (session) sessions.delete(session);
        res.setHeader('Set-Cookie', 'hildors_admin=; HttpOnly; SameSite=Strict; Path=/; Max-Age=0');
        return send(200, { authenticated: false });
      }
      if (path.startsWith('/admin/')) {
        const supplied = Buffer.from(req.headers.authorization || '');
        const expected = Buffer.from(`Bearer ${adminToken}`);
        const bearerValid = adminToken && supplied.length === expected.length && timingSafeEqual(supplied, expected);
        const session = /(?:^|;\s*)hildors_admin=([^;]+)/.exec(req.headers.cookie || '')?.[1];
        const expires = session && sessions.get(session);
        const sessionValid = Boolean(expires && expires > Date.now());
        if (session && !sessionValid) sessions.delete(session);
        if (!bearerValid && !sessionValid) return fail(401, 'UNAUTHORIZED');
      }
      if (req.method === 'GET' && path === '/health') return send(200, { status: 'ok', mode });
      if (req.method === 'GET' && path === '/ready') {
        try {
          return store.ready() ? send(200, { status: 'ready' }) : fail(503, 'NOT_READY');
        } catch { return fail(503, 'NOT_READY'); }
      }
      if (req.method === 'POST' && path === '/v1/device-session') {
        const userId = store.createUser();
        return send(201, { token: store.createSession(userId, 86400), expiresIn: 86400 });
      }
      if (path === '/v1/me' || path.startsWith('/v1/me/')) {
        const token = /^Bearer ([A-Za-z0-9_-]{43})$/.exec(req.headers.authorization || '')?.[1];
        const userId = store.authenticate(token);
        if (!userId) return fail(401, 'USER_AUTH_REQUIRED');
        if (req.method === 'GET' && path === '/v1/me') return send(200, { id: userId });
        if (req.method === 'DELETE' && path === '/v1/me/session') {
          store.revokeSession(token); return send(200, { signedOut: true });
        }
        if (req.method === 'GET' && path === '/v1/me/customization-orders') {
          return send(200, { items: store.listCustomizationOrders(userId) });
        }
        if (req.method === 'POST' && path === '/v1/me/customization-orders') {
          const chunks = []; let bytes = 0;
          for await (const chunk of req) { bytes += chunk.length; if (bytes > 32768) return fail(413, 'BODY_TOO_LARGE'); chunks.push(chunk); }
          let value; try { value = JSON.parse(Buffer.concat(chunks).toString('utf8')); } catch { return fail(400, 'INVALID_JSON'); }
          if (!value || typeof value.characterName !== 'string' || !value.characterName.trim()
            || value.characterName.length > 120 || typeof value.sourceType !== 'string' || value.sourceType.length > 80
            || !Array.isArray(value.requestedFeatures) || value.requestedFeatures.length > 20
            || !value.requestedFeatures.every(x => typeof x === 'string' && x.length <= 80)
            || !Number.isInteger(value.materialCount) || value.materialCount < 0 || value.materialCount > 20
            || typeof value.marketRegion !== 'string' || value.marketRegion.length > 32
            || typeof value.privacyConsentVersion !== 'string' || !value.privacyConsentVersion.trim()) return fail(400, 'INVALID_CUSTOMIZATION_ORDER');
          return send(201, store.createCustomizationOrder(userId, {
            characterName: value.characterName.trim(), sourceType: value.sourceType,
            requestedFeatures: value.requestedFeatures, materialCount: value.materialCount,
            marketRegion: value.marketRegion, privacyConsentVersion: value.privacyConsentVersion,
            privacyConsentAt: new Date().toISOString(), materialsUploaded: false,
          }));
        }
        if (req.method === 'GET' && path === '/v1/me/creator-profile') {
          const profile = store.getCreatorProfile(userId); return profile ? send(200, profile) : fail(404, 'NOT_FOUND');
        }
        if (req.method === 'POST' && path === '/v1/me/creator-profile') {
          const chunks = []; let bytes = 0;
          for await (const chunk of req) { bytes += chunk.length; if (bytes > 32768) return fail(413, 'BODY_TOO_LARGE'); chunks.push(chunk); }
          let value; try { value = JSON.parse(Buffer.concat(chunks).toString('utf8')); } catch { return fail(400, 'INVALID_JSON'); }
          if (!value || typeof value.displayName !== 'string' || !value.displayName.trim() || value.displayName.length > 80
            || typeof value.email !== 'string' || value.email.length > 254
            || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(value.email.trim())
            || typeof value.portfolioUrl !== 'string' || value.portfolioUrl.length > 500
            || !Array.isArray(value.skillTags) || value.skillTags.length > 20
            || !value.skillTags.every(x => typeof x === 'string' && x.length <= 60)
            || typeof value.marketRegion !== 'string' || value.marketRegion.length > 32
            || typeof value.agreementVersion !== 'string' || !value.agreementVersion.trim()) return fail(400, 'INVALID_CREATOR_PROFILE');
          return send(200, store.upsertCreatorProfile(userId, { displayName: value.displayName.trim(),
            email: value.email.trim().toLowerCase(),
            portfolioUrl: value.portfolioUrl.trim(), skillTags: value.skillTags,
            marketRegion: value.marketRegion, agreementVersion: value.agreementVersion,
            agreementAcceptedAt: new Date().toISOString() }));
        }
        const download = /^\/v1\/me\/packages\/([^/]+)\/clips\/([^/]+)\/(download|manifest|access)$/.exec(path);
        if (req.method === 'GET' && download) {
          if (download[3] === 'access') {
            const allowed = enableDownloads && authorizedClip(store, userId,
              decodeURIComponent(download[1]), decodeURIComponent(download[2]));
            return send(200, { canDownload: Boolean(allowed),
              reason: !enableDownloads ? 'DOWNLOAD_NOT_ENABLED' : allowed ? 'ALLOWED' : 'CONTENT_UNAVAILABLE',
              hardwareReady: false });
          }
          if (!enableDownloads) return fail(503, 'DOWNLOAD_NOT_ENABLED');
          const packageId = decodeURIComponent(download[1]), clipId = decodeURIComponent(download[2]);
          const allowed = authorizedClip(store, userId, packageId, clipId);
          if (!allowed) return fail(404, 'CONTENT_UNAVAILABLE');
          const { media, item } = allowed;
          const info = await stat(resolve(mediaDirectory, `${media.id}.mp4`));
          if (info.size !== media.bytes) return fail(409, 'MEDIA_INTEGRITY_ERROR');
          // Stat is asynchronous: recheck revocation/session expiry before streaming.
          if (store.authenticate(token) !== userId) return fail(401, 'USER_AUTH_REQUIRED');
          if (!authorizedClip(store, userId, packageId, clipId)) return fail(404, 'CONTENT_UNAVAILABLE');
          if (download[3] === 'manifest') return send(200, {
            packageId, clipId, packageVersion: item.version, bytes: media.bytes, sha256: media.sha256,
            contentType: 'video/mp4', hardwareReady: false,
            downloadPath: `/v1/me/packages/${encodeURIComponent(packageId)}/clips/${encodeURIComponent(clipId)}/download`,
            authorizationRequired: true,
          });
          return await serveMedia(req, res, mediaDirectory, media.id, { preflight: () => {
            if (store.authenticate(token) !== userId) { fail(401, 'USER_AUTH_REQUIRED'); return false; }
            if (!authorizedClip(store, userId, packageId, clipId)) { fail(404, 'CONTENT_UNAVAILABLE'); return false; }
            return true;
          } });
        }
        if (req.method === 'GET' && path === '/v1/me/entitlements') {
          return send(200, { items: store.entitlements(userId).map(entry => {
            const item = store.get(entry.package_id);
            const available = entry.status === 'active' && item?.status === 'published';
            return { packageId: entry.package_id, status: entry.status, available,
              title: item?.title, cloudDownload: false, hardwareReady: false };
          }) });
        }
        return fail(404, 'NOT_FOUND');
      }
      if (req.method === 'GET' && path === '/v1/bootstrap') return send(200, {
        mode, capabilities: { cloudDownload: enableDownloads, hardwareTranscoding: false, payments: false } });
      if (req.method === 'GET' && path === '/v1/layout') {
        const layout = store.getLayout();
        return send(200, { version: layout.version, layout: layout.published, updatedAt: layout.updatedAt });
      }
      if (req.method === 'GET' && path === '/v1/catalog') {
        const limit = Number(url.searchParams.get('limit') ?? 24);
        if (!Number.isInteger(limit) || limit < 1 || limit > 100) return fail(400, 'INVALID_LIMIT');
        const query = (url.searchParams.get('query') || '').toLowerCase();
        const items = store.list().filter(p => p.status === 'published'
          && (!url.searchParams.get('source') || p.source === url.searchParams.get('source'))
          && (!url.searchParams.get('format') || p.format === url.searchParams.get('format'))
          && (!url.searchParams.get('tag') || p.tags.includes(url.searchParams.get('tag')))
          && p.title.toLowerCase().includes(query)
          && p.id > (url.searchParams.get('cursor') || ''));
        return send(200, { items: items.slice(0, limit).map(publicPackage), nextCursor: items.length > limit ? items[limit - 1].id : null });
      }
      const publicMedia = /^\/v1\/media\/([a-f0-9-]{36})(\/thumbnail)?$/.exec(path);
      if (req.method === 'GET' && publicMedia) {
        const published = store.list().some(p => p.status === 'published' && p.clips.some(c =>
          c.media?.id === publicMedia[1] && c.media.inspection?.status === 'checked'));
        if (!published) return fail(404, 'NOT_FOUND');
        // A shared media ID cannot make a paid video's full file public through another clip.
        if (!publicMedia[2] && store.list().some(p => p.clips.some(c =>
          c.media?.id === publicMedia[1] && !publicFullPreview(c)))) return fail(404, 'NOT_FOUND');
        if (publicMedia[2]) {
          const image = readFileSync(resolve(mediaDirectory, `${publicMedia[1]}.jpg`));
          res.writeHead(200, { 'Content-Type': 'image/jpeg', 'Cache-Control': 'public, max-age=3600',
            'X-Content-Type-Options': 'nosniff' });
          return res.end(image);
        }
        return await serveMedia(req, res, mediaDirectory, publicMedia[1], { preflight: () => {
          const items = store.list();
          const available = items.some(p => p.status === 'published' && p.clips.some(c =>
            c.media?.id === publicMedia[1] && c.media.inspection?.status === 'checked'));
          if (!available || items.some(p => p.clips.some(c => c.media?.id === publicMedia[1] && !publicFullPreview(c)))) {
            fail(404, 'NOT_FOUND'); return false;
          }
          return true;
        } });
      }
      const coverThumbnailRoute = /^\/v1\/covers\/([a-f0-9-]{36})\/thumbnail$/.exec(path);
      if (req.method === 'GET' && coverThumbnailRoute) {
        const available = () => store.list().find(p => p.status === 'published' && p.cover?.id === coverThumbnailRoute[1]);
        const item = available();
        if (!item) return fail(404, 'NOT_FOUND');
        return await serveCoverThumbnail(req, res, mediaDirectory, item.cover, () => {
          if (available()) return true;
          fail(404, 'NOT_FOUND'); return false;
        });
      }
      const publicCover = /^\/v1\/covers\/([a-f0-9-]{36})$/.exec(path);
      if (req.method === 'GET' && publicCover) {
        const item = store.list().find(p => p.status === 'published' && p.cover?.id === publicCover[1]);
        if (!item) return fail(404, 'NOT_FOUND');
        return await serveImage(res, mediaDirectory, item.cover, { publicCache: true });
      }
      if (req.method === 'GET' && path.startsWith('/v1/packages/')) {
        const item = store.get(decodeURIComponent(path.slice('/v1/packages/'.length)));
        return item?.status === 'published' ? send(200, publicPackage(item)) : fail(404, 'NOT_FOUND');
      }
      if (req.method === 'GET' && path === '/admin/packages') return send(200, { items: store.list() });
      if (req.method === 'GET' && path === '/admin/customization-orders') return send(200, { items: store.listCustomizationOrders() });
      if (req.method === 'GET' && path === '/admin/creators') return send(200, { items: store.listCreatorProfiles() });
      if (req.method === 'GET' && path === '/admin/layout') return send(200, store.getLayout());
      if (req.method === 'GET' && path === '/admin/audit') return send(200, { items: store.auditLog() });
      const pricingRoute = /^\/admin\/packages\/([^/]+)\/clips\/([^/]+)\/pricing$/.exec(path);
      if (req.method === 'POST' && pricingRoute) {
        const id = decodeURIComponent(pricingRoute[1]), clipId = decodeURIComponent(pricingRoute[2]);
        if (!store.get(id)?.clips.some(c => c.id === clipId)) return fail(404, 'NOT_FOUND');
        const chunks = []; let bytes = 0;
        for await (const chunk of req) {
          bytes += chunk.length; if (bytes > 65536) return fail(413, 'BODY_TOO_LARGE'); chunks.push(chunk);
        }
        let value;
        try { value = JSON.parse(Buffer.concat(chunks).toString('utf8')); } catch { return fail(400, 'INVALID_JSON'); }
        if (!Number.isSafeInteger(value?.version) || value.version < 1 || !validPricing(value?.pricing)) return fail(400, 'INVALID_PRICING');
        return send(200, store.updateClipPricing(id, clipId, value.version, value.pricing));
      }
      const inspect = /^\/admin\/packages\/([^/]+)\/clips\/([^/]+)\/inspect$/.exec(path);
      if (req.method === 'POST' && inspect) {
        const id = decodeURIComponent(inspect[1]), clipId = decodeURIComponent(inspect[2]);
        const item = store.get(id), clip = item?.clips.find(c => c.id === clipId);
        if (!clip?.media) return fail(404, 'NOT_FOUND');
        if (item.status !== 'draft') return fail(409, 'VERSION_OR_STATE_CONFLICT');
        if (processing) return fail(409, 'PROCESSOR_BUSY');
        processing = true;
        try {
          // Invalidate any previous approval before a recheck begins.
          store.setInspection(id, clipId, clip.media.id, { status: 'processing', startedAt: new Date().toISOString() });
          const result = await inspector(mediaDirectory, clip.media.id);
          return send(200, store.setInspection(id, clipId, clip.media.id, result));
        } finally { processing = false; }
      }
      const thumbnail = /^\/admin\/media\/([a-f0-9-]{36})\/thumbnail$/.exec(path);
      if (req.method === 'GET' && thumbnail) {
        if (!store.list().some(p => p.clips.some(c => c.media?.id === thumbnail[1] && c.media.inspection?.status === 'checked'))) return fail(404, 'NOT_FOUND');
        const image = readFileSync(resolve(mediaDirectory, `${thumbnail[1]}.jpg`));
        res.writeHead(200, { 'Content-Type': 'image/jpeg', 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' });
        return res.end(image);
      }
      const adminCover = /^\/admin\/covers\/([a-f0-9-]{36})$/.exec(path);
      if (req.method === 'GET' && adminCover) {
        const item = store.list().find(p => p.cover?.id === adminCover[1]);
        if (!item) return fail(404, 'NOT_FOUND');
        return await serveImage(res, mediaDirectory, item.cover);
      }
      const upload = /^\/admin\/packages\/([^/]+)\/clips\/([^/]+)\/media$/.exec(path);
      if (req.method === 'PUT' && upload) {
        const id = decodeURIComponent(upload[1]), clipId = decodeURIComponent(upload[2]);
        const item = store.get(id), version = Number(req.headers['if-match']);
        if (!item || !item.clips.some(c => c.id === clipId)) return fail(404, 'NOT_FOUND');
        if (item.status !== 'draft' || item.version !== version) return fail(409, 'VERSION_OR_STATE_CONFLICT');
        if (req.headers['content-type'] !== 'video/mp4') return fail(415, 'MP4_REQUIRED');
        const media = await receiveMedia(req, mediaDirectory, uploadLimit);
        try { return send(200, store.attachMedia(id, clipId, version, media)); }
        catch (error) { await unlink(resolve(mediaDirectory, `${media.id}.mp4`)).catch(() => {}); throw error; }
      }
      const coverUpload = /^\/admin\/packages\/([^/]+)\/cover$/.exec(path);
      if (req.method === 'PUT' && coverUpload) {
        const id = decodeURIComponent(coverUpload[1]), item = store.get(id), version = Number(req.headers['if-match']);
        if (!item) return fail(404, 'NOT_FOUND');
        if (item.status !== 'draft' || item.version !== version || item.format !== 'package') return fail(409, 'VERSION_OR_STATE_CONFLICT');
        if (!['image/jpeg','image/png'].includes(req.headers['content-type'])) return fail(415, 'IMAGE_REQUIRED');
        const cover = await receiveImage(req, mediaDirectory, req.headers['content-type']);
        return send(200, store.attachCover(id, version, cover));
      }
      const mediaRoute = /^\/admin\/media\/([a-f0-9-]{36})$/.exec(path);
      if (req.method === 'GET' && mediaRoute) {
        if (!store.list().some(p => p.clips.some(c => c.media?.id === mediaRoute[1]))) return fail(404, 'NOT_FOUND');
        return await serveMedia(req, res, mediaDirectory, mediaRoute[1]);
      }
      if (req.method === 'POST' && path.startsWith('/admin/packages')) {
        const chunks = []; let bytes = 0;
        for await (const chunk of req) {
          bytes += chunk.length;
          if (bytes > 65536) { fail(413, 'BODY_TOO_LARGE'); return; }
          chunks.push(chunk);
        }
        let value;
        try { value = JSON.parse(Buffer.concat(chunks).toString('utf8')); } catch { return fail(400, 'INVALID_JSON'); }
        if (path === '/admin/packages') {
          if (!validDocument(value)) return fail(400, 'INVALID_PACKAGE');
          // Metadata-only drafts cannot claim playable assets or hardware readiness.
          return send(201, store.create({ title: value.title.trim(), source: value.source,
            format: value.format, tags: value.tags,
            clips: value.clips.map(c => ({ id: c.id, title: c.title, hardwareReady: false })), demo: false }));
        }
        const review = /^\/admin\/packages\/([^/]+)\/review$/.exec(path);
        if (review) {
          if (!['approved', 'rejected'].includes(value?.decision) || typeof value.note !== 'string'
            || !value.note.trim() || value.note.length > 1000 || !Number.isInteger(value.version)) return fail(400, 'INVALID_REVIEW');
          if (value.decision === 'approved' && (value.rightsConfirmed !== true
            || typeof value.rightsReference !== 'string' || !value.rightsReference.trim()
            || value.rightsReference.length > 300)) return fail(400, 'RIGHTS_REFERENCE_REQUIRED');
          const id = decodeURIComponent(review[1]);
          if (!store.get(id)) return fail(404, 'NOT_FOUND');
          return send(200, store.review(id, value.version, value.decision, value.note.trim(),
            value.decision === 'approved' ? value.rightsReference.trim() : null));
        }
        const match = /^\/admin\/packages\/([^/]+)\/(publish|withdraw)$/.exec(path);
        if (match) {
          const item = store.get(match[1]);
          if (!item) return fail(404, 'NOT_FOUND');
          // Publication exposes catalog metadata only; hardwareReady remains false.
          const result = store.transition(item.id, value?.version, match[2] === 'publish' ? 'published' : 'withdrawn');
          return send(200, result);
        }
      }
      if (req.method === 'POST' && path.startsWith('/admin/customization-orders/')) {
        const id = decodeURIComponent(path.slice('/admin/customization-orders/'.length));
        const chunks = []; for await (const chunk of req) chunks.push(chunk);
        let value; try { value = JSON.parse(Buffer.concat(chunks).toString('utf8')); } catch { return fail(400, 'INVALID_JSON'); }
        if (!Number.isInteger(value?.version) || typeof value?.status !== 'string' || typeof (value.note ?? '') !== 'string') return fail(400, 'INVALID_ORDER_UPDATE');
        return send(200, store.updateCustomizationOrderWorkflow(id, value.version, value.status, value.note ?? '', value.fields ?? {}));
      }
      if (req.method === 'POST' && path.startsWith('/admin/creators/')) {
        const id = decodeURIComponent(path.slice('/admin/creators/'.length));
        const chunks = []; for await (const chunk of req) chunks.push(chunk);
        let value; try { value = JSON.parse(Buffer.concat(chunks).toString('utf8')); } catch { return fail(400, 'INVALID_JSON'); }
        if (!Number.isInteger(value?.version) || typeof value?.status !== 'string' || typeof (value.note ?? '') !== 'string') return fail(400, 'INVALID_CREATOR_UPDATE');
        return send(200, store.manageCreatorProfile(id, value.version, value));
      }
      if (req.method === 'POST' && path === '/admin/layout/draft') {
        const chunks = []; let bytes = 0; for await (const chunk of req) { bytes += chunk.length; if (bytes > 65536) return fail(413, 'BODY_TOO_LARGE'); chunks.push(chunk); }
        let value; try { value = JSON.parse(Buffer.concat(chunks).toString('utf8')); } catch { return fail(400, 'INVALID_JSON'); }
        if (!Number.isInteger(value?.version) || !validLayout(value?.layout)) return fail(400, 'INVALID_LAYOUT');
        return send(200, store.saveLayoutDraft(value.version, value.layout));
      }
      if (req.method === 'POST' && path === '/admin/layout/publish') {
        const chunks = []; for await (const chunk of req) chunks.push(chunk);
        let value; try { value = JSON.parse(Buffer.concat(chunks).toString('utf8')); } catch { return fail(400, 'INVALID_JSON'); }
        if (!Number.isInteger(value?.version)) return fail(400, 'INVALID_LAYOUT_VERSION');
        return send(200, store.publishLayout(value.version));
      }
      if (req.method === 'POST' && path === '/admin/layout/rollback') {
        const chunks = []; for await (const chunk of req) chunks.push(chunk);
        let value; try { value = JSON.parse(Buffer.concat(chunks).toString('utf8')); } catch { return fail(400, 'INVALID_JSON'); }
        if (!Number.isInteger(value?.version)) return fail(400, 'INVALID_LAYOUT_VERSION');
        return send(200, store.rollbackLayout(value.version));
      }
      return fail(404, 'NOT_FOUND');
    } catch (error) {
      if (error.message === 'EMAIL_IN_USE') return fail(409, 'EMAIL_IN_USE');
      if (error.message === 'INVALID_ORDER_TRANSITION') return fail(409, 'INVALID_ORDER_TRANSITION');
      if (error.message.startsWith('ORDER_')) return fail(400, error.message);
      if (error.message === 'INVALID_IMAGE') return fail(415, 'INVALID_IMAGE');
      if (error.message === 'UPLOAD_TOO_LARGE') return fail(413, 'UPLOAD_TOO_LARGE');
      if (error.message === 'INVALID_MP4') return fail(415, 'INVALID_MP4');
      if (error.message === 'MEDIA_REVIEW_REQUIRED') return fail(409, 'MEDIA_REVIEW_REQUIRED');
      if (error.message === 'PACKAGE_COVER_REQUIRED') return fail(409, 'PACKAGE_COVER_REQUIRED');
      if (error.code === 'ENOENT') return fail(404, 'NOT_FOUND');
      return fail(error.message === 'CONFLICT' ? 409 : 500, error.message === 'CONFLICT' ? 'VERSION_OR_STATE_CONFLICT' : 'INTERNAL_ERROR');
    }
  });
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const config = runtimeConfig(process.env, fileURLToPath(new URL('../data/', import.meta.url)));
  const directory = config.directory;
  mkdirSync(directory, { recursive: true });
  const store = createStore(resolve(directory, 'catalog.sqlite'));
  if (config.seedDemos) seedDemos(store);
  const server = app(store, { adminToken: config.adminToken, adminUsername: config.adminUsername,
    adminPassword: config.adminPassword, mediaDirectory: resolve(directory, 'media'), mode: config.mode, enableDownloads: config.enableDownloads });
  server.listen(config.port, config.host, () => console.log(`HILDORS ${config.mode}: http://${config.host}:${config.port}/health`));
  const stop = () => server.close(() => { store.close(); process.exit(0); });
  process.on('SIGINT', stop); process.on('SIGTERM', stop);
}
