// Server-paged summaries; private materials are requested only inside order details.
let orderPage = 1, orderTotal = 0, orderRequest = 0, orderDetailRequest = 0, orderSearchTimer;
const orderPageSize = 20;
const orderFieldLabels = {quoteAmount:'报价金额',currency:'币种',deliveryDays:'预计工期（天）',assignee:'制作负责人',dueAt:'计划交付日期',deliverableReference:'成品文件或任务地址',qcPassed:'平台质检通过',deliveryReference:'最终交付记录',quoteAcceptedAt:'用户确认报价时间',quoteProposedAt:'创作者报价时间',quoteProposedBy:'报价创作者',quoteConfirmedAt:'平台确认报价时间'};
const orderEventLabels = {assigned:'指派创作者',applications_opened:'发布公开报名',creator_applied:'创作者报名',creator_declined:'创作者退回任务',creator_quoted:'创作者提交报价',creator_submitted:'创作者提交成品',quote_accepted:'用户接受报价',delivery_accepted:'用户确认验收',revision_requested:'用户要求修改',material_uploaded:'用户上传素材',material_removed:'用户移除素材'};
function orderDate(value) { const date = new Date(value); return value && Number.isFinite(date.getTime()) ? date.toLocaleString('zh-CN') : '未记录'; }
function orderButton(label, handler, style = 'secondary') { const button = text('button',label,style); button.type='button'; button.onclick=handler; return button; }
function orderPath(order) { return `/admin/customization-orders/${encodeURIComponent(order.id)}`; }
function orderActionLabel(next, current) {
  if(next==='quality_review') return current==='user_acceptance'?'重新质检':'提交平台质检';
  if(next==='in_production') return current==='quoted'?'开始制作':'退回制作';
  return {needs_info:'退回补充资料',approved_for_quote:'通过预审',rejected:'拒绝申请',free_review:'重新审核',quoted:'确认报价并发送给用户',user_acceptance:'质检通过并交用户验收',withdrawn:'撤回订单',delivered:'确认交付'}[next]||'处理订单';
}
function resetOrderPage() { orderPage=1; refreshOrders().catch(()=>{}); }
async function refreshOrders() {
  const request=++orderRequest, session=epoch;
  const params=new URLSearchParams({page:String(orderPage),pageSize:String(orderPageSize),q:$('order-search').value.trim(),status:$('order-status').value,dispatchMode:$('order-dispatch').value});
  $('order-cards').replaceChildren(text('p','正在加载订单…','empty'));
  $('orders-prev').disabled=true; $('orders-next').disabled=true;
  try {
    const result=await api(`/admin/customization-orders?${params}`);
    if(request!==orderRequest || session!==epoch) return;
    orders=result.items; orderTotal=result.total; orderPage=result.page;
    if(!orders.length && orderPage>1 && orderTotal>0) { orderPage=Math.max(1,Math.ceil(orderTotal/orderPageSize)); return refreshOrders(); }
    $('orders-total').textContent=result.counts?.total??orderTotal;
    $('orders-review').textContent=result.counts?.free_review??0;
    $('orders-production').textContent=result.counts?.in_production??0;
    renderOrders();
  } catch(error) {
    if(request!==orderRequest || session!==epoch) return;
    $('order-cards').replaceChildren(text('p',error.message,'empty'),orderButton('重试',()=>refreshOrders().catch(()=>{})));
    $('orders-page').textContent='订单加载失败';
    throw error;
  }
}
function renderOrders() {
  const target=$('order-cards'); target.replaceChildren();
  for(const order of orders) {
    const row=text('article','','order-row'), info=text('div','','order-row-info');
    info.append(text('h2',order.characterName||'未命名角色'),text('p',order.id),text('p',`用户：${order.userId||'未记录'} · 提交于 ${orderDate(order.createdAt)}`));
    const assignment=order.assignedCreatorName || (order.dispatchState==='unassigned'?'创作者已退回 · 待重新派单':order.dispatchMode==='applications'?'等待报名 / 待选人':'待派单');
    const delivery=text('div','','order-row-meta'); delivery.append(text('strong',assignment),text('p',order.dispatchMode==='direct'?'直接派单':order.dispatchMode==='applications'?`公开报名 · ${order.applicantCount??order.applicantCreatorIds?.length??0} 人`:'尚未分配'),text('p',`交付日期：${order.dueAt||order.workflow?.dueAt||'待安排'}`));
    row.append(info,text('span',orderLabels[order.status]||'未知状态','status'),delivery,orderButton('查看并处理',()=>openOrderDetail(order.id)));
    target.append(row);
  }
  if(!orders.length) target.append(text('p','没有符合条件的订单，可调整筛选或搜索条件。','empty'));
  const pages=Math.max(1,Math.ceil(orderTotal/orderPageSize));
  $('orders-page').textContent=`共 ${orderTotal} 条 · 第 ${orderPage} / ${pages} 页`;
  $('orders-prev').disabled=orderPage<=1; $('orders-next').disabled=orderPage>=pages;
}
function clearOrderDetail() { ++orderDetailRequest; $('order-detail').close(); $('order-detail-body').replaceChildren(); }
async function openOrderDetail(id) {
  const request=++orderDetailRequest, session=epoch;
  if(!$('order-detail').open) $('order-detail').showModal();
  $('order-detail-body').replaceChildren(text('p','正在加载需求和素材…'));
  try { const result=await api(`/admin/customization-orders/${encodeURIComponent(id)}`); if(request!==orderDetailRequest || session!==epoch || !$('order-detail').open) return; renderOrderDetail(result.order||result); }
  catch(error) { if(request!==orderDetailRequest || session!==epoch) return; $('order-detail-body').replaceChildren(text('p',error.message),orderButton('重新加载',()=>openOrderDetail(id))); }
}
function orderSection(title) { const section=text('section','','order-section'); section.append(text('h3',title)); return section; }
function renderOrderDetail(order) {
  const body=$('order-detail-body'); body.replaceChildren();
  body.append(text('h2',order.characterName||'未命名角色'),text('p',`${order.id} · ${orderLabels[order.status]||'未知状态'} · 版本 ${order.version}`));
  const requirements=orderSection('用户需求');
  requirements.append(text('p',`来源：${({original:'原创角色',existing:'已有角色',licensed:'已授权角色',inspired:'灵感角色'})[order.sourceType]||order.sourceType||'未填写'} · 市场：${order.marketRegion||'未填写'}`),text('p',`功能要求：${(order.requestedFeatures||[]).join(' / ')||'未填写'}`),text('p',order.requirements||'未填写补充需求','order-long-text'));
  body.append(requirements);
  const materials=orderSection('用户上传素材（仅后台与获派创作者可见）');
  if(!order.materials?.length) materials.append(text('p','此订单没有可查看的原始图片。历史记录中的素材数量或上传标记不代表文件已实际上传。'));
  else {
    const gallery=text('div','','order-materials');
    for(const material of order.materials) {
      const item=text('figure',''),link=text('a',''); const originalPath=`${orderPath(order)}/materials/${encodeURIComponent(material.id)}`; link.href=originalPath+'?variant=preview'; link.target='_blank'; link.rel='noopener';
      if(material.contentType?.startsWith('image/')) { const img=document.createElement('img'); img.src=originalPath+'?variant=thumbnail'; img.alt=material.name||'用户参考图片'; img.loading='lazy'; img.decoding='async'; img.onerror=()=>{img.replaceWith(text('span','图片加载失败，点击重试预览'));}; link.append(img); } else { link.href=originalPath; link.append(text('span','查看文件')); }
      const original=text('a','查看原图'); original.href=originalPath; original.target='_blank'; original.rel='noopener';
      item.append(link,text('figcaption',`${material.name||'素材'} · 原文件 ${Math.ceil((material.bytes||0)/1024)} KB`),original); gallery.append(item);
    }
    materials.append(gallery);
  }
  body.append(materials);
  const assignment=orderSection('派单与制作安排');
  assignment.append(text('p',`派单方式：${order.dispatchMode==='direct'?'直接派单':order.dispatchMode==='applications'?'公开报名':'未派单'} · 制作人：${order.assignedCreatorName||'尚未选定'} · 报名人数：${order.applicantCreatorIds?.length||0}`));
  if(order.status==='approved_for_quote') {
    const actions=text('div','','order-actions');
    actions.append(orderButton(order.assignedCreatorId?'改派给创作者':'直接派给创作者',()=>showDispatchForm(order,'direct',assignment)),orderButton(order.dispatchMode?'重新开放报名':'发布任务 · 开放报名',()=>showDispatchForm(order,'applications',assignment,true)));
    if(order.dispatchMode==='applications') actions.append(orderButton('选择已报名创作者',()=>showDispatchForm(order,'applications',assignment)));
    assignment.append(actions);
  }
  body.append(assignment);
  const workflow=orderSection('履约信息');
  for(const [key,value] of Object.entries(order.workflow||{})) if(orderFieldLabels[key]) workflow.append(text('p',`${orderFieldLabels[key]}：${value===true?'是':value===false?'否':value}`));
  if(order.creatorQuote) workflow.append(text('p',`创作者建议报价：${order.creatorQuote.quoteAmount??order.creatorQuote.amount??'待确认'} ${order.creatorQuote.currency||''} · ${order.creatorQuote.deliveryDays||'待确认'} 天`));
  body.append(workflow);
  const actions=orderSection('下一步处理');
  const recoverable=!order.dispatchMode && !order.assignedCreatorId && ['quoted','in_production','quality_review','user_acceptance'].includes(order.status);
  const awaitingMaterials=order.legacyRecoveryAt && !(order.materials?.length>=Math.max(1,order.materialCount??1));
  if(recoverable) {
    actions.append(text('p','历史订单尚未关联创作者。请退回补充真实素材，再重新派单和确认报价。'),orderButton('退回补充资料并重走派单',()=>{
      const context=orderForm(actions,order,'恢复历史订单：退回补充资料');
      context.form.prepend(text('p','保留处理记录；清除旧报价、制作安排和验收状态。补齐素材后重新派单，由用户重新确认报价。'));
      context.form.elements.note.required=true;
      context.form.onsubmit=event=>{event.preventDefault();saveOrderForm(order,context,`${orderPath(order)}/recover`,{version:order.version,note:context.form.elements.note.value});};
    }));
  }
  if(awaitingMaterials) actions.append(text('p','等待用户上传真实素材，补齐后才能通过预审并重新派单。'));
  if(order.status==='quoted' && order.dispatchMode) actions.append(text('p','等待用户在 App 中接受报价后进入制作，后台不能代替用户确认。'));
  if(order.status==='user_acceptance' && order.dispatchMode) actions.append(text('p','等待用户在 App 中确认验收或提出修改，后台不能代替用户完成交付。'));
  if(order.status==='approved_for_quote' && order.dispatchMode && !order.creatorQuote) actions.append(text('p','创作者提交建议报价后，平台可确认报价并发送给用户。'));
  for(const next of orderTransitions[order.status]||[]) {
    if(recoverable) continue;
    if(awaitingMaterials && next==='approved_for_quote') continue;
    if(order.legacyRecoveryAt && next==='quoted' && !order.assignedCreatorId) continue;
    if(next==='in_production' && order.status==='quoted' && order.dispatchMode) continue;
    if(next==='delivered' && order.dispatchMode) continue;
    if(next==='quoted' && order.dispatchMode && !order.creatorQuote) continue;
    actions.append(orderButton(orderActionLabel(next,order.status),()=>showOrderAction(order,next,actions)));
  }
  body.append(actions);
  const history=orderSection('处理记录');
  if(!order.workflowHistory?.length) history.append(text('p','暂无处理记录。'));
  for(const entry of [...(order.workflowHistory||[])].reverse()) {
    const transition=(entry.action==='legacy_recovered'?'历史订单退回补充资料，重新派单':orderEventLabels[entry.action]) || (entry.from!==entry.to?`${orderLabels[entry.from]||'订单提交'} → ${orderLabels[entry.to]||'状态更新'}`:'订单信息更新');
    history.append(text('p',`${orderDate(entry.at)} · ${({admin:'管理员',creator:'创作者',user:'用户',system:'系统'})[entry.actor]||'操作人员'} · ${transition}${entry.note?`\n${entry.note}`:''}`,'order-long-text'));
  }
  body.append(history);
}
function orderForm(target,order,title) {
  target.replaceChildren(text('h3',title));
  const form=text('form','','order-edit-form'),error=text('p','','order-error'); error.setAttribute('role','alert');
  const note=text('label','处理说明'),textarea=document.createElement('textarea'); textarea.name='note'; textarea.rows=3; textarea.maxLength=1000; note.append(textarea);
  const buttons=text('div','','order-actions'),save=text('button','确认保存'); save.type='submit';
  buttons.append(save,orderButton('取消 / 返回',()=>renderOrderDetail(order)));
  target.append(form); form.append(note,error,buttons);
  return {form,error,save,note,buttons};
}
async function saveOrderForm(order,context,path,payload) {
  const session=epoch,request=orderDetailRequest;
  const controls=[...context.form.querySelectorAll('input,select,textarea,button')]; controls.forEach(el=>el.disabled=true); context.error.textContent='正在保存…';
  try { await api(path,payload); if(session!==epoch) return; if(request===orderDetailRequest && $('order-detail').open) await openOrderDetail(order.id); await refreshOrders(); }
  catch(error) { if(session!==epoch || request!==orderDetailRequest) return; context.error.replaceChildren(text('span',`${error.message} 若订单已更新，请重新加载详情后处理。`),orderButton('重新加载详情',()=>openOrderDetail(order.id))); controls.forEach(el=>el.disabled=false); }
}
function showOrderAction(order,next,target) {
  const context=orderForm(target,order,`确认：${orderLabels[next]}`);
  const fields=orderFields(next,next==='quoted' && order.creatorQuote?{...order,workflow:{...order.workflow,...order.creatorQuote}}:order); context.form.prepend(fields);
  if(next==='user_acceptance' && order.dispatchMode) fields.append(inputField('最终交付包编号或地址','deliveryReference',order.workflow?.deliveryReference));
  const needsReason=['needs_info','rejected','withdrawn'].includes(next)
    || (order.status==='quality_review' && next==='in_production')
    || (order.status==='user_acceptance' && next==='quality_review');
  context.form.elements.note.required=needsReason;
  context.form.elements.note.disabled=!needsReason;
  context.note.hidden=!needsReason;
  context.form.elements.note.placeholder='请填写退回或不通过的具体原因及需要补充的内容';
  for(const input of fields.querySelectorAll('input')) { input.required=true; if(input.type==='number') { input.min='0.01'; input.step='any'; if(input.name==='deliveryDays') {input.min='1';input.step='1';} } }
  context.form.onsubmit=event=>{event.preventDefault();if(needsReason && !context.form.elements.note.value.trim()) {context.error.textContent='请填写退回或不通过的原因。';return;} const values={}; for(const input of fields.querySelectorAll('[name]')) values[input.name]=input.type==='checkbox'?input.checked:input.value; saveOrderForm(order,context,orderPath(order),{version:order.version,status:next,note:needsReason?context.form.elements.note.value:'',fields:values});};
}
async function showDispatchForm(order,mode,target,reopen=false) {
  const request=orderDetailRequest, selecting=mode==='applications' && order.dispatchMode==='applications' && !reopen;
  const context=orderForm(target,order,mode==='direct'?'直接派单':selecting?'选择报名创作者':'发布公开报名任务');
  context.save.disabled=true;
  context.form.insertBefore(inputField('计划交付日期（可选）','dueAt','','date'),context.note);
  context.form.elements.note.required=false;
  context.note.hidden=true;
  try {
    if(mode==='direct'||selecting) {
      context.error.textContent='正在加载可接单创作者…';
      const result=await api('/admin/order-creators'); if(request!==orderDetailRequest || !context.form.isConnected) return;
      const eligible=result.items.filter(c=>c.status==='approved' && c.management?.canReceiveOrders===true && c.userId!==order.userId && (!selecting || order.applicantCreatorIds?.includes(c.id)));
      const wrap=text('label',selecting?'已报名且有接单资格的创作者':'有接单资格的创作者'),select=document.createElement('select'); select.name='creatorId'; select.required=true;
      const placeholder=text('option','请选择创作者'); placeholder.value='';select.append(placeholder);
      for(const creator of eligible) {const option=text('option',`${creator.displayName} · ${(creator.skills||creator.skillTags||[]).join(' / ')||'未填写技能'} · 在办 ${creator.activeOrderCount??0} 单`);option.value=creator.id;select.append(option);}
      wrap.append(select);context.form.prepend(wrap);
      if(!eligible.length) {context.error.textContent=selecting?'暂无具备接单资格的报名者，请等待报名或检查创作者权限。':'暂无可接单创作者，请先在创作者管理中完成认证并开启接单权限。';return;}
    } else context.form.prepend(text('p','发布后，有接单资格的创作者可以报名。报名后由管理员选择制作人。'));
    context.error.textContent=''; context.save.disabled=false;
    context.form.onsubmit=event=>{event.preventDefault();saveOrderForm(order,context,`${orderPath(order)}/dispatch`,{version:order.version,mode,creatorId:context.form.elements.creatorId?.value||undefined,note:context.form.elements.note.value,dueAt:context.form.elements.dueAt.value||undefined});};
  } catch(error) {context.error.replaceChildren(text('span',error.message),orderButton('重试',()=>showDispatchForm(order,mode,target,reopen)));}
}
document.getElementById('order-search').oninput=()=>{clearTimeout(orderSearchTimer);++orderRequest;orderSearchTimer=setTimeout(resetOrderPage,300);};
document.getElementById('order-dispatch').onchange=resetOrderPage;
document.getElementById('orders-prev').onclick=()=>{orderPage--;refreshOrders().catch(()=>{});};
document.getElementById('orders-next').onclick=()=>{orderPage++;refreshOrders().catch(()=>{});};
document.getElementById('order-close').onclick=clearOrderDetail;
document.getElementById('order-detail').addEventListener('close',()=>{++orderDetailRequest;document.getElementById('order-detail-body').replaceChildren();});
