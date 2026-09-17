import { DatabaseSync } from 'node:sqlite';
import { randomUUID, randomBytes, createHash } from 'node:crypto';

const defaultLayout = () => ({
  schemaVersion: 1,
  pages: {
    collection: [
      { id: 'collection-hildors', type: 'hildors', title: 'HILDORS 出品', visible: true, columns: 3 },
      { id: 'collection-creators', type: 'creators', title: '创作者作品', visible: true, columns: 3 },
    ],
    discover: [
      { id: 'discover-customization', type: 'customization', title: '定制你的专属角色', visible: true, columns: 1 },
      { id: 'discover-portal', type: 'character_portal', title: 'Character Portal', visible: true, columns: 2 },
      { id: 'discover-creator', type: 'creator_join', title: '加入创作者计划', visible: true, columns: 1 },
    ],
  },
});

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
      status TEXT NOT NULL, document TEXT NOT NULL, email_normalized TEXT,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS app_layouts (
      id TEXT PRIMARY KEY, version INTEGER NOT NULL, draft TEXT NOT NULL, published TEXT NOT NULL,
      previous_published TEXT, updated_at TEXT NOT NULL);`);
  const creatorColumns = db.prepare('PRAGMA table_info(creator_profiles)').all();
  if (!creatorColumns.some(column => column.name === 'email_normalized')) {
    db.exec('ALTER TABLE creator_profiles ADD COLUMN email_normalized TEXT');
  }
  db.exec(`CREATE UNIQUE INDEX IF NOT EXISTS creator_profiles_email_unique
    ON creator_profiles(email_normalized) WHERE email_normalized IS NOT NULL;`);
  const initialLayout = JSON.stringify(defaultLayout());
  db.prepare('INSERT OR IGNORE INTO app_layouts VALUES (?,?,?,?,?,?)')
    .run('main', 1, initialLayout, initialLayout, null, new Date().toISOString());
  const layoutRow = db.prepare('SELECT draft,published,previous_published FROM app_layouts WHERE id=?').get('main');
  const withoutFeatured = raw => {
    if (!raw) return raw;
    const value = JSON.parse(raw);
    value.pages.collection = (value.pages.collection ?? []).filter(block => block.type !== 'featured');
    return JSON.stringify(value);
  };
  db.prepare('UPDATE app_layouts SET draft=?,published=?,previous_published=? WHERE id=?')
    .run(withoutFeatured(layoutRow.draft), withoutFeatured(layoutRow.published),
      withoutFeatured(layoutRow.previous_published), 'main');
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
      const transitions = {
        free_review: ['needs_info','approved_for_quote','rejected'],
        needs_info: ['free_review','approved_for_quote','rejected'],
        approved_for_quote: ['quoted','needs_info','rejected'],
        quoted: ['in_production','needs_info','withdrawn'],
        in_production: ['quality_review'],
        quality_review: ['in_production','user_acceptance'],
        user_acceptance: ['quality_review','delivered'],
        delivered: [], rejected: ['free_review'], withdrawn: [],
      };
      if (status !== current.status && !transitions[current.status]?.includes(status)) throw new Error('INVALID_ORDER_TRANSITION');
      const now = new Date().toISOString();
      const history = Array.isArray(current.workflowHistory) ? [...current.workflowHistory] : [];
      if (status !== current.status || note.trim()) history.push({ from: current.status, to: status, note: note.trim(), at: now, actor: 'admin' });
      const document = { ...current, adminNote: note.trim(), workflowHistory: history, status: undefined, id: undefined,
        userId: undefined, version: undefined, createdAt: undefined, updatedAt: undefined };
      db.prepare('UPDATE customization_orders SET status=?,document=?,version=version+1,updated_at=? WHERE id=?')
        .run(status, JSON.stringify(document), now, id);
      return this.getCustomizationOrder(id);
    },
    updateCustomizationOrderWorkflow(id, version, status, note = '', fields = {}) {
      const current = this.getCustomizationOrder(id);
      if (!current || current.version !== version) throw new Error('CONFLICT');
      const transitions = { free_review: ['needs_info','approved_for_quote','rejected'], needs_info: ['free_review','approved_for_quote','rejected'],
        approved_for_quote: ['quoted','needs_info','rejected'], quoted: ['in_production','needs_info','withdrawn'],
        in_production: ['quality_review'], quality_review: ['in_production','user_acceptance'],
        user_acceptance: ['quality_review','delivered'], delivered: [], rejected: ['free_review'], withdrawn: [] };
      if (status !== current.status && !transitions[current.status]?.includes(status)) throw new Error('INVALID_ORDER_TRANSITION');
      const clean = value => typeof value === 'string' ? value.trim() : value;
      const patch = Object.fromEntries(Object.entries(fields ?? {}).map(([key, value]) => [key, clean(value)]));
      if (status === 'quoted' && (!(Number(patch.quoteAmount) > 0) || !patch.currency || !(Number(patch.deliveryDays) > 0))) throw new Error('ORDER_QUOTE_REQUIRED');
      if (status === 'in_production' && (!patch.assignee || !patch.dueAt)) throw new Error('ORDER_PRODUCTION_REQUIRED');
      if (status === 'quality_review' && !patch.deliverableReference) throw new Error('ORDER_DELIVERABLE_REQUIRED');
      if (status === 'user_acceptance' && patch.qcPassed !== true) throw new Error('ORDER_QC_REQUIRED');
      if (status === 'delivered' && !patch.deliveryReference) throw new Error('ORDER_DELIVERY_REQUIRED');
      const next = this.updateCustomizationOrder(id, version, status, note);
      const document = { ...next, workflow: { ...(current.workflow ?? {}), ...patch }, status: undefined, id: undefined,
        userId: undefined, version: undefined, createdAt: undefined, updatedAt: undefined };
      db.prepare('UPDATE customization_orders SET document=?,version=version+1,updated_at=? WHERE id=?')
        .run(JSON.stringify(document), new Date().toISOString(), id);
      return this.getCustomizationOrder(id);
    },
    upsertCreatorProfile(userId, document) {
      const email = String(document.email ?? '').trim().toLowerCase();
      if (!email) throw new Error('INVALID_CREATOR_PROFILE');
      const owner = db.prepare('SELECT user_id FROM creator_profiles WHERE email_normalized=?').get(email);
      if (owner && owner.user_id !== userId) throw new Error('EMAIL_IN_USE');
      document = { ...document, email };
      const existing = db.prepare('SELECT id FROM creator_profiles WHERE user_id=?').get(userId);
      const now = new Date().toISOString(), id = existing?.id ?? randomUUID();
      if (existing) db.prepare('UPDATE creator_profiles SET document=?,email_normalized=?,status=?,version=version+1,updated_at=? WHERE id=?')
        .run(JSON.stringify(document), email, 'pending', now, id);
      else db.prepare(`INSERT INTO creator_profiles
        (id,user_id,version,status,document,email_normalized,created_at,updated_at)
        VALUES (?,?,1,?,?,?,?,?)`)
        .run(id, userId, 'pending', JSON.stringify(document), email, now, now);
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
    manageCreatorProfile(id, version, value) {
      const current = this.getCreatorProfile(id);
      if (!current || current.version !== version) throw new Error('CONFLICT');
      if (!['pending','approved','rejected','suspended'].includes(value.status)) throw new Error('INVALID_CREATOR_STATUS');
      const commissionRate = Number(value.commissionRate ?? 0);
      if (!Number.isFinite(commissionRate) || commissionRate < 0 || commissionRate > 100) throw new Error('INVALID_CREATOR_PROFILE');
      const management = { tier: String(value.tier ?? 'standard').trim(), commissionRate,
        manager: String(value.manager ?? '').trim(), canPublish: value.canPublish === true,
        identityVerified: value.identityVerified === true, agreementSigned: value.agreementSigned === true,
        payoutReady: value.payoutReady === true, note: String(value.note ?? '').trim() };
      const history = Array.isArray(current.managementHistory) ? [...current.managementHistory] : [];
      history.push({ at: new Date().toISOString(), status: value.status, manager: management.manager, note: management.note });
      const document = { ...current, management, managementHistory: history, reviewNote: management.note,
        status: undefined, id: undefined, userId: undefined, version: undefined, createdAt: undefined, updatedAt: undefined };
      const now = new Date().toISOString();
      db.prepare('UPDATE creator_profiles SET status=?,document=?,version=version+1,updated_at=? WHERE id=?')
        .run(value.status, JSON.stringify(document), now, id);
      return this.getCreatorProfile(id);
    },
    getLayout() {
      const row = db.prepare('SELECT * FROM app_layouts WHERE id=?').get('main');
      return { version: row.version, draft: JSON.parse(row.draft), published: JSON.parse(row.published),
        canRollback: Boolean(row.previous_published), updatedAt: row.updated_at };
    },
    saveLayoutDraft(version, document) {
      const current = this.getLayout();
      if (current.version !== version) throw new Error('CONFLICT');
      db.prepare('UPDATE app_layouts SET draft=?,version=version+1,updated_at=? WHERE id=?')
        .run(JSON.stringify(document), new Date().toISOString(), 'main');
      return this.getLayout();
    },
    publishLayout(version) {
      const current = this.getLayout();
      if (current.version !== version) throw new Error('CONFLICT');
      db.prepare('UPDATE app_layouts SET previous_published=published,published=draft,version=version+1,updated_at=? WHERE id=?')
        .run(new Date().toISOString(), 'main');
      return this.getLayout();
    },
    rollbackLayout(version) {
      const current = this.getLayout();
      if (current.version !== version || !current.canRollback) throw new Error('CONFLICT');
      db.prepare('UPDATE app_layouts SET draft=previous_published,published=previous_published,previous_published=published,version=version+1,updated_at=? WHERE id=?')
        .run(new Date().toISOString(), 'main');
      return this.getLayout();
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
    attachCover(id, version, cover) {
      return transaction(() => {
        const current = get(id);
        if (!current || current.status !== 'draft' || current.version !== version || current.format !== 'package') throw new Error('CONFLICT');
        current.cover = cover; delete current.review;
        delete current.id; delete current.status; delete current.version;
        db.prepare('UPDATE packages SET document=?,version=version+1 WHERE id=?').run(JSON.stringify(current), id);
        audit(id, 'cover_uploaded'); return get(id);
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
    updateMetadata(id, version, metadata) {
      return transaction(() => {
        const current = get(id);
        if (!current || current.version !== version) throw new Error('CONFLICT');
        if (metadata.description) current.description = metadata.description;
        else delete current.description;
        if (current.source === 'creator' && metadata.creator) current.creator = metadata.creator;
        else delete current.creator;
        delete current.id; delete current.status; delete current.version;
        db.prepare('UPDATE packages SET document=?,version=version+1 WHERE id=?')
          .run(JSON.stringify(current), id);
        audit(id, 'metadata_updated'); return get(id);
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
        if (next === 'published' && current.format === 'package' && !current.cover && !current.demo) throw new Error('PACKAGE_COVER_REQUIRED');
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
