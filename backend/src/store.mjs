import { DatabaseSync } from 'node:sqlite';
import { randomUUID, randomBytes, createHash } from 'node:crypto';

export function createStore(path = ':memory:') {
  const db = new DatabaseSync(path);
  db.exec(`PRAGMA foreign_keys=ON;
    CREATE TABLE IF NOT EXISTS packages (
      id TEXT PRIMARY KEY, version INTEGER NOT NULL CHECK(version > 0),
      status TEXT NOT NULL CHECK(status IN ('draft','published','withdrawn')),
      document TEXT NOT NULL, created_at TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS audit (
      id TEXT PRIMARY KEY, package_id TEXT NOT NULL REFERENCES packages(id),
      action TEXT NOT NULL, created_at TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS users (id TEXT PRIMARY KEY);
    CREATE TABLE IF NOT EXISTS sessions (
      token_hash TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id), expires_at INTEGER NOT NULL);
    CREATE TABLE IF NOT EXISTS entitlements (
      user_id TEXT NOT NULL REFERENCES users(id), package_id TEXT NOT NULL REFERENCES packages(id),
      status TEXT NOT NULL CHECK(status IN ('active','revoked')), reference TEXT NOT NULL,
      PRIMARY KEY(user_id, package_id));
    CREATE TABLE IF NOT EXISTS customization_orders (
      id TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id), version INTEGER NOT NULL,
      status TEXT NOT NULL, document TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS creator_profiles (
      id TEXT PRIMARY KEY, user_id TEXT NOT NULL UNIQUE REFERENCES users(id), version INTEGER NOT NULL,
      status TEXT NOT NULL, document TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL);`);
  const tokenHash = token => createHash('sha256').update(token).digest('hex');
  const decode = row => row ? { ...JSON.parse(row.document), id: row.id,
    version: row.version, status: row.status } : null;
  function get(id) { return decode(db.prepare('SELECT * FROM packages WHERE id=?').get(id)); }
  function audit(id, action) {
    db.prepare('INSERT INTO audit VALUES (?,?,?,?)').run(randomUUID(), id, action, new Date().toISOString());
  }
  function transaction(fn) {
    db.exec('BEGIN');
    try { const result = fn(); db.exec('COMMIT'); return result; }
    catch (error) { db.exec('ROLLBACK'); throw error; }
  }
  return {
    get,
    ready: () => db.prepare('SELECT 1 AS ok').get().ok === 1,
    // Internal provisioning only: never accept a client-supplied user ID as authentication.
    createUser(id = randomUUID()) {
      db.prepare('INSERT INTO users VALUES (?)').run(id); return id;
    },
    createSession(userId, lifetimeSeconds = 3600) {
      if (!Number.isInteger(lifetimeSeconds) || lifetimeSeconds < 1 || lifetimeSeconds > 86400) throw new Error('INVALID_LIFETIME');
      const token = randomBytes(32).toString('base64url');
      db.prepare('INSERT INTO sessions VALUES (?,?,?)').run(tokenHash(token), userId, Date.now() + lifetimeSeconds * 1000);
      return token;
    },
    authenticate(token) {
      if (typeof token !== 'string' || !/^[A-Za-z0-9_-]{43}$/.test(token)) return null;
      return db.prepare('SELECT user_id FROM sessions WHERE token_hash=? AND expires_at>?').get(tokenHash(token), Date.now())?.user_id ?? null;
    },
    revokeSession(token) { db.prepare('DELETE FROM sessions WHERE token_hash=?').run(tokenHash(token)); },
    setEntitlement(userId, packageId, status, reference) {
      if (!['active', 'revoked'].includes(status) || typeof reference !== 'string' || !reference.trim() || reference.length > 300) throw new Error('INVALID_ENTITLEMENT');
      return transaction(() => {
        if (status === 'active' && get(packageId)?.status !== 'published') throw new Error('CONFLICT');
        db.prepare('INSERT INTO entitlements VALUES (?,?,?,?) ON CONFLICT(user_id,package_id) DO UPDATE SET status=excluded.status,reference=excluded.reference')
          .run(userId, packageId, status, reference.trim());
        audit(packageId, `entitlement_${status}:${userId}`);
      });
    },
    entitlements(userId) {
      return db.prepare('SELECT package_id,status FROM entitlements WHERE user_id=? ORDER BY package_id').all(userId);
    },
    createCustomizationOrder(userId, document) {
      const id = randomUUID(), now = new Date().toISOString();
      db.prepare('INSERT INTO customization_orders VALUES (?,?,1,?,?,?,?)')
        .run(id, userId, 'free_review', JSON.stringify(document), now, now);
      return this.getCustomizationOrder(id);
    },
    getCustomizationOrder(id) {
      const row = db.prepare('SELECT * FROM customization_orders WHERE id=?').get(id);
      return row ? { ...JSON.parse(row.document), id: row.id, userId: row.user_id,
        version: row.version, status: row.status, createdAt: row.created_at, updatedAt: row.updated_at } : null;
    },
    listCustomizationOrders(userId = null) {
      const rows = userId
        ? db.prepare('SELECT * FROM customization_orders WHERE user_id=? ORDER BY created_at DESC').all(userId)
        : db.prepare('SELECT * FROM customization_orders ORDER BY created_at DESC').all();
      return rows.map(row => ({ ...JSON.parse(row.document), id: row.id, userId: row.user_id,
        version: row.version, status: row.status, createdAt: row.created_at, updatedAt: row.updated_at }));
    },
    updateCustomizationOrder(id, version, status, note = '') {
      const current = this.getCustomizationOrder(id);
      if (!current || current.version !== version) throw new Error('CONFLICT');
      const allowed = ['free_review','needs_info','approved_for_quote','quoted','in_production','quality_review','user_acceptance','delivered','rejected','withdrawn'];
      if (!allowed.includes(status)) throw new Error('INVALID_ORDER_STATUS');
      const document = { ...current, adminNote: note.trim(), status: undefined, id: undefined,
        userId: undefined, version: undefined, createdAt: undefined, updatedAt: undefined };
      const now = new Date().toISOString();
      db.prepare('UPDATE customization_orders SET status=?,document=?,version=version+1,updated_at=? WHERE id=?')
        .run(status, JSON.stringify(document), now, id);
      return this.getCustomizationOrder(id);
    },
    upsertCreatorProfile(userId, document) {
      const existing = db.prepare('SELECT id FROM creator_profiles WHERE user_id=?').get(userId);
      const now = new Date().toISOString(), id = existing?.id ?? randomUUID();
      if (existing) db.prepare('UPDATE creator_profiles SET document=?,status=?,version=version+1,updated_at=? WHERE id=?')
        .run(JSON.stringify(document), 'pending', now, id);
      else db.prepare('INSERT INTO creator_profiles VALUES (?,?,1,?,?,?,?)')
        .run(id, userId, 'pending', JSON.stringify(document), now, now);
      return this.getCreatorProfile(id);
    },
    getCreatorProfile(id) {
      const row = db.prepare('SELECT * FROM creator_profiles WHERE id=? OR user_id=?').get(id, id);
      return row ? { ...JSON.parse(row.document), id: row.id, userId: row.user_id,
        version: row.version, status: row.status, createdAt: row.created_at, updatedAt: row.updated_at } : null;
    },
    listCreatorProfiles() {
      return db.prepare('SELECT * FROM creator_profiles ORDER BY created_at DESC').all().map(row => ({
        ...JSON.parse(row.document), id: row.id, userId: row.user_id, version: row.version,
        status: row.status, createdAt: row.created_at, updatedAt: row.updated_at }));
    },
    reviewCreatorProfile(id, version, status, note = '') {
      const current = this.getCreatorProfile(id);
      if (!current || current.version !== version) throw new Error('CONFLICT');
      if (!['pending','approved','rejected','suspended'].includes(status)) throw new Error('INVALID_CREATOR_STATUS');
      const document = { ...current, reviewNote: note.trim(), status: undefined, id: undefined,
        userId: undefined, version: undefined, createdAt: undefined, updatedAt: undefined };
      const now = new Date().toISOString();
      db.prepare('UPDATE creator_profiles SET status=?,document=?,version=version+1,updated_at=? WHERE id=?')
        .run(status, JSON.stringify(document), now, id);
      return this.getCreatorProfile(id);
    },
    review(id, version, decision, note, rightsReference) {
      return transaction(() => {
        const current = get(id);
        if (!current || current.status !== 'draft' || current.version !== version) throw new Error('CONFLICT');
        if (decision === 'approved' && !current.clips.every(c => c.media?.inspection?.status === 'checked')) throw new Error('MEDIA_REVIEW_REQUIRED');
        current.review = { decision, note, rightsReference, reviewedAt: new Date().toISOString(), actor: 'local-admin' };
        delete current.id; delete current.status; delete current.version;
        db.prepare('UPDATE packages SET document=?,version=version+1 WHERE id=?').run(JSON.stringify(current), id);
        audit(id, `review_${decision}`); return get(id);
      });
    },
    auditLog: () => db.prepare('SELECT id,package_id,action,created_at FROM audit ORDER BY rowid DESC LIMIT 100').all(),
    setInspection(id, clipId, mediaId, inspection) {
      return transaction(() => {
        const current = get(id);
        const clip = current?.clips.find(c => c.id === clipId);
        if (current?.status !== 'draft' || clip?.media?.id !== mediaId) throw new Error('CONFLICT');
        clip.media.inspection = inspection;
        delete current.review;
        const version = current.version;
        delete current.id; delete current.status; delete current.version;
        db.prepare('UPDATE packages SET document=?,version=? WHERE id=?').run(JSON.stringify(current), version + 1, id);
        audit(id, inspection.status === 'checked' ? 'media_checked' : inspection.status === 'processing' ? 'media_check_started' : 'media_check_failed');
        return get(id);
      });
    },
    attachMedia(id, clipId, version, media) {
      return transaction(() => {
        const current = get(id);
        if (!current || current.status !== 'draft' || current.version !== version) throw new Error('CONFLICT');
        const clip = current.clips.find(c => c.id === clipId);
        if (!clip) throw new Error('CONFLICT');
        clip.media = media;
        clip.reviewStatus = 'pending';
        delete current.review;
        delete current.id; delete current.status; delete current.version;
        db.prepare('UPDATE packages SET document=?,version=version+1 WHERE id=?').run(JSON.stringify(current), id);
        audit(id, 'media_uploaded'); return get(id);
      });
    },
    list: () => db.prepare('SELECT * FROM packages ORDER BY id').all().map(decode),
    create(document, id = randomUUID()) {
      return transaction(() => {
        db.prepare('INSERT INTO packages VALUES (?,1,\'draft\',?,?)')
          .run(id, JSON.stringify(document), new Date().toISOString());
        audit(id, 'created'); return get(id);
      });
    },
    transition(id, version, next) {
      return transaction(() => {
        const current = get(id);
        if (!current) return null;
        if (current.version !== version || !(
          (current.status === 'draft' && next === 'published') ||
          (current.status === 'published' && next === 'withdrawn'))) {
          throw new Error('CONFLICT');
        }
        if (next === 'published' && !current.demo && (current.review?.decision !== 'approved'
          || !current.clips.every(c => c.media?.inspection?.status === 'checked'))) throw new Error('MEDIA_REVIEW_REQUIRED');
        db.prepare('UPDATE packages SET status=?,version=version+1 WHERE id=?').run(next, id);
        audit(id, next); return get(id);
      });
    },
    close: () => db.close(),
  };
}

export function seedDemos(store) {
  for (let i = 1; i <= 4; i++) {
    const suffix = String(i).padStart(2, '0');
    const id = `hildors_demo_${suffix}`;
    if (store.get(id)) continue;
    store.create({ title: `HILDORS ${i <= 2 ? '全息展示' : '音乐联动'} ${String(i <= 2 ? i : i - 2).padStart(2, '0')}`,
      source: 'hildors', tags: [i <= 2 ? '角色' : '音乐'], format: 'single',
      demo: true, clips: [{ id: `${id}:main`, title: '展示视频',
        bundledAsset: `assets/videos/showcase/showcase_${suffix}.mp4`,
        thumbnail: `assets/images/video_thumbnails/showcase_${suffix}.jpg`,
        durationSeconds: i === 1 ? 63 : 10, hardwareReady: false }] }, id);
    store.transition(id, 1, 'published');
  }
}
