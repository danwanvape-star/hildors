import {randomUUID} from 'node:crypto';
const fail = code => {throw new Error(code);};
const view = row => row && ({id:row.id,status:row.status,version:row.version,message:row.message,createdAt:row.created_at,updatedAt:row.updated_at});
export function accountDeletionOperations(db) {
 db.exec(`CREATE TABLE IF NOT EXISTS account_deletion_requests (
 id TEXT PRIMARY KEY,user_id TEXT NOT NULL UNIQUE REFERENCES users(id),
 status TEXT NOT NULL CHECK(status IN ('received','in_review','needs_information','cancelled')),
 version INTEGER NOT NULL,message TEXT NOT NULL,created_at TEXT NOT NULL,updated_at TEXT NOT NULL);`);
 const get = userId => db.prepare('SELECT * FROM account_deletion_requests WHERE user_id=?').get(userId);
 const account = userId => {if(!userId || !db.prepare('SELECT 1 FROM users WHERE id=?').get(userId))fail('USER_AUTH_REQUIRED');};
 return {
  accountDeletionRequest(userId) {account(userId);return view(get(userId)) ?? null;},
  requestAccountDeletion(userId,value) {
   account(userId);
   if(value?.confirm!==true)fail('DELETION_INVALID_INPUT');
   const previous=get(userId), now=new Date().toISOString();
   if(previous && previous.status!=='cancelled')return view(previous);
   if(previous)db.prepare("UPDATE account_deletion_requests SET status='received',version=version+1,message='',created_at=?,updated_at=? WHERE user_id=?").run(now,now,userId);
   else db.prepare('INSERT INTO account_deletion_requests VALUES (?,?,?,1,?,?,?)').run(randomUUID(),userId,'received','',now,now);
   return view(get(userId));
  },
  cancelAccountDeletion(userId,value) {
   account(userId);
   if(!Number.isSafeInteger(value?.version))fail('DELETION_INVALID_INPUT');
   const changed=db.prepare("UPDATE account_deletion_requests SET status='cancelled',version=version+1,message='',updated_at=? WHERE user_id=? AND version=? AND status!='cancelled'")
     .run(new Date().toISOString(),userId,value.version);
   if(!changed.changes)fail('DELETION_CONFLICT');
   return view(get(userId));
  },
  adminAccountDeletions() {return db.prepare('SELECT * FROM account_deletion_requests ORDER BY updated_at DESC LIMIT 500').all().map(r=>({...view(r),userId:r.user_id}));},
  reviewAccountDeletion(id,value) {
   const message=value?.message ?? '';
   if(!['in_review','needs_information'].includes(value?.status) || !Number.isSafeInteger(value?.version)
     || typeof message!=='string' || message.length>2000 || (value.status==='needs_information'&&!message.trim()))fail('DELETION_INVALID_INPUT');
   const changed=db.prepare("UPDATE account_deletion_requests SET status=?,version=version+1,message=?,updated_at=? WHERE id=? AND version=? AND status!='cancelled'")
    .run(value.status,message.trim(),new Date().toISOString(),id,value.version);
   if(!changed.changes)fail('DELETION_CONFLICT');
   return view(db.prepare('SELECT * FROM account_deletion_requests WHERE id=?').get(id));
  },
 };
}

export async function accountDeletionRoute({req,url,store,send,fail:reject,readJson,userId,authorized=()=>false,adminAuthorized=()=>false}) {
 const path=url.pathname, admin=/^\/admin\/account-deletions(?:\/[^/]+)?$/.test(path);
 if(!admin && !['/v1/me/deletion-request','/v1/me/deletion-request/cancel'].includes(path))return false;
 const permitted=()=>admin?adminAuthorized():Boolean(userId&&authorized());
 if(!permitted()){reject(401,admin?'UNAUTHORIZED':'USER_AUTH_REQUIRED');return true;}
 try {
  if(req.method==='GET'&&path==='/admin/account-deletions')send(200,{items:store.adminAccountDeletions()});
  else if(req.method==='GET'&&path==='/v1/me/deletion-request')send(200,{request:store.accountDeletionRequest(userId)});
  else if(req.method==='POST') {
   const value=await readJson();
   if(!permitted()){reject(401,admin?'UNAUTHORIZED':'USER_AUTH_REQUIRED');return true;}
   if(admin&&path.split('/')[3])send(200,store.reviewAccountDeletion(path.split('/')[3],value));
   else if(path==='/v1/me/deletion-request')send(200,{request:store.requestAccountDeletion(userId,value)});
   else if(path==='/v1/me/deletion-request/cancel')send(200,{request:store.cancelAccountDeletion(userId,value)});
   else reject(405,'METHOD_NOT_ALLOWED');
  } else reject(405,'METHOD_NOT_ALLOWED');
 } catch(error) {
  const status={DELETION_INVALID_INPUT:400,DELETION_CONFLICT:409,USER_AUTH_REQUIRED:401}[error.message];
  if(!status)throw error;
  reject(status,error.message);
 }
 return true;
}
