import {randomBytes,randomUUID,scryptSync,timingSafeEqual} from 'node:crypto';
const groups={account_deletions:['账号注销','view:查看注销申请','review:审核注销申请'],plans:['定制套餐','view:查看套餐及历史','edit:编辑套餐描述时长及排序','pricing:修改套餐价格及有声加价','publish:套餐上架及下架','billing:绑定商店支付商品'],content:['内容','view:查看内容','create:创建内容','edit:编辑信息','upload:上传媒体','review:审核内容','publish:上架','withdraw:下架','delete:删除及恢复','pricing:管理定价'],tags:['标签','manage:管理标签'],creators:['创作者','view:查看创作者','review:审核认证','manage:管理创作者'],orders:['订单','view:查看订单','review:审核订单','quote:管理报价','dispatch:派单','deliver:交付及质检','cancel:取消订单','recover:恢复历史订单'],layout:['页面装修','view:查看装修','edit:编辑装修','publish:发布及回滚'],governance:['举报治理','view:查看举报','manage:处理举报'],operators:['运营账号','manage:管理账号与权限'],audit:['审计','view:查看操作日志']};
export const permissionCatalog=Object.entries(groups).flatMap(([key,[group,...entries]])=>entries.map(entry=>{const [id,label]=entry.split(':');return {id:`${key}.${id}`,label,group};}));
export const permissionKeys=permissionCatalog.map(p=>p.id);
export const permissionPresets=[{id:'plans',label:'套餐运营',permissions:['plans.view','plans.edit','plans.pricing','plans.publish']},{id:'account_deletions',label:'账号注销审核',permissions:['account_deletions.view','account_deletions.review']},{id:'reviewer',label:'内容审核',permissions:['content.view','content.review','creators.view','creators.review','governance.view']},{id:'editor',label:'内容运营',permissions:['content.view','content.create','content.edit','content.upload','content.publish','content.withdraw','tags.manage','layout.view','layout.edit']},{id:'orders',label:'订单运营',permissions:permissionKeys.filter(k=>k.startsWith('orders.'))},{id:'observer',label:'只读查看',permissions:permissionKeys.filter(k=>k.endsWith('.view'))}];
const passwordHash=password=>{if(typeof password!=='string'||password.length<12||password.length>128)throw new Error('OPERATOR_INVALID_PASSWORD');const salt=randomBytes(16).toString('hex');return `${salt}:${scryptSync(password,salt,64).toString('hex')}`;};
const verify=(password,hash)=>{const [salt,key]=hash.split(':');return timingSafeEqual(scryptSync(password,salt,64),Buffer.from(key,'hex'));};
const permissions=value=>{if(!Array.isArray(value)||value.some(p=>!permissionKeys.includes(p)))throw new Error('OPERATOR_INVALID_PERMISSIONS');return [...new Set(value)];};
export function operatorOperations(db){
 db.exec(`CREATE TABLE IF NOT EXISTS operators (id TEXT PRIMARY KEY,username TEXT NOT NULL UNIQUE,display_name TEXT NOT NULL,password_hash TEXT NOT NULL,active INTEGER NOT NULL,permissions TEXT NOT NULL,version INTEGER NOT NULL,auth_version INTEGER NOT NULL,created_at TEXT NOT NULL,updated_at TEXT NOT NULL);
 CREATE TABLE IF NOT EXISTS operator_audit (id TEXT PRIMARY KEY,actor_id TEXT NOT NULL,actor_name TEXT NOT NULL,action TEXT NOT NULL,target_id TEXT,permissions TEXT NOT NULL,created_at TEXT NOT NULL);`);
 if(!db.prepare('PRAGMA table_info(operators)').all().some(c=>c.name==='must_change_password')) db.exec('ALTER TABLE operators ADD COLUMN must_change_password INTEGER NOT NULL DEFAULT 0');
 const atomic=work=>{db.exec('SAVEPOINT operator_mutation');try{const result=work();db.exec('RELEASE operator_mutation');return result;}catch(error){db.exec('ROLLBACK TO operator_mutation; RELEASE operator_mutation');throw error;}};
 const decode=r=>r?{id:r.id,username:r.username,displayName:r.display_name,active:!!r.active,mustChangePassword:!!r.must_change_password,permissions:JSON.parse(r.permissions),version:r.version,createdAt:r.created_at,updatedAt:r.updated_at}:null;
 const get=id=>db.prepare('SELECT * FROM operators WHERE id=?').get(id);
 const audit=(actor,action,targetId,keys=[])=>db.prepare('INSERT INTO operator_audit VALUES (?,?,?,?,?,?,?)').run(randomUUID(),actor?.id??'root',actor?.username??'root',action,targetId??null,JSON.stringify(keys),new Date().toISOString());
 return {
  listOperators:()=>db.prepare('SELECT * FROM operators ORDER BY created_at,id').all().map(decode),
  getOperator:id=>decode(get(id)),
  operatorIdentity(id,authVersion){const r=get(id);return r&&r.active&&r.auth_version===authVersion?{...decode(r),isRoot:false}:null;},
  authenticateOperator(username,password){const r=db.prepare('SELECT * FROM operators WHERE username=?').get(String(username).toLowerCase());if(typeof password!=='string'||password.length>128)return null;const ok=verify(password,r?.password_hash??`00000000000000000000000000000000:${'00'.repeat(64)}`);return r?.active&&ok?{id:r.id,authVersion:r.auth_version}:null;},
  createOperator(value,actor){return atomic(()=>{const username=String(value?.username??'').trim().toLowerCase();if(!/^[a-z0-9_.-]{3,64}$/.test(username)||typeof value.displayName!=='string'||!value.displayName.trim()||value.displayName.length>80||value.active!==undefined&&typeof value.active!=='boolean')throw new Error('OPERATOR_INVALID');const keys=permissions(value.permissions);const hash=passwordHash(value.password);if(db.prepare('SELECT 1 FROM operators WHERE username=?').get(username))throw new Error('OPERATOR_USERNAME_EXISTS');const id=randomUUID(),now=new Date().toISOString();db.prepare('INSERT INTO operators (id,username,display_name,password_hash,active,permissions,version,auth_version,created_at,updated_at,must_change_password) VALUES (?,?,?,?,?,?,1,1,?,?,1)').run(id,username,value.displayName.trim(),hash,value.active===false?0:1,JSON.stringify(keys),now,now);audit(actor,'operator.create',id,keys);return decode(get(id));});},
  updateOperator(id,value,actor){return atomic(()=>{const r=get(id);if(!r)throw new Error('OPERATOR_NOT_FOUND');if(value.version!==r.version)throw new Error('CONFLICT');const keys=permissions(value.permissions??JSON.parse(r.permissions));if(actor?.id===id&&keys.some(k=>!actor.permissions.includes(k)))throw new Error('OPERATOR_SELF_ESCALATION');const name=value.displayName??r.display_name,active=value.active??!!r.active;if(typeof name!=='string'||!name.trim()||name.length>80||typeof active!=='boolean')throw new Error('OPERATOR_INVALID');db.prepare('UPDATE operators SET display_name=?,active=?,permissions=?,version=version+1,auth_version=auth_version+1,updated_at=? WHERE id=?').run(name.trim(),+active,JSON.stringify(keys),new Date().toISOString(),id);audit(actor,'operator.update',id,keys);return decode(get(id));});},
  resetOperatorPassword(id,value,actor){return atomic(()=>{const r=get(id);if(!r)throw new Error('OPERATOR_NOT_FOUND');if(value.version!==r.version)throw new Error('CONFLICT');db.prepare('UPDATE operators SET password_hash=?,must_change_password=1,version=version+1,auth_version=auth_version+1,updated_at=? WHERE id=?').run(passwordHash(value.password),new Date().toISOString(),id);audit(actor,'operator.password',id);return decode(get(id));});},
  changeOperatorPassword(id,value,actor){return atomic(()=>{const r=get(id);if(!r||!r.active)throw new Error('OPERATOR_NOT_FOUND');if(typeof value?.currentPassword!=='string'||value.currentPassword.length>128||!verify(value.currentPassword,r.password_hash))throw new Error('OPERATOR_INVALID_CREDENTIALS');if(value.password===value.currentPassword)throw new Error('OPERATOR_PASSWORD_REUSED');const hash=passwordHash(value.password);db.prepare('UPDATE operators SET password_hash=?,must_change_password=0,version=version+1,auth_version=auth_version+1,updated_at=? WHERE id=?').run(hash,new Date().toISOString(),id);audit({id:r.id,username:r.username},'operator.password.change',id);return decode(get(id));});},
  recordOperatorAudit:audit,
  operatorAudit:()=>db.prepare('SELECT * FROM operator_audit ORDER BY created_at DESC,rowid DESC LIMIT 500').all().map(r=>({id:r.id,actorId:r.actor_id,actor:r.actor_name,action:r.action,targetId:r.target_id,permissions:JSON.parse(r.permissions),createdAt:r.created_at}))
 };
}
export async function adminPermissions(method,path,readJson,store){
 if(method==='POST'&&path==='/admin/me/password')return [];
 if(method==='GET'){
  if(path==='/admin/account-deletions')return ['account_deletions.view'];
  if(/^\/admin\/customization-plans(?:\/[^/]+(?:\/history)?)?$/.test(path))return ['plans.view'];
  if(/^\/admin\/customization-orders\/[^/]+\/deliverable$/.test(path))return ['orders.view'];
  if(['/admin/me','/admin/permissions'].includes(path))return [];
  if(path==='/admin/operators')return ['operators.manage'];
  if(path==='/admin/audit')return ['audit.view'];
  if(path==='/admin/content-tags')return {any:['content.view','content.create','content.edit','tags.manage']};
  if(path==='/admin/packages'||/^\/admin\/(media|covers)\/[^/]+(?:\/thumbnail)?$/.test(path))return ['content.view'];
  if(/^\/admin\/creators(?:\/[^/]+(?:\/application-videos\/[^/]+)?)?$/.test(path))return ['creators.view'];
  if(path==='/admin/order-creators'||path==='/admin/email-status'||/^\/admin\/customization-orders(?:\/[^/]+(?:\/materials\/[^/]+)?)?$/.test(path))return ['orders.view'];
  if(path==='/admin/layout')return ['layout.view'];
  if(/^\/admin\/reports(?:\/[^/]+)?$/.test(path))return ['governance.view'];
 }
 if(method==='PUT'&&/^\/admin\/customization-orders\/[^/]+\/deliverable$/.test(path))return ['orders.deliver'];
 if(method==='PUT'&&/^\/admin\/packages\/[^/]+\/(?:cover|clips(?:\/[^/]+\/media)?)$/.test(path))return ['content.upload'];
 if(method==='DELETE'&&/^\/admin\/packages\/[^/]+\/clips\/[^/]+$/.test(path))return ['content.delete'];
 if(method!=='POST')return null;
 if(/^\/admin\/account-deletions\/[^/]+$/.test(path))return ['account_deletions.review'];
 if(/^\/admin\/customization-plans\/[^/]+$/.test(path)){
  const value=await readJson();
  const fields={usdBaseCents:'pricing',audioMarkupPercent:'pricing',listed:'publish',durationSeconds:'edit',description:'edit',sortOrder:'edit',appleProductId:'billing',googleProductId:'billing',audioAppleProductId:'billing',audioGoogleProductId:'billing'};
  if(!value||typeof value!=='object'||Array.isArray(value)||Object.keys(value).some(key=>key!=='version'&&!Object.hasOwn(fields,key)))return null;
  const current=store.customizationPlans().find(plan=>plan.id===decodeURIComponent(path.split('/').at(-1)));
  const previous=current&&{...current,appleProductId:current.apple?.productId??'',googleProductId:current.google?.productId??'',audioMarkupPercent:current.audio?.markupPercent??20,audioAppleProductId:current.audio?.apple?.productId??'',audioGoogleProductId:current.audio?.google?.productId??''};
  const equal=(a,b)=>a&&b&&typeof a==='object'&&typeof b==='object'?Object.keys(a).length===Object.keys(b).length&&Object.keys(a).every(key=>a[key]===b[key]):a===b;
  const keys=Object.keys(fields).filter(key=>Object.hasOwn(value,key)&&!equal(value[key],previous?.[key])).map(key=>'plans.'+fields[key]);
  return keys.length?[...new Set(keys)]:{any:['plans.edit','plans.pricing','plans.publish','plans.billing']};
 }
 const planOrder=/^\/admin\/customization-orders\/[^/]+\/(plan-offer|plan-progress|plan-review)$/.exec(path);
 if(planOrder){
  if(planOrder[1]==='plan-offer')return ['orders.quote'];
  if(planOrder[1]==='plan-progress')return ['orders.deliver'];
  const value=await readJson();
  if(['request_info','reject'].includes(value?.action))return ['orders.review'];
  if(['approve_delivery','request_rework'].includes(value?.action))return ['orders.deliver'];
  return null;
 }
 if(/^\/admin\/operators(?:\/[^/]+(?:\/password)?)?$/.test(path))return ['operators.manage'];
 if(path==='/admin/content-tags')return ['tags.manage'];
 if(path==='/admin/packages')return ['content.create'];
 let m=/^\/admin\/packages\/[^/]+(?:\/clips\/[^/]+)?\/(metadata|review|inspect|publish|withdraw|delete|restore|pricing)$/.exec(path);
 if(m?.[1]==='publish'&&path.includes('/clips/'))return ['content.publish','content.review'];
 if(m)return [`content.${({metadata:'edit',inspect:'upload',restore:'delete'})[m[1]]??m[1]}`];
 if(/^\/admin\/creators\/[^/]+$/.test(path)){
  const v=await readJson(),current=store.getCreatorProfile(decodeURIComponent(path.split('/').at(-1)));if(!current)return ['creators.review'];
  if(!v||typeof v!=='object'||Array.isArray(v))throw new Error('INVALID_CREATOR_PROFILE');
  if(!Object.hasOwn(v,'status'))v.status=current.status;
  if(!Object.hasOwn(v,'note'))v.note=current.management?.note??'';
  const keys=[];if(v.status!==current.status||Object.hasOwn(v,'abilityLevel')&&v.abilityLevel!==(current.abilityLevel??null)||Object.hasOwn(v,'note')&&v.note!==(current.management?.note??''))keys.push('creators.review');
  const defaults={tier:'standard',commissionRate:0,manager:'',canReceiveOrders:false,identityVerified:false,agreementSigned:false,payoutReady:false};
  if(Object.keys(defaults).some(k=>Object.hasOwn(v,k)&&(k==='commissionRate'?Number(v[k]):v[k])!==(current.management?.[k]??defaults[k])))keys.push('creators.manage');
  return keys.length?keys:{any:['creators.review','creators.manage']};
 }
 if(/^\/admin\/customization-orders\/[^/]+\/dispatch$/.test(path))return ['orders.dispatch'];
 if(/^\/admin\/customization-orders\/[^/]+\/recover$/.test(path))return ['orders.recover'];
 if(/^\/admin\/customization-orders\/[^/]+$/.test(path)){const v=await readJson(),current=store.getCustomizationOrder(decodeURIComponent(path.split('/').at(-1)));const keys=[({free_review:'orders.review',needs_info:'orders.review',approved_for_quote:'orders.review',rejected:'orders.review',quoted:'orders.quote',in_production:'orders.deliver',quality_review:'orders.deliver',user_acceptance:'orders.deliver',delivered:'orders.deliver',withdrawn:'orders.cancel'})[v?.status]??'orders.review'];for(const [key,value] of Object.entries(v?.fields??{})){if(JSON.stringify(value)===JSON.stringify(current?.workflow?.[key]))continue;if(['quoteAmount','currency','deliveryDays'].includes(key))keys.push('orders.quote');else keys.push('orders.deliver');}return [...new Set(keys)];}
 if(path==='/admin/layout/draft')return ['layout.edit'];
 if(['/admin/layout/publish','/admin/layout/rollback'].includes(path))return ['layout.publish'];
 if(/^\/admin\/reports\/[^/]+$/.test(path))return ['governance.manage'];
 return null;
}
