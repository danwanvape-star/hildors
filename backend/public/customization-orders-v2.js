const $ = id => document.getElementById(id);
const el = (tag, text = '') => { const node = document.createElement(tag); node.textContent = text; return node; };
let busy = false, page = 1, hasNext = false;
let query = '', statusFilter = '';
let listGeneration = 0;
let actor = null, permissions = new Set();
const can = key => Boolean(actor) && !actor.mustChangePassword && (actor.isRoot === true || permissions.has(key));
const statuses = { free_review: '免费预审', needs_info: '待补充资料', approved_for_quote: '预审通过', quoted: '等待用户确认条款与付款', in_production: '制作中', quality_review: '平台质检', user_acceptance: '等待用户验收', delivered: '已交付', rejected: '已拒绝', withdrawn: '已撤回' };
const path = order => `/admin/customization-orders/${encodeURIComponent(order.id)}`;
async function request(url, options = {}) {
  if (options.method && options.method !== 'GET') {
    let permission = url.endsWith('/plan-offer') ? 'orders.quote' : 'orders.deliver';
    if (url.endsWith('/plan-review')) permission = ['request_info','reject'].includes(JSON.parse(options.body).action) ? 'orders.review' : 'orders.deliver';
    if (!can('orders.view') || !can(permission)) throw new Error('当前账号没有此操作权限。');
  }
  const response = await fetch(url, { credentials: 'same-origin', cache: 'no-store', ...options });
  if (!response.ok) throw new Error(response.status === 401 || response.status === 403 ? '登录已失效或权限不足，请返回后台登录。' : response.status === 409 ? '订单版本或状态已变化。输入仍保留，请复制需要保留的内容，再重新读取后操作。' : '操作失败。请检查内容、文件格式、视频时长及订单状态后重试。');
  return response.json();
}
function post(url, value) { return request(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(value) }); }
function updateButtons() {
  document.querySelectorAll('button, input, textarea, select').forEach(node => { node.disabled = busy; });
  $('previous').disabled = busy || page <= 1;
  $('next').disabled = busy || !hasNext;
}
async function run(work, loading = '正在处理…') {
  if (busy) return;
  busy = true; updateButtons(); $('message').textContent = loading;
  try { await work(); } catch (error) { $('message').textContent = error.message; }
  finally { busy = false; updateButtons(); }
}
function jsonDetails(title, value) {
  const details = el('details'); details.append(el('summary', title));
  const pre = el('pre', JSON.stringify(value ?? {}, null, 2));
  pre.style.whiteSpace = 'pre-wrap'; pre.style.overflowWrap = 'anywhere';
  details.append(pre); return details;
}
function amount(snapshot) {
  if (!/^\d{1,18}$/.test(snapshot?.amountMicros ?? '') || !/^[A-Z]{3}$/.test(snapshot?.currency ?? '')) return '金额未记录';
  const micros = BigInt(snapshot.amountMicros);
  const whole = new Intl.NumberFormat('zh-CN', { maximumFractionDigits: 0 }).format(micros / 1000000n);
  const fraction = (micros % 1000000n).toString().padStart(6, '0').replace(/0+$/, '').padEnd(2, '0');
  return `${snapshot.currency} ${whole}.${fraction}`;
}
function textarea(form, title, value = '') {
  const label = el('label', title), input = el('textarea');
  input.required = true; input.maxLength = 4000; input.rows = 3; input.value = value;
  input.style.width = '100%'; input.style.boxSizing = 'border-box'; label.append(input); form.append(label); return input;
}
function button(title, handler) { const node = el('button', title); node.type = 'button'; node.onclick = handler; return node; }
function render(order) {
  const section = el('details'); section.open = true;
  section.append(el('summary', `${order.characterName || '定制视频'} · ${order.planSnapshot.durationSeconds} 秒 · ${statuses[order.status] ?? order.status} · ${order.id.slice(0, 8)}`));
  section.append(el('h2', `订单 ${order.id}`), el('p', `状态：${statuses[order.status] ?? order.status} · 版本 ${order.version}`), el('p', `用户：${order.userId} · 套餐时长：${order.planSnapshot.durationSeconds} 秒 · 私密订单`));
  section.append(el('p',order.planSnapshot.audioMode==='matched'?'音频：平台按视频内容搭配；按订单快照收取加价。':'音频：无音频基础套餐。'));
  const payment = order.payment;
  const payLabels = { purchased: '已验证付款', pending: '等待付款验证', refunded: '已退款' };
  section.append(el('p', `付款：${payment ? payLabels[payment.status] ?? payment.status : '尚无已验证收据'}；环境：${payment?.environment === 'production' ? '正式 / production' : payment?.environment === 'sandbox' ? '测试 / sandbox' : '未记录'}`));
  if (payment) section.append(el('p', `商店：${payment.platform} · 交易：${payment.transactionId}`));
  if (order.paidSnapshot) section.append(el('p', `付款快照金额：${amount(order.paidSnapshot)}`), jsonDetails('查看付款时冻结的套餐与条款', order.paidSnapshot));
  section.append(el('h3', '用户需求'), el('p', typeof order.requirements === 'string' ? order.requirements : '未填写文字需求'), jsonDetails('套餐和价格记录', order.planSnapshot));
  for(const material of order.materials??[]){
    const link=el('a',material.name??'参考图片');link.href=`${path(order)}/materials/${encodeURIComponent(material.id)}?variant=preview`;link.target='_blank';link.rel='noopener';
    const image=el('img');image.src=`${path(order)}/materials/${encodeURIComponent(material.id)}?variant=thumbnail`;image.alt=material.name??'参考图片';image.loading='lazy';image.width=120;image.height=120;image.style.objectFit='contain';link.prepend(image);section.append(link);
  }
  if(order.requirementHistory?.length)section.append(jsonDetails('需求补充记录',order.requirementHistory));
  if (order.offer) section.append(jsonDetails('已确认的交付条款', order.offer));
  section.append(el('p', `已请求修改：${order.revisionCount ?? 0} 次`));
  for (const revision of order.revisionRequests ?? []) section.append(el('p', `${revision.at}：${revision.note}`));
  async function mutate(operation) {
    await operation();
    try { section.replaceWith(render(await request(path(order)))); $('message').textContent = '订单已更新。'; }
    catch { $('message').textContent = '操作已提交，但新版本读取失败。请重新读取订单后继续。'; }
  }
  for(const update of [...(order.productionUpdates??[])].reverse())section.append(el('p',`${new Date(update.at).toLocaleString()} · ${update.text.zh||update.text.en}`));
  if(can('orders.deliver')&&payment?.status==='purchased'&&['in_production','quality_review','user_acceptance'].includes(order.status)){
    const form=el('form');form.append(el('h3','向用户发布制作进展（发布后保留历史）'));
    const english=textarea(form,'英文进展（必填，用户可见）'),chinese=textarea(form,'中文进展（可选）');chinese.required=false;english.maxLength=chinese.maxLength=2000;
    const submit=el('button','发布进展');submit.type='submit';form.append(submit);
    let requestId=crypto.randomUUID();
    form.onsubmit=event=>{event.preventDefault();if(busy||!form.reportValidity()||!english.value.trim())return;run(()=>mutate(()=>post(`${path(order)}/plan-progress`,{version:order.version,requestId,text:{en:english.value.trim(),zh:chinese.value.trim()}})));};
    section.append(form);
  }
  const unpaidReview = ['free_review', 'needs_info', 'approved_for_quote', 'quoted'].includes(order.status) && payment?.status !== 'purchased' && payment?.status !== 'refunded';
  if (unpaidReview && can('orders.quote')) {
    const form = el('form'); form.append(el('h3', '确认交付条款'), el('p', '请根据此订单明确约定每项条款。提交后仍需用户付款验证成功才能开始制作。'));
    const values = {}, terms = order.offer?.terms ?? {};
    for (const [key, label] of [['deliveryContent', '交付内容'], ['deliveryPeriod', '交付周期'], ['revisionScope', '可修改范围'], ['usageRights', '使用权限']]) values[key] = textarea(form, label, terms[key] ?? '');
    const label = el('label', '最多修改次数（0–100，必填）'), revisions = el('input');
    Object.assign(revisions, { type: 'number', min: '0', max: '100', step: '1', required: true, value: terms.maxRevisions ?? '' }); label.append(revisions); form.append(label);
    const save = el('button', '确认条款并等待用户付款'); save.type = 'submit'; form.append(save);
    form.onsubmit = event => {
      event.preventDefault(); if (busy || !form.reportValidity()) return;
      const nextTerms = Object.fromEntries(Object.entries(values).map(([key, input]) => [key, input.value.trim()]));
      if (Object.values(nextTerms).some(value => !value)) { $('message').textContent = '请完整填写交付条款。'; return; }
      nextTerms.maxRevisions = Number(revisions.value);
      if (!Number.isInteger(nextTerms.maxRevisions) || nextTerms.maxRevisions < 0 || nextTerms.maxRevisions > 100) return;
      run(() => mutate(() => post(`${path(order)}/plan-offer`, { version: order.version, terms: nextTerms })));
    };
    section.append(form);
  }
  if (can('orders.deliver') && order.status === 'in_production' && payment?.status === 'purchased') {
    const form = el('form'); form.append(el('h3', '上传私密成品'), el('p', `上传 MP4 视频。服务端检查实际视频时长，必须至少 ${order.planSnapshot.durationSeconds} 秒；通过后进入平台质检。`));
    const label = el('label', 'MP4 成品文件'), file = el('input'); file.type = 'file'; file.accept = 'video/mp4,.mp4'; file.required = true; label.append(file); form.append(label);
    const upload = el('button', '上传并提交质检'); upload.type = 'submit'; form.append(upload);
    form.onsubmit = event => { event.preventDefault(); if (busy || !form.reportValidity() || !file.files?.[0]) return;
      const video = file.files[0];
      run(() => mutate(() => request(`${path(order)}/deliverable`, { method: 'PUT', headers: { 'Content-Type': 'video/mp4', 'If-Match': String(order.version) }, body: video })), '正在上传并检查视频，请勿关闭页面…');
    }; section.append(form);
  }
  if (order.deliverable && payment?.status === 'purchased' && ['quality_review', 'user_acceptance', 'delivered'].includes(order.status)) {
    const link = el('a', '查看私密成品（需管理权限）'); link.href = `${path(order)}/deliverable`; link.target = '_blank'; link.rel = 'noopener'; section.append(el('p', `成品实际时长：${order.deliverable.durationSeconds ?? '未记录'} 秒`), link);
  }
  if (unpaidReview && can('orders.review') || order.status === 'quality_review' && can('orders.deliver')) {
    const form = el('form'); form.append(el('h3', '审核操作'));
    const note = textarea(form, '补充资料、拒绝或返工说明（执行对应操作时必填）'); note.maxLength = 2000;
    const actionButton = (title, action, needsNote) => button(title, () => {
      if (needsNote && !note.value.trim()) { $('message').textContent = '请填写具体说明。'; note.focus(); return; }
      run(() => mutate(() => post(`${path(order)}/plan-review`, { version: order.version, action, ...(needsNote ? { note: note.value.trim() } : {}) })));
    });
    if (unpaidReview) form.append(actionButton('要求补充资料', 'request_info', true), actionButton('拒绝申请', 'reject', true));
    if (order.status === 'quality_review' && payment?.status === 'purchased') form.append(actionButton('质检通过，交用户验收', 'approve_delivery', false), actionButton('退回制作修改', 'request_rework', true));
    section.append(form);
  }
  section.append(el('hr')); return section;
}
function renderSummary(order, generation) {
  const row = el('details');
  const summary = el('summary', `${order.characterName || '定制视频'} · ${order.planSummary.durationSeconds} 秒 · ${statuses[order.status] ?? order.status} · ${order.id.slice(0,8)}`);
  row.append(summary);
  const body = el('div'); row.append(body);
  let loading = false, loaded = false;
  const fetchDetail = async () => {
    if (loading || loaded) return;
    loading = true; body.replaceChildren(el('p','正在读取订单详情…'));
    try {
      const detail = await request(path(order));
      if (generation !== listGeneration || !row.isConnected) return;
      const expanded = render(detail); expanded.open = row.open;
      row.replaceWith(expanded); loaded = true;
    } catch (error) {
      body.replaceChildren(el('p',error.message),button('重新读取详情', fetchDetail));
    } finally { loading = false; }
  };
  row.ontoggle = () => { if (row.open) fetchDetail(); };
  return row;
}
async function load() {
  actor = null; permissions.clear(); hasNext = false; $('orders').replaceChildren();
  const identity = await request('/admin/me'); actor = identity.actor || null; permissions = new Set(Array.isArray(identity.permissions) ? identity.permissions : []);
    if (actor?.mustChangePassword) { $('message').textContent = '请点击“登录与账号”或返回管理后台，先修改本人密码，再进入此页面。'; return; }
  if (!can('orders.view')) { $('message').textContent = '当前账号没有查看订单的权限。'; return; }
  const params = new URLSearchParams({kind:'plan',page:String(page),pageSize:'20',q:query,status:statusFilter});
  const data = await request(`/admin/customization-orders?${params}`);
  page = data.page; hasNext = page * data.pageSize < data.total;
  const generation = ++listGeneration;
  $('orders').replaceChildren(...data.items.map(order => renderSummary(order,generation)));
  $('page').textContent = `第 ${page} / ${Math.max(1,Math.ceil(data.total/data.pageSize))} 页 · 共 ${data.total} 个订单`;
  $('message').textContent = data.items.length ? '点击订单查看需求并处理。' : (query || statusFilter ? '没有符合筛选条件的订单。' : '暂无套餐定制订单。');
}
for (const [value,label] of Object.entries(statuses)) { const option=el('option',label);option.value=value;$('order-status').append(option); }
$('order-filters').onsubmit = event => { event.preventDefault(); if(busy)return;query=$('order-query').value.trim();statusFilter=$('order-status').value;page=1;run(load); };
$('clear-filters').onclick = () => { if(busy)return;query=statusFilter='';$('order-query').value='';$('order-status').value='';page=1;run(load); };
$('refresh').onclick = () => run(load, '正在读取订单…');
$('previous').onclick = () => { if (page > 1) { page--; run(load); } };
$('next').onclick = () => { if (hasNext) { page++; run(load); } };
run(load, '正在读取订单…');
