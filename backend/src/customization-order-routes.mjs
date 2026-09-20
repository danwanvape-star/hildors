import {resolve} from 'node:path';
import {unlink} from 'node:fs/promises';
import {receiveMedia,serveMedia} from './media.mjs';
export async function customizationOrderRoute({req,res,url,store,send,fail,readJson,mediaDirectory,userId,authorized=()=>false,admin=false,billing,inspector,uploadLimit}){
 const m=/^\/(?:admin|v1\/me)\/customization-orders\/([^/]+)\/(plan-offer|plan-review|plan-progress|purchase|deliverable|manifest|download|plan-action)$/.exec(url.pathname);if(!m)return false;
 const id=m[1],action=m[2],o=store.getCustomizationOrder(id);
 const permitted=()=>authorized()&&(admin||store.getCustomizationOrder(id)?.userId===userId);
 if(!o?.planSnapshot||!permitted()){fail(404,'NOT_FOUND');return true;}
 try{
  if(req.method==='POST'&&action==='plan-offer'&&admin){const v=await readJson();if(!permitted()){fail(401,'UNAUTHORIZED');return true;}send(200,store.preparePlanOffer(id,v));}
  else if(req.method==='POST'&&action==='plan-progress'&&admin){const v=await readJson();if(!permitted()){fail(401,'UNAUTHORIZED');return true;}send(200,store.recordPlanProgress(id,v));}
  else if(req.method==='POST'&&action==='plan-review'&&admin){const v=await readJson();if(!permitted()){fail(401,'UNAUTHORIZED');return true;}send(200,store.reviewPlanOrder(id,v));}
  else if(req.method==='POST'&&action==='purchase'&&!admin){
   const v=await readJson();if(!permitted()){fail(401,'USER_AUTH_REQUIRED');return true;}
   const productId=v?.platform==='apple'?o.planSnapshot.appleProductId:v?.platform==='google'?o.planSnapshot.googleProductId:null;
   if(!productId||!o.offer||v?.offerVersion!==o.offer.version||v?.acceptedTerms!==true){fail(409,'TERMS_REQUIRED');return true;}
   const receipt=await billing.verify(v.platform,v.proof,{productId,orderId:id,userId});
   if(!permitted()){fail(401,'USER_AUTH_REQUIRED');return true;}
   if(store.getCustomizationOrder(id)?.offer?.version!==v.offerVersion){fail(409,'PLAN_CONFLICT');return true;}
   send(200,store.customerOrderView(store.applyVerifiedCustomizationTransaction(receipt)));
  } else if(req.method==='POST'&&action==='plan-action'&&!admin){const v=await readJson();if(!permitted()){fail(401,'USER_AUTH_REQUIRED');return true;}send(200,store.customerOrderView(store.planOrderAction(id,userId,v)));}
  else if(req.method==='PUT'&&action==='deliverable'&&admin){
   if(req.headers['content-type']!=='video/mp4'){fail(415,'MP4_REQUIRED');return true;}
   const version=Number(req.headers['if-match']);if(version!==o.version||o.status!=='in_production'||o.payment?.status!=='purchased'){fail(409,'PLAN_CONFLICT');return true;}
   const directory=resolve(mediaDirectory,'private-deliverables');
   const media=await receiveMedia(req,directory,uploadLimit);
   try{const inspection=await inspector(directory,media.id);if(!permitted())throw new Error('USER_AUTH_REQUIRED');send(200,store.attachPlanDeliverable(id,version,{...media,inspection}));}
   catch(e){await Promise.all([unlink(resolve(directory,`${media.id}.mp4`)).catch(()=>{}),unlink(resolve(directory,`${media.id}.jpg`)).catch(()=>{})]);throw e;}
  }else if(req.method==='GET'&&['manifest','download'].includes(action)&&!admin){
   const ready=()=>{const current=store.getCustomizationOrder(id);return permitted()&&current?.status==='delivered'&&current?.payment?.status==='purchased'&&current?.deliverable?.id===o.deliverable?.id;};
   if(!o.deliverable||!ready()){fail(404,'NOT_FOUND');return true;}
   if(action==='manifest')send(200,{packageId:`custom-order-${id}`,clipId:o.deliverable.id,bytes:o.deliverable.bytes,sha256:o.deliverable.sha256,contentType:'video/mp4',authorizationRequired:true,downloadPath:`/v1/me/customization-orders/${id}/download`});
   else await serveMedia(req,res,resolve(mediaDirectory,'private-deliverables'),o.deliverable.id,{cacheControl:'private, no-store',preflight:()=>{if(!ready()){fail(404,'NOT_FOUND');return false;}return true;}});
  }else if(req.method==='GET'&&action==='deliverable'){
   const visible=()=>{const current=store.getCustomizationOrder(id);return permitted()&&current?.payment?.status==='purchased'&&current?.deliverable?.id===o.deliverable?.id&&(admin||['user_acceptance','delivered'].includes(current.status));};
   if(!o.deliverable||!visible()){fail(404,'NOT_FOUND');return true;}
   await serveMedia(req,res,resolve(mediaDirectory,'private-deliverables'),o.deliverable.id,{cacheControl:'private, no-store',preflight:()=>{if(!visible()){fail(404,'NOT_FOUND');return false;}return true;}});
  }else fail(405,'METHOD_NOT_ALLOWED');
 }catch(e){const status={PAYMENT_NOT_READY:503,PAYMENT_VERIFICATION_FAILED:403,PAYMENT_ORDER_MISMATCH:403,PAYMENT_REPLAY:409,PAYMENT_ALREADY_RECORDED:409,PAYMENT_REFUNDED:409,PLAN_CONFLICT:409,PROGRESS_INVALID:400,PROGRESS_LIMIT:409,TERMS_REQUIRED:400,ORDER_REQUIREMENTS_REQUIRED:400,ORDER_MATERIAL_REQUIRED:409,DELIVERY_DURATION_MISMATCH:422,DELIVERY_AUDIO_MISMATCH:422,USER_AUTH_REQUIRED:401,REVISION_LIMIT_REACHED:409,ORDER_NOTE_REQUIRED:400}[e.message];if(!status)throw e;fail(status,e.message);}return true;
}
