import { customizationOrderOperations, assertPlanTransition } from './customization-billing.mjs';
import { customizationPlanOperations } from './customization-plans.mjs';
import { accountDeletionOperations } from './account-deletion.mjs';
import { operatorOperations } from './operators.mjs';
import { migrateGovernance, governanceOperations } from './content-governance.mjs';
import { validTranslations, validClipTranslations } from './content-localization.mjs';
import { validPricing, publicPricing } from './clip-pricing.mjs';
import { DatabaseSync } from 'node:sqlite';
import { emailIdentityOperations } from './email-identity.mjs';
import { orderEmailOutboxOperations } from './order-email-outbox.mjs';
import { randomUUID, randomBytes, createHash } from 'node:crypto';
import { orderOperations } from './order-operations.mjs';
import { creatorManagementUpdate } from './creator-management.mjs';
import { creatorContentCapabilities, creatorPricing, assertCreatorContentPricing } from './creator-content-policy.mjs';
import { creatorApplicationOperations } from './creator-application-store.mjs';
import { checkedClips, editableClip } from './package-clips.mjs';

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

export function createStore(path = ':memory:', {emailCodeSecret} = {}) {
  const db = new DatabaseSync(path);
  const needsTagSetup = !db.prepare("SELECT 1 FROM sqlite_master WHERE type='table' AND name='content_tags'").get();
  db.exec(`PRAGMA foreign_keys=ON;
    CREATE TABLE IF NOT EXISTS content_tags (id TEXT PRIMARY KEY, name TEXT NOT NULL UNIQUE, active INTEGER NOT NULL);
    CREATE TABLE IF NOT EXISTS content_tag_translations (tag_id TEXT PRIMARY KEY REFERENCES content_tags(id), document TEXT NOT NULL);
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
  migrateGovernance(db);
  if (needsTagSetup) {
    const genres = ['神话传说','东方仙侠','奇幻魔法','科幻未来','赛博朋克','历史古风','现代都市','二次元','游戏世界','童话萌宠'];
    const insertTag = db.prepare('INSERT INTO content_tags VALUES (?,?,1)');
    genres.forEach((name, index) => insertTag.run(`genre-${index + 1}`, name));
  }
  const creatorColumns = db.prepare('PRAGMA table_info(creator_profiles)').all();
  db.exec(`CREATE TABLE IF NOT EXISTS refresh_sessions (
    token_hash TEXT PRIMARY KEY,user_id TEXT NOT NULL REFERENCES users(id),expires_at INTEGER NOT NULL);
    CREATE INDEX IF NOT EXISTS refresh_sessions_user ON refresh_sessions(user_id);`);
  db.exec(`CREATE INDEX IF NOT EXISTS customization_orders_created ON customization_orders(created_at DESC,id DESC);
    CREATE INDEX IF NOT EXISTS customization_orders_user_created ON customization_orders(user_id,created_at DESC);
    CREATE INDEX IF NOT EXISTS customization_orders_status_created ON customization_orders(status,created_at DESC);
    CREATE INDEX IF NOT EXISTS customization_orders_assignee ON customization_orders(json_extract(document,'$.assignedCreatorId'));`);
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
  const tagIdsFor = (tags = [], previous = {}) => tags.map(name => {
    const index = previous.tags?.indexOf(name) ?? -1;
    return (index >= 0 ? previous.tagIds?.[index] : null) || db.prepare('SELECT id FROM content_tags WHERE name=?').get(name)?.id || null;
  });
  const decode = row => {
    if (!row) return null;
    const document = JSON.parse(row.document);
    return {...document, tagIds:document.tagIds || tagIdsFor(document.tags), id:row.id,
      contentCode:`HD-${row.id.toUpperCase()}`, version:row.version, status:row.status};
  };
  function get(id, { includeDeleted = false } = {}) {
    const item = decode(db.prepare('SELECT * FROM packages WHERE id=?').get(id));
    return item?.deletedAt && !includeDeleted ? null : item;
  }
  function audit(id, action) {
    db.prepare('INSERT INTO audit VALUES (?,?,?,?)').run(randomUUID(), id, action, new Date().toISOString());
  }
  function transaction(fn) {
    const name=`tx_${randomUUID().replaceAll('-','')}`;
    db.exec(`SAVEPOINT ${name}`);
    try { const result = fn(); db.exec(`RELEASE ${name}`); return result; }
    catch (error) { db.exec(`ROLLBACK TO ${name}; RELEASE ${name}`); throw error; }
  }
  return {
    ...operatorOperations(db),
    ...emailIdentityOperations(db,{codeSecret:emailCodeSecret}),
    ...orderEmailOutboxOperations(db),
    ...orderOperations(db),
    ...governanceOperations(db),
    ...accountDeletionOperations(db),
    ...customizationPlanOperations(db),
    ...customizationOrderOperations(db),
    ...creatorApplicationOperations(db),
    get,
    updateClipPricing(id, clipId, version, pricing) {
      if (!validPricing(pricing)) throw new Error('INVALID_PRICING');
      return transaction(() => {
        const current = get(id), clip = current?.clips.find(c => c.id === clipId);
        if (!clip || current.version !== version) throw new Error('CONFLICT');
        if (current.ownerId) creatorPricing(this.getCreatorProfile(current.ownerId), pricing);
        clip.pricing = publicPricing(pricing);
        delete current.id; delete current.version; delete current.status;
        db.prepare('UPDATE packages SET document=?,version=version+1 WHERE id=?').run(JSON.stringify(current), id);
        audit(id, 'clip_pricing_updated:' + clipId); return get(id);
      });
    },
    contentTags: () => db.prepare('SELECT t.id,t.name,t.active,l.document FROM content_tags t LEFT JOIN content_tag_translations l ON l.tag_id=t.id ORDER BY t.rowid').all()
      .map(({document,...tag}) => ({...tag,active:Boolean(tag.active),...(document ? {translations:JSON.parse(document)} : {})})),
    updateCreatorClipPricing(userId, id, clipId, version, pricing) {
      return transaction(() => {
        const current = get(id), clip = current?.clips.find(c => c.id === clipId);
        if (!clip || current.ownerId !== userId || current.version !== version || current.status !== 'draft'
          || !['draft','rejected'].includes(current.submissionStatus)) throw new Error('CONFLICT');
        const profile = this.getCreatorProfile(userId);
        if (!creatorContentCapabilities(profile).canUpload) throw new Error('CREATOR_APPROVAL_REQUIRED');
        clip.pricing = creatorPricing(profile, pricing);
        current.submissionStatus = 'draft'; delete current.review;
        delete current.id; delete current.version; delete current.status;
        db.prepare('UPDATE packages SET document=?,version=version+1 WHERE id=?').run(JSON.stringify(current), id);
        audit(id, 'creator_clip_pricing_updated:' + clipId); return get(id);
      });
    },
    saveContentTags(items) {
      if (!Array.isArray(items) || items.length > 200 || items.some(x => !x || !validTranslations(x.translations, {name:32}) || typeof x.name !== 'string' || !x.name.trim() || x.name.trim().length > 32 || typeof x.active !== 'boolean' || (x.id !== undefined && (typeof x.id !== 'string' || !/^[a-zA-Z0-9_-]{1,100}$/.test(x.id))))
        || new Set(items.map(x => x.name.trim())).size !== items.length || new Set(items.filter(x => x.id).map(x => x.id)).size !== items.filter(x => x.id).length) throw new Error('INVALID_CONTENT_TAGS');
      return transaction(() => {
        const existing = this.contentTags();
        if (items.some(value => value.id && existing.some(tag => tag.name === value.name.trim() && tag.id !== value.id))) throw new Error('INVALID_CONTENT_TAGS');
        db.prepare('UPDATE content_tags SET active=0').run();
        for (const value of items) {
          const previous = existing.find(x => x.id === value.id);
          const id = value.id ?? existing.find(x => x.name === value.name.trim())?.id ?? randomUUID();
          // A rename preserves the old selection as a disabled legacy name.
          if (previous && previous.name !== value.name.trim()) {
            // Freeze IDs before preserving the renamed legacy string as an alias.
            for (const item of this.list()) {
              if (item.tags?.includes(previous.name)) {
                const {id:packageId,version,status,contentCode,...document}=item;
                db.prepare('UPDATE packages SET document=? WHERE id=?').run(JSON.stringify(document),packageId);
              }
            }
            db.prepare('UPDATE content_tags SET name=? WHERE id=?').run(value.name.trim(), id);
            db.prepare('INSERT INTO content_tags VALUES (?,?,0)').run(randomUUID(), previous.name);
          }
          db.prepare('INSERT INTO content_tags VALUES (?,?,?) ON CONFLICT(id) DO UPDATE SET name=excluded.name,active=excluded.active')
            .run(id, value.name.trim(), Number(value.active));
          if (value.translations !== undefined) db.prepare('INSERT INTO content_tag_translations VALUES (?,?) ON CONFLICT(tag_id) DO UPDATE SET document=excluded.document').run(id,JSON.stringify(value.translations));
        }
        return this.contentTags();
      });
    },
    updateMetadata(id, version, metadata) {
      return transaction(() => {
        const current = get(id);
        if (!current || current.version !== version || (current.ownerId && (current.status !== 'draft' || !['draft','rejected'].includes(current.submissionStatus)))) throw new Error('CONFLICT');
        if (!validTranslations(metadata.translations) || !validClipTranslations(metadata.clipTranslations)) throw new Error('INVALID_PACKAGE');
        const {clipTranslations, ...fields} = metadata;
        for (const entry of clipTranslations || []) {
          const clip = current.clips.find(c => c.id === entry.id);
          if (!clip) throw new Error('INVALID_PACKAGE');
          if (entry.translations !== undefined) clip.translations = entry.translations;
        }
        fields.tagIds = tagIdsFor(fields.tags || current.tags, current);
        Object.assign(current, fields);
        if (current.status === 'draft') { delete current.review; if (current.ownerId) current.submissionStatus = 'draft'; }
        delete current.id; delete current.version; delete current.status;
        db.prepare('UPDATE packages SET document=?,version=version+1 WHERE id=?').run(JSON.stringify(current), id);
        audit(id, 'metadata_updated'); return get(id);
      });
    },
    submitContent(id, version) {
      return transaction(() => {
        const current = get(id);
        if (!current || !current.ownerId || current.status !== 'draft' || current.version !== version || !['draft','rejected'].includes(current.submissionStatus)) throw new Error('CONFLICT');
        if (!current.description?.trim()) throw new Error('INVALID_PACKAGE');
        assertCreatorContentPricing(this, current);
        for (const clip of current.clips) clip.pricing = creatorPricing(this.getCreatorProfile(current.ownerId), clip.pricing);
        if (!current.tags.every(name => this.contentTags().some(x => x.active && x.name === name))) throw new Error('INVALID_CONTENT_TAGS');
        if (!checkedClips(current)) throw new Error('MEDIA_REVIEW_REQUIRED');
        if (current.format === 'package' && !current.cover) throw new Error('PACKAGE_COVER_REQUIRED');
        current.submissionStatus = 'pending'; delete current.review;
        delete current.id; delete current.version; delete current.status;
        db.prepare('UPDATE packages SET document=?,version=version+1 WHERE id=?').run(JSON.stringify(current), id);
        audit(id, 'submitted'); return get(id);
      });
    },
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
    createDeviceSession(userId) {
      const refreshToken=randomBytes(32).toString('base64url'),refreshExpiresIn=180*86400;
      return transaction(()=>{
        const token=this.createSession(userId,86400);
        db.prepare('INSERT INTO refresh_sessions VALUES (?,?,?)').run(tokenHash(refreshToken),userId,Date.now()+refreshExpiresIn*1000);
        return {token,expiresIn:86400,refreshToken,refreshExpiresIn};
      });
    },
    refreshDeviceSession(refreshToken) {
      if(typeof refreshToken!=='string'||!/^[A-Za-z0-9_-]{43}$/.test(refreshToken)) return null;
      const row=db.prepare('SELECT user_id,expires_at FROM refresh_sessions WHERE token_hash=? AND expires_at>?').get(tokenHash(refreshToken),Date.now());
      if(!row) return null;
      return {token:this.createSession(row.user_id,86400),expiresIn:86400,refreshToken,refreshExpiresIn:Math.floor((row.expires_at-Date.now())/1000)};
    },
    revokeSession(token) {
      const row=db.prepare('SELECT user_id FROM sessions WHERE token_hash=?').get(tokenHash(token));
      transaction(()=>{
        if(row) {db.prepare('DELETE FROM refresh_sessions WHERE user_id=?').run(row.user_id);db.prepare('DELETE FROM sessions WHERE user_id=?').run(row.user_id);}
      });
    },
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
      return db.prepare(`SELECT e.package_id,e.status FROM entitlements e JOIN packages p ON p.id=e.package_id
        WHERE e.user_id=? AND json_extract(p.document,'$.deletedAt') IS NULL ORDER BY e.package_id`).all(userId);
    },
    createCustomizationOrder(userId, document) {
      if(document.clientRequestId) { const existing=this.findOrderRequest(userId,document.clientRequestId); if(existing) return existing; }
      if(document.planId!==undefined){
        const plan=this.customizationPlans().find(p=>p.id===document.planId&&p.listed);
        if(!plan||plan.version!==document.planVersion)throw new Error('PLAN_CONFLICT');
        document={...document,planSnapshot:this.customizationPlanSnapshot(plan.id,document.audioMode),privacy:'private',payment:{status:'unpaid'}};
      }
      const account=this.emailAccount(userId);
      document={...document,verifiedContactEmail:account.emailVerified?account.email:null};
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
      assertPlanTransition(current,status);
      if(current.planSnapshot&&status==='delivered')throw new Error('ORDER_USER_CONFIRMATION_REQUIRED');
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
      if(!fields || typeof fields!=='object' || Array.isArray(fields) || typeof note!=='string' || note.length>1000) throw new Error('ORDER_INVALID_FIELDS');
      const current = this.getCustomizationOrder(id);
      if (!current || current.version !== version) throw new Error('CONFLICT');
      if(current.legacyRecoveryAt && status==='approved_for_quote' && !(current.materials?.length>=Math.max(1,current.materialCount??1))) throw new Error('ORDER_MATERIAL_REQUIRED');
      if(current.legacyRecoveryAt && status==='quoted' && !current.assignedCreatorId) throw new Error('ORDER_CREATOR_REQUIRED');
      if(current.dispatchMode && status==='in_production' && current.status==='quoted') throw new Error('ORDER_USER_CONFIRMATION_REQUIRED');
      if(current.dispatchMode && status==='delivered') throw new Error('ORDER_USER_CONFIRMATION_REQUIRED');
      if((['needs_info','rejected','withdrawn'].includes(status)
        || (current.status==='quality_review' && status==='in_production')
        || (current.status==='user_acceptance' && status==='quality_review')) && !note.trim()) throw new Error('ORDER_NOTE_REQUIRED');
      if(current.dispatchMode && status==='quoted' && !current.assignedCreatorId) throw new Error('ORDER_CREATOR_REQUIRED');
      if(current.dispatchMode && status==='quoted' && !current.creatorQuote) throw new Error('ORDER_QUOTE_PROPOSAL_REQUIRED');
      if(current.dispatchMode && status==='user_acceptance' && !fields.deliveryReference) throw new Error('ORDER_DELIVERY_REQUIRED');
      const transitions = { free_review: ['needs_info','approved_for_quote','rejected'], needs_info: ['free_review','approved_for_quote','rejected'],
        approved_for_quote: ['quoted','needs_info','rejected'], quoted: ['in_production','needs_info','withdrawn'],
        in_production: ['quality_review'], quality_review: ['in_production','user_acceptance'],
        user_acceptance: ['quality_review','delivered'], delivered: [], rejected: ['free_review'], withdrawn: [] };
      if (status !== current.status && !transitions[current.status]?.includes(status)) throw new Error('INVALID_ORDER_TRANSITION');
      const clean = value => typeof value === 'string' ? value.trim() : value;
      const patch = Object.fromEntries(Object.entries(fields ?? {}).map(([key, value]) => [key, clean(value)]));
      if(current.dispatchMode && ['in_production','quality_review'].includes(status)) {patch.qcPassed=false;patch.deliveryReference=null;}
      if (status === 'quoted' && (!Number.isFinite(Number(patch.quoteAmount)) || !(Number(patch.quoteAmount) > 0) || Number(patch.quoteAmount)>1000000 || !['USD','CNY','EUR','GBP','JPY','HKD'].includes(patch.currency) || !Number.isInteger(Number(patch.deliveryDays)) || !(Number(patch.deliveryDays) > 0) || Number(patch.deliveryDays)>365)) throw new Error('ORDER_QUOTE_REQUIRED');
      if (status === 'in_production' && (!patch.assignee || !patch.dueAt)) throw new Error('ORDER_PRODUCTION_REQUIRED');
      if (status === 'quality_review' && !patch.deliverableReference) throw new Error('ORDER_DELIVERABLE_REQUIRED');
      if (status === 'user_acceptance' && patch.qcPassed !== true) throw new Error('ORDER_QC_REQUIRED');
      if (status === 'delivered' && !patch.deliveryReference) throw new Error('ORDER_DELIVERY_REQUIRED');
      return transaction(() => {
      const next = this.updateCustomizationOrder(id, version, status, note);
      const document = { ...next, workflow: { ...(current.workflow ?? {}), ...patch }, status: undefined, id: undefined,
        userId: undefined, version: undefined, createdAt: undefined, updatedAt: undefined };
      db.prepare('UPDATE customization_orders SET document=?,version=version+1,updated_at=? WHERE id=?')
        .run(JSON.stringify(document), new Date().toISOString(), id);
      return this.getCustomizationOrder(id);
      });
    },
    upsertCreatorProfile(userId, document) {
      const email = String(document.email ?? '').trim().toLowerCase();
      if (!email) throw new Error('INVALID_CREATOR_PROFILE');
      const owner = db.prepare('SELECT user_id FROM creator_profiles WHERE email_normalized=?').get(email);
      if (owner && owner.user_id !== userId) throw new Error('EMAIL_IN_USE');
      const previous = this.getCreatorProfile(userId);
      if (previous?.applicationVersion === 2) throw new Error('CREATOR_APPLICATION_MIGRATION_REQUIRED');
      document = { ...document, email, management: previous?.management, managementHistory: previous?.managementHistory,
        reviewNote: previous?.reviewNote, abilityLevel: previous?.abilityLevel };
      const existing = db.prepare('SELECT id FROM creator_profiles WHERE user_id=?').get(userId);
      const now = new Date().toISOString(), id = existing?.id ?? randomUUID();
      if (existing) db.prepare('UPDATE creator_profiles SET document=?,email_normalized=?,status=?,version=version+1,updated_at=? WHERE id=?')
        .run(JSON.stringify(document), email, ['approved', 'suspended'].includes(previous?.status) ? previous.status : 'pending', now, id);
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
      if (current.applicationVersion === 2) return this.manageCreatorProfile(id, version, {status, note});
      if (!['pending','approved','rejected','suspended'].includes(status)) throw new Error('INVALID_CREATOR_STATUS');
      const document = { ...current, reviewNote: note.trim(), status: undefined, id: undefined,
        userId: undefined, version: undefined, createdAt: undefined, updatedAt: undefined };
      const now = new Date().toISOString();
      db.prepare('UPDATE creator_profiles SET status=?,document=?,version=version+1,updated_at=? WHERE id=?')
        .run(status, JSON.stringify(document), now, id);
      return this.getCreatorProfile(id);
    },
    manageCreatorProfile(id, version, value, actor = 'system') {
      const current = this.getCreatorProfile(id);
      if (!current || current.version !== version) throw new Error('CONFLICT');
      const document = { ...current, ...creatorManagementUpdate(current, value, actor),
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
        if (current.ownerId && current.submissionStatus !== 'pending') throw new Error('CONFLICT');
        if (decision === 'approved') assertCreatorContentPricing(this, current);
        if (decision === 'approved' && !checkedClips(current)) throw new Error('MEDIA_REVIEW_REQUIRED');
        if (current.ownerId) current.submissionStatus = decision;
        current.review = { id: randomUUID(), decision, note, rightsReference, reviewedAt: new Date().toISOString(), actor: 'local-admin' };
        delete current.id; delete current.status; delete current.version;
        db.prepare('UPDATE packages SET document=?,version=version+1 WHERE id=?').run(JSON.stringify(current), id);
        audit(id, `review_${decision}`); return get(id);
      });
    },
    auditLog: () => db.prepare('SELECT id,package_id,action,created_at FROM audit ORDER BY rowid DESC LIMIT 100').all(),
    appendClip(id, version, title, media) {
      return transaction(() => {
        const current = get(id);
        if (!current || current.format !== 'package' || current.ownerId || !['draft','published'].includes(current.status)
          || current.version !== version || current.clips.filter(c => c.media).length >= 100) throw new Error('CONFLICT');
        current.clips = current.clips.filter(c => c.media);
        current.clips.push({ id: randomUUID(), title, media, hardwareReady: false,
          ...(current.status === 'published' ? { visibility: 'draft' } : {}) });
        if (current.status === 'draft') delete current.review;
        delete current.id; delete current.status; delete current.version;
        db.prepare('UPDATE packages SET document=?,version=version+1 WHERE id=?').run(JSON.stringify(current), id);
        audit(id, 'clip_added'); return get(id);
      });
    },
    transitionClip(id, clipId, version, next, review) {
      return transaction(() => {
        const current = get(id), clip = current?.clips.find(c => c.id === clipId);
        if (!clip?.media || current.format !== 'package' || current.version !== version
          || !['draft','published','withdrawn'].includes(current.status) || (current.ownerId && current.status === 'draft')) throw new Error('CONFLICT');
        if (next === 'restored') {
          if (!['draft','withdrawn'].includes(current.status) || clip.visibility !== 'withdrawn') throw new Error('CONFLICT');
        } else if (next === 'published') {
          if (current.status !== 'published' || !['draft','withdrawn'].includes(clip.visibility)) throw new Error('CONFLICT');
          if (current.governance?.hold) throw new Error('CONTENT_GOVERNANCE_HOLD');
          assertCreatorContentPricing(this, {...current, clips: [clip]});
          if (clip.media.inspection?.status !== 'checked') throw new Error('MEDIA_REVIEW_REQUIRED');
          clip.review = { ...review, id: randomUUID(), actor: 'local-admin', reviewedAt: new Date().toISOString() };
        } else if (next !== 'withdrawn' || clip.visibility === 'withdrawn') throw new Error('CONFLICT');
        // Withdrawal must retain whether this clip was actually published. A package's
        // older approval does not cover drafts appended after its initial publication.
        if (next === 'withdrawn') clip.visibilityBeforeWithdrawal = current.status === 'draft' ? 'draft' : (clip.visibility || 'published');
        if (next === 'restored') {
          if (current.status === 'draft') delete clip.visibility;
          else clip.visibility = clip.visibilityBeforeWithdrawal === 'published' ? 'published' : 'draft';
          delete clip.visibilityBeforeWithdrawal;
        } else {
          clip.visibility = next;
          if (next === 'published') delete clip.visibilityBeforeWithdrawal;
        }
        if (current.status === 'draft') delete current.review;
        delete current.id; delete current.status; delete current.version;
        db.prepare('UPDATE packages SET document=?,version=version+1 WHERE id=?').run(JSON.stringify(current), id);
        audit(id, `clip_${next}:${clipId}`); return get(id);
      });
    },
    setInspection(id, clipId, mediaId, inspection) {
      return transaction(() => {
        const current = get(id);
        const clip = current?.clips.find(c => c.id === clipId);
        if (!editableClip(current, clip) || clip?.media?.id !== mediaId) throw new Error('CONFLICT');
        if (current.ownerId && !['draft','rejected'].includes(current.submissionStatus)) throw new Error('CONFLICT');
        clip.media.inspection = inspection;
        if (current.status === 'draft') delete current.review;
        else { if (inspection.status === 'processing' || clip.visibility !== 'withdrawn') clip.visibility = 'draft'; delete clip.review; delete clip.visibilityBeforeWithdrawal; }
        if (current.ownerId) current.submissionStatus = 'draft';
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
        if (!current || current.version !== version) throw new Error('CONFLICT');
        if (current.ownerId && !['draft','rejected'].includes(current.submissionStatus)) throw new Error('CONFLICT');
        const clip = current.clips.find(c => c.id === clipId);
        if (!editableClip(current, clip)) throw new Error('CONFLICT');
        clip.media = media;
        clip.reviewStatus = 'pending';
        if (current.status === 'draft') delete current.review;
        else { clip.visibility = 'draft'; delete clip.review; }
        if (current.ownerId) current.submissionStatus = 'draft';
        delete current.id; delete current.status; delete current.version;
        db.prepare('UPDATE packages SET document=?,version=version+1 WHERE id=?').run(JSON.stringify(current), id);
        audit(id, 'media_uploaded'); return get(id);
      });
    },
    attachCover(id, version, cover) {
      return transaction(() => {
        const current = get(id);
        if (!current || current.status !== 'draft' || current.version !== version || current.format !== 'package') throw new Error('CONFLICT');
        if (current.ownerId && !['draft','rejected'].includes(current.submissionStatus)) throw new Error('CONFLICT');
        current.cover = cover; delete current.review;
        if (current.ownerId) current.submissionStatus = 'draft';
        delete current.id; delete current.status; delete current.version;
        db.prepare('UPDATE packages SET document=?,version=version+1 WHERE id=?').run(JSON.stringify(current), id);
        audit(id, 'cover_uploaded'); return get(id);
      });
    },
    list: ({ includeDeleted = false } = {}) => db.prepare('SELECT * FROM packages ORDER BY id').all().map(decode)
      .filter(item => includeDeleted || !item.deletedAt),
    deletePackage(id, version) {
      return transaction(() => {
        const current = get(id, { includeDeleted: true });
        if (!current || current.deletedAt || current.version !== version || current.status === 'published') throw new Error('CONFLICT');
        current.deletedAt = new Date().toISOString();
        delete current.id; delete current.status; delete current.version;
        db.prepare('UPDATE packages SET document=?,version=version+1 WHERE id=?').run(JSON.stringify(current), id);
        audit(id, 'deleted'); return get(id, { includeDeleted: true });
      });
    },
    restorePackage(id, version) {
      return transaction(() => {
        const current = get(id, { includeDeleted: true });
        if (!current?.deletedAt || current.version !== version) throw new Error('CONFLICT');
        const status = current.status === 'draft' ? 'draft' : 'withdrawn';
        delete current.deletedAt;
        current.restoredAt = new Date().toISOString();
        delete current.id; delete current.status; delete current.version;
        db.prepare('UPDATE packages SET status=?,document=?,version=version+1 WHERE id=?').run(status, JSON.stringify(current), id);
        audit(id, 'restored'); return get(id);
      });
    },
    create(document, id = randomUUID()) {
      if (!validTranslations(document.translations) || document.clips?.some(c => !validTranslations(c.translations))) throw new Error('INVALID_PACKAGE');
      document = {...document, tagIds:tagIdsFor(document.tags)};
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
          (['draft','withdrawn'].includes(current.status) && next === 'published') ||
          (current.status === 'published' && next === 'withdrawn'))) {
          throw new Error('CONFLICT');
        }
        if (next === 'published' && !current.demo && (current.review?.decision !== 'approved'
          || !checkedClips(current))) throw new Error('MEDIA_REVIEW_REQUIRED');
        if (next === 'published' && current.governance?.hold) throw new Error('CONTENT_GOVERNANCE_HOLD');
        if (next === 'published') assertCreatorContentPricing(this, current);
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
    if (store.get(id, { includeDeleted: true })) continue;
    store.create({ title: `HILDORS ${i <= 2 ? '全息展示' : '音乐联动'} ${String(i <= 2 ? i : i - 2).padStart(2, '0')}`,
      source: 'hildors', tags: [i <= 2 ? '角色' : '音乐'], format: 'single',
      demo: true, clips: [{ id: `${id}:main`, title: '展示视频',
        bundledAsset: `assets/videos/showcase/showcase_${suffix}.mp4`,
        thumbnail: `assets/images/video_thumbnails/showcase_${suffix}.jpg`,
        durationSeconds: i === 1 ? 63 : 10, hardwareReady: false }] }, id);
    store.transition(id, 1, 'published');
  }
}
