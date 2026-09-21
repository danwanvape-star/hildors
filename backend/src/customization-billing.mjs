import {operatorActorContext} from './operators.mjs';
export function createCustomizationBilling({mode='disabled',apple,google}={}) {
 if(!['disabled','test','live'].includes(mode))throw new Error('BILLING_MODE_INVALID');
 const adapters={apple,google};
 return {mode, async verify(platform,proof,expected){
  const adapter=adapters[platform];
  if(mode==='disabled'||!adapter?.verify)throw new Error('PAYMENT_NOT_READY');
  const r=await adapter.verify(proof,expected);
  const environment=mode==='live'?'production':'sandbox';
  if(!r||r.verified!==true||r.environment!==environment||r.platform!==platform||r.productId!==expected.productId||r.orderId!==expected.orderId||r.userId!==expected.userId
   ||!['purchased','pending','refunded'].includes(r.status)||typeof r.transactionId!=='string'||r.transactionId.length<1||r.transactionId.length>200)throw new Error('PAYMENT_VERIFICATION_FAILED');
  if(r.status!=='pending'&&(!/^[A-Z]{3}$/.test(r.currency??'')||typeof r.amountMicros!=='string'||!/^\d{1,18}$/.test(r.amountMicros)))throw new Error('PAYMENT_VERIFICATION_FAILED');
  return Object.fromEntries(['platform','environment','productId','orderId','userId','status','transactionId','currency','amountMicros'].map(k=>[k,r[k]]));
 }};
}
export function assertPlanTransition(order,next){
 if(!order?.planSnapshot)return;
 if(['in_production','quality_review','user_acceptance','delivered'].includes(next)&&order.payment?.status!=='purchased')throw new Error('PAYMENT_REQUIRED');
 if(['user_acceptance','delivered'].includes(next)&&(!order.deliverable?.durationVerified||order.deliverable.durationSeconds<order.planSnapshot.durationSeconds))throw new Error('DELIVERY_DURATION_MISMATCH');
}
export function customizationOrderOperations(db) {
 db.exec(`CREATE TABLE IF NOT EXISTS customization_transactions(platform TEXT NOT NULL,transaction_id TEXT NOT NULL,order_id TEXT NOT NULL,user_id TEXT NOT NULL,document TEXT NOT NULL,PRIMARY KEY(platform,transaction_id));`);
 const save=(store,o,patch)=>{
  const d={...o,...patch};for(const k of ['id','userId','version','status','createdAt','updatedAt'])delete d[k];
  const status=patch.status??o.status;assertPlanTransition({...o,...patch},status);
  const change=db.prepare('UPDATE customization_orders SET status=?,document=?,version=version+1,updated_at=? WHERE id=? AND version=?').run(status,JSON.stringify(d),new Date().toISOString(),o.id,o.version);
  if(!change.changes)throw new Error('PLAN_CONFLICT');return store.getCustomizationOrder(o.id);
 };
 return {
  preparePlanOffer(id,value){
   const o=this.getCustomizationOrder(id),t=value?.terms;
   if(!o?.planSnapshot||o.version!==value?.version||!['free_review','needs_info','approved_for_quote','quoted'].includes(o.status)||o.payment?.status==='purchased')throw new Error('PLAN_CONFLICT');
   if((o.materials??[]).length<(o.materialCount??0))throw new Error('ORDER_MATERIAL_REQUIRED');
   if(!t||!['deliveryContent','deliveryPeriod','revisionScope','usageRights'].every(k=>typeof t[k]==='string'&&t[k].trim()&&t[k].length<=4000)||!Number.isInteger(t.maxRevisions)||t.maxRevisions<0||t.maxRevisions>100)throw new Error('TERMS_REQUIRED');
   const terms=Object.fromEntries(['deliveryContent','deliveryPeriod','revisionScope','usageRights','maxRevisions'].map(k=>[k,t[k]]));
   return save(this,o,{status:'quoted',offer:{terms,version:o.version+1,confirmedAt:new Date().toISOString()},privacy:'private'});
  },
  applyVerifiedCustomizationTransaction(receipt){
   const o=this.getCustomizationOrder(receipt.orderId);
   if(!o?.planSnapshot||o.userId!==receipt.userId)throw new Error('PAYMENT_ORDER_MISMATCH');
   if(receipt.status==='pending')return o;
   if(!o.offer||!['quoted','in_production','quality_review','user_acceptance','delivered','withdrawn'].includes(o.status))throw new Error('PLAN_CONFLICT');
   const previous=db.prepare('SELECT * FROM customization_transactions WHERE platform=? AND transaction_id=?').get(receipt.platform,receipt.transactionId);
   if(previous&&(previous.order_id!==o.id||previous.user_id!==o.userId))throw new Error('PAYMENT_REPLAY');
   if(o.payment?.transactionId&&o.payment.transactionId!==receipt.transactionId)throw new Error('PAYMENT_ALREADY_RECORDED');
   if(previous&&JSON.parse(previous.document).status==='refunded'&&receipt.status==='purchased')throw new Error('PAYMENT_REFUNDED');
   if(previous&&JSON.parse(previous.document).status===receipt.status)return o;
   if(o.status==='withdrawn'&&!previous)throw new Error('PLAN_CONFLICT');
   if(receipt.status==='refunded'&&!previous)throw new Error('PAYMENT_ORDER_MISMATCH');
   db.exec('SAVEPOINT custom_payment');try{
    db.prepare('INSERT INTO customization_transactions VALUES (?,?,?,?,?) ON CONFLICT(platform,transaction_id) DO UPDATE SET document=excluded.document').run(receipt.platform,receipt.transactionId,o.id,o.userId,JSON.stringify(receipt));
    const payment={...receipt,verifiedAt:new Date().toISOString()};
    const patch={payment,status:receipt.status==='purchased'&&o.status==='quoted'?'in_production':o.status};
    if(receipt.status==='refunded')patch.status='withdrawn';
    if(!o.paidSnapshot)patch.paidSnapshot={plan:o.planSnapshot,terms:o.offer.terms,currency:receipt.currency,amountMicros:receipt.amountMicros,platform:receipt.platform,transactionId:receipt.transactionId};
    const result=save(this,o,patch);db.exec('RELEASE custom_payment');return result;
   }catch(e){db.exec('ROLLBACK TO custom_payment; RELEASE custom_payment');throw e;}
  },
  recordPlanProgress(id,value,actor=operatorActorContext.getStore()||'admin'){
   const o=this.getCustomizationOrder(id);
   if(!o?.planSnapshot||o.payment?.status!=='purchased'||!['in_production','quality_review','user_acceptance'].includes(o.status))throw new Error('PLAN_CONFLICT');
   const text=value?.text;
   if(typeof value?.requestId!=='string'||!/^[A-Za-z0-9_-]{1,120}$/.test(value.requestId)||!text||typeof text.en!=='string'||!text.en.trim()||text.en.length>2000||(text.zh!==undefined&&(typeof text.zh!=='string'||text.zh.length>2000)))throw new Error('PROGRESS_INVALID');
   const clean={en:text.en.trim(),zh:(text.zh??'').trim()},history=o.productionUpdates??[];
   const previous=history.find(entry=>entry.requestId===value.requestId);
   if(previous){if(JSON.stringify(previous.text)!==JSON.stringify(clean))throw new Error('PLAN_CONFLICT');return o;}
   if(o.version!==value.version)throw new Error('PLAN_CONFLICT');
   if(history.length>=100)throw new Error('PROGRESS_LIMIT');
   return save(this,o,{productionUpdates:[...history,{requestId:value.requestId,text:clean,actor,at:new Date().toISOString()}]});
  },
  reviewPlanOrder(id,value){
   const o=this.getCustomizationOrder(id);if(!o?.planSnapshot||o.version!==value?.version)throw new Error('PLAN_CONFLICT');
   if(value.action==='approve_delivery'&&o.status==='quality_review')return save(this,o,{status:'user_acceptance',workflow:{...o.workflow,qcPassed:true}});
   if(typeof value.note!=='string'||!value.note.trim()||value.note.length>2000)throw new Error('ORDER_NOTE_REQUIRED');
   if(value.action==='request_rework'&&o.status==='quality_review')return save(this,o,{status:'in_production',deliverable:null,adminNote:value.note});
   if(['request_info','reject'].includes(value.action)&&['free_review','needs_info','approved_for_quote','quoted'].includes(o.status)&&o.payment?.status!=='purchased')return save(this,o,{status:value.action==='reject'?'rejected':'needs_info',offer:null,adminNote:value.note});
   throw new Error('PLAN_CONFLICT');
  },
  attachPlanDeliverable(id,version,media){
   const o=this.getCustomizationOrder(id);
   if(!o?.planSnapshot||o.version!==version||o.status!=='in_production'||o.payment?.status!=='purchased')throw new Error('PLAN_CONFLICT');
   if(media?.inspection?.status!=='checked'||!Number.isFinite(media.inspection.videoDurationSeconds)||media.inspection.videoDurationSeconds<o.planSnapshot.durationSeconds)throw new Error('DELIVERY_DURATION_MISMATCH');
   if(o.planSnapshot.audioMode==='matched'&&!media.inspection.audioCodec||o.planSnapshot.audioMode==='none'&&media.inspection.audioCodec)throw new Error('DELIVERY_AUDIO_MISMATCH');
   return save(this,o,{status:'quality_review',deliverable:{...media,durationSeconds:media.inspection.videoDurationSeconds,durationVerified:true},workflow:{...o.workflow,qcPassed:false}});
  },
  planOrderAction(id,userId,value){
   const o=this.getCustomizationOrder(id);if(!o?.planSnapshot||o.userId!==userId||o.version!==value?.version)throw new Error('PLAN_CONFLICT');
   if(value.action==='resubmit'&&o.status==='needs_info'&&o.payment?.status==='unpaid'){
    if(typeof value.requirements!=='string'||!value.requirements.trim()||value.requirements.length>10000)throw new Error('ORDER_REQUIREMENTS_REQUIRED');
    if((o.materials??[]).length<(o.materialCount??0))throw new Error('ORDER_MATERIAL_REQUIRED');
    return save(this,o,{status:'free_review',requirements:value.requirements.trim(),offer:null,requirementHistory:[...(o.requirementHistory??[]),{requirements:o.requirements??'',reviewNote:o.adminNote??'',at:new Date().toISOString()}]});
   }
   if(o.status!=='user_acceptance')throw new Error('PLAN_CONFLICT');
   if(value.action==='accept_delivery')return save(this,o,{status:'delivered',acceptedAt:new Date().toISOString()});
   if(value.action==='request_revision'){
    if(typeof value.note!=='string'||!value.note.trim()||value.note.length>2000)throw new Error('ORDER_NOTE_REQUIRED');
    if((o.revisionCount??0)>=o.offer.terms.maxRevisions)throw new Error('REVISION_LIMIT_REACHED');
    return save(this,o,{status:'in_production',revisionCount:(o.revisionCount??0)+1,revisionRequests:[...(o.revisionRequests??[]),{note:value.note,at:new Date().toISOString()}],deliverable:null,workflow:{...o.workflow,qcPassed:false}});
   }throw new Error('PLAN_CONFLICT');
  }
 };
}
