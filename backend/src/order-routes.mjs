import { resolve } from 'node:path';
import { unlink } from 'node:fs/promises';
import { receiveImage, serveImage } from './media.mjs';

export async function orderRoute({req,res,url,store,send,fail,readJson,mediaDirectory,userId=null,authorized=()=>true}) {
  const path=url.pathname, admin=path.startsWith('/admin/');
  if(admin && path==='/admin/order-creators' && req.method==='GET') {send(200,{items:store.orderCreatorPool()});return true;}
  if(admin && path==='/admin/customization-orders' && req.method==='GET') {send(200,store.pageCustomizationOrders(url.searchParams));return true;}
  if(path==='/v1/me/creator-tasks' && req.method==='GET') {send(200,{items:store.listCreatorTasks(userId)});return true;}
  const match=/^\/(admin\/customization-orders|v1\/me\/customization-orders|v1\/me\/creator-tasks)\/([^/]+)(?:\/(dispatch|action|materials|recover)(?:\/([^/]+))?)?$/.exec(path);
  if(!match) return false;
  const id=decodeURIComponent(match[2]), action=match[3], creatorRoute=match[1].endsWith('creator-tasks');
  const order=store.getCustomizationOrder(id), creator=creatorRoute?store.getCreatorProfile(userId):null;
  const assigned=()=>store.eligibleOrderCreator(store.getCreatorProfile(userId))&&store.getCustomizationOrder(id)?.assignedCreatorId===creator?.id;
  const allowed=()=>admin||(!creatorRoute&&store.getCustomizationOrder(id)?.userId===userId)||(creatorRoute&&assigned());
  const view=o=>admin||creatorRoute?o:store.customerOrderView(o);
  if(!order) {fail(404,'NOT_FOUND');return true;}
  if(creatorRoute && req.method==='POST' && !action) {
    if(!store.eligibleOrderCreator(creator)) {fail(403,'ORDER_CREATOR_INELIGIBLE');return true;}
    if(!assigned() && !(order.status==='approved_for_quote'&&order.dispatchMode==='applications'&&order.dispatchState==='open')) {fail(404,'NOT_FOUND');return true;}
    const value=await readJson();
    if(!authorized()) {fail(401,'USER_AUTH_REQUIRED');return true;}
    send(200,store.creatorOrderAction(id,userId,value));return true;
  }
  if(!allowed()) {fail(404,'NOT_FOUND');return true;}
  if(req.method==='POST' && action==='recover' && admin) {send(200,store.recoverLegacyOrder(id,await readJson()));return true;}
  if(req.method==='GET' && !action) {send(200,view(order));return true;}
  if(req.method==='POST' && action==='dispatch' && admin) {send(200,store.dispatchOrder(id,await readJson()));return true;}
  if(req.method==='POST' && action==='action' && !admin&&!creatorRoute) {
    const value=await readJson();
    if(!authorized()) {fail(401,'USER_AUTH_REQUIRED');return true;}
    send(200,view(store.customerOrderAction(id,userId,value)));return true;
  }
  const directory=resolve(mediaDirectory,'order-materials');
  if(req.method==='DELETE' && action==='materials' && match[4] && !admin && !creatorRoute) {
    const material=(order.materials??[]).find(m=>m.id===match[4]);
    if(!material) {fail(404,'NOT_FOUND');return true;}
    const result=store.removeOrderMaterial(id,userId,material.id,Number(url.searchParams.get('version')));
    await unlink(resolve(directory,`${material.id}.${material.extension}`)).catch(()=>{});
    send(200,view(result));return true;
  }
  if(req.method==='GET' && action==='materials' && match[4]) {
    const material=(order.materials??[]).find(m=>m.id===match[4]);
    if(!material) fail(404,'NOT_FOUND'); else await serveImage(res,directory,material);
    return true;
  }
  if(req.method==='POST' && action==='materials' && !match[4] && !admin && !creatorRoute) {
    const name=url.searchParams.get('name')||'参考图片', slot=url.searchParams.get('slot');
    if(!slot||slot.length>120||name.length>240) {fail(400,'ORDER_INVALID_MATERIAL');return true;}
    if((order.materials??[]).some(m=>m.slot===slot)) {req.resume();send(200,view(order));return true;}
    if(!['free_review','needs_info','approved_for_quote'].includes(order.status)) {fail(409,'ORDER_MATERIAL_LOCKED');return true;}
    const material=await receiveImage(req,directory,req.headers['content-type']);
    try {
      if(!authorized()||!allowed()) throw new Error('CONFLICT');
      const result=store.attachOrderMaterial(id,userId,{...material,name},slot);
      if(!result.materials.some(m=>m.id===material.id)) await unlink(resolve(directory,`${material.id}.${material.extension}`));
      send(200,view(result));
    } catch(error) {await unlink(resolve(directory,`${material.id}.${material.extension}`)).catch(()=>{});throw error;}
    return true;
  }
  return false;
}
