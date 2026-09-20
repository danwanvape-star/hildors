import { randomUUID } from 'node:crypto';

export const reportReasons = ['copyright', 'abuse', 'sexual_content', 'violence', 'spam', 'other'];
export function migrateGovernance(db) {
  db.exec(`CREATE TABLE IF NOT EXISTS content_reports (
    id TEXT PRIMARY KEY,user_id TEXT NOT NULL REFERENCES users(id),package_id TEXT NOT NULL REFERENCES packages(id),
    reason TEXT NOT NULL,details TEXT NOT NULL,status TEXT NOT NULL,version INTEGER NOT NULL,
    resolution TEXT NOT NULL,created_at TEXT NOT NULL,updated_at TEXT NOT NULL);
    CREATE INDEX IF NOT EXISTS reports_user ON content_reports(user_id,created_at);
    CREATE TABLE IF NOT EXISTS creator_blocks (
    user_id TEXT NOT NULL REFERENCES users(id),creator_id TEXT NOT NULL REFERENCES creator_profiles(id),
    created_at TEXT NOT NULL,PRIMARY KEY(user_id,creator_id));`);
}
const failure = code => { throw new Error(code); };
const bounded = (value, max) => typeof value === 'string' && value.length <= max;
const publicReport = row => row && ({id:row.id,packageId:row.package_id,reason:row.reason,
  details:row.details,status:row.status,version:row.version,resolution:row.resolution,
  createdAt:row.created_at,updatedAt:row.updated_at});

export function governanceOperations(db) {
  const account = id => { if (!id || !db.prepare('SELECT 1 FROM users WHERE id=?').get(id)) failure('USER_AUTH_REQUIRED'); };
  function subject(userId, id) {
    if (!bounded(id, 120)) failure('GOVERNANCE_INVALID_INPUT');
    const row = db.prepare('SELECT * FROM packages WHERE id=?').get(id);
    if (!row) failure('GOVERNANCE_NOT_FOUND');
    const doc = JSON.parse(row.document);
    if (doc.deletedAt) failure('GOVERNANCE_NOT_FOUND');
    const owned = db.prepare("SELECT 1 FROM entitlements WHERE user_id=? AND package_id=? AND status='active'").get(userId,id);
    if (row.status !== 'published' && doc.ownerId !== userId && !owned) failure('GOVERNANCE_NOT_FOUND');
    return doc;
  }
  return {
    createContentReport(userId, value) {
      account(userId);
      if (!value || !reportReasons.includes(value.reason) || !bounded(value.details ?? '',2000)) failure('GOVERNANCE_INVALID_INPUT');
      subject(userId,value.packageId);
      const now = new Date().toISOString(), id = randomUUID();
      db.prepare('INSERT INTO content_reports VALUES (?,?,?,?,?,?,1,?,?,?)')
        .run(id,userId,value.packageId,value.reason,(value.details ?? '').trim(),'received','',now,now);
      return this.getContentReport(userId,id);
    },
    getContentReport(userId,id) {
      account(userId);
      const row = db.prepare('SELECT * FROM content_reports WHERE id=? AND user_id=?').get(id,userId);
      if (!row) failure('GOVERNANCE_NOT_FOUND');
      return publicReport(row);
    },
    listContentReports(userId) {
      account(userId);
      return db.prepare('SELECT * FROM content_reports WHERE user_id=? ORDER BY created_at DESC LIMIT 200').all(userId).map(publicReport);
    },
    adminContentReports() {
      return db.prepare('SELECT * FROM content_reports ORDER BY created_at DESC LIMIT 500').all().map(row=>({...publicReport(row),userId:row.user_id}));
    },
    resolveContentReport(id,value) {
      if (!value || !['in_review','action_taken','no_violation'].includes(value.status)
        || !Number.isInteger(value.version) || !bounded(value.resolution,2000) || !value.resolution.trim()) failure('GOVERNANCE_INVALID_INPUT');
      const changed = db.prepare('UPDATE content_reports SET status=?,resolution=?,version=version+1,updated_at=? WHERE id=? AND version=?')
        .run(value.status,value.resolution.trim(),new Date().toISOString(),id,value.version);
      if (!changed.changes) failure('GOVERNANCE_CONFLICT');
      return publicReport(db.prepare('SELECT * FROM content_reports WHERE id=?').get(id));
    },
    blockContentCreator(userId,value) {
      account(userId);
      const doc = subject(userId,value?.packageId);
      const creator = doc.ownerId && db.prepare('SELECT id,user_id FROM creator_profiles WHERE user_id=?').get(doc.ownerId);
      if (!creator || creator.user_id === userId) failure('GOVERNANCE_CREATOR_UNAVAILABLE');
      db.prepare('INSERT OR IGNORE INTO creator_blocks VALUES (?,?,?)').run(userId,creator.id,new Date().toISOString());
      return {creatorId:creator.id};
    },
    listBlockedCreators(userId) {
      account(userId);
      return db.prepare('SELECT creator_id AS creatorId,created_at AS createdAt FROM creator_blocks WHERE user_id=? ORDER BY created_at DESC').all(userId);
    },
    unblockContentCreator(userId,id) {
      account(userId);
      db.prepare('DELETE FROM creator_blocks WHERE user_id=? AND creator_id=?').run(userId,id);
      return {removed:true};
    },
  };
}

// Both auth callbacks default closed. Call after the server resolves its session.
export async function governanceRoute({req,url,store,send,fail,readJson,userId,
  authorized=()=>false,adminAuthorized=()=>false}) {
  const path=url.pathname, admin=path.startsWith('/admin/reports');
  if (!/^\/(?:v1\/me\/(?:reports|blocks)|admin\/reports)(?:\/[^/]+)?$/.test(path)) return false;
  const auth=()=>admin?adminAuthorized():Boolean(userId && authorized());
  if (!auth()) {fail(401,admin?'UNAUTHORIZED':'USER_AUTH_REQUIRED');return true;}
  try {
    const id=path.split('/')[4], adminId=path.split('/')[3];
    if (req.method==='GET') {
      if(admin) send(200,{items:store.adminContentReports()});
      else if(path.startsWith('/v1/me/reports')) send(200,id?store.getContentReport(userId,id):{items:store.listContentReports(userId)});
      else send(200,{items:store.listBlockedCreators(userId)});
    } else if (req.method==='POST') {
      const value=await readJson();
      if(!auth()) {fail(401,admin?'UNAUTHORIZED':'USER_AUTH_REQUIRED');return true;}
      if(admin && adminId) send(200,store.resolveContentReport(adminId,value));
      else if(path==='/v1/me/reports') send(201,store.createContentReport(userId,value));
      else if(path==='/v1/me/blocks') send(200,store.blockContentCreator(userId,value));
      else fail(405,'METHOD_NOT_ALLOWED');
    } else if(req.method==='DELETE' && path.startsWith('/v1/me/blocks/') && id) send(200,store.unblockContentCreator(userId,id));
    else fail(405,'METHOD_NOT_ALLOWED');
  } catch(error) {
    const status={GOVERNANCE_INVALID_INPUT:400,GOVERNANCE_NOT_FOUND:404,GOVERNANCE_CONFLICT:409,GOVERNANCE_CREATOR_UNAVAILABLE:409,USER_AUTH_REQUIRED:401}[error.message];
    if(!status) throw error;
    fail(status,error.message);
  }
  return true;
}
