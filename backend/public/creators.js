let creatorPage = 1, creatorTotal = 0, creatorRequest = 0, creatorDetailRequest = 0, creatorSearchTimer;
let selectedCreator = null, creatorSaving = false;
const creatorPageSize = 20;
const creatorTiers = { standard: '标准创作者', verified: '认证创作者', partner: '签约伙伴' };
const creatorFields = { tier: '等级', commissionRate: '平台分成（%）', manager: '运营负责人', canPublish: '投稿权限',
  canReceiveOrders: '接单权限', identityVerified: '身份已核验', agreementSigned: '协议已签署', payoutReady: '收款资料已完善' };
function creatorDate(value) { const date = new Date(value); return value && Number.isFinite(date.getTime()) ? date.toLocaleString('zh-CN') : '未记录'; }
function creatorButton(label, handler, style = 'secondary') {
  const button = text('button', label, style); button.type = 'button'; button.onclick = handler; return button;
}
function renderCreators() {
  const list = $('creator-cards'); list.replaceChildren();
  if (!creators.length) {
    list.append(text('p', creatorTotal ? '当前页暂无记录，请刷新。' : '没有符合条件的创作者。可以调整筛选条件；新申请提交后会显示在这里。', 'empty'));
  } else {
    const table = text('table', '', 'creator-table'), head = text('thead'), row = text('tr');
    for (const label of ['创作者', '状态 / 等级', '地区 / 技能', '负责人', '申请时间', '操作']) row.append(text('th', label));
    head.append(row); table.append(head); const body = text('tbody');
    for (const creator of creators) {
      const tr = text('tr'), name = text('td');
      name.append(text('strong', creator.displayName), text('p', creator.email || '邮箱待补充'));
      const state = text('td'); state.append(text('span', creatorLabels[creator.status] || creator.status, `creator-status ${creator.status}`), text('p', creatorTiers[creator.management?.tier] || '标准创作者'));
      const skills = text('td'); skills.append(text('div', creator.marketRegion || '未填写'), text('p', creator.skillTags.join(' / ') || '未填写技能'));
      const action = text('td'); action.append(creatorButton(creator.status === 'pending' ? '审核申请' : '查看详情', () => openCreatorDetail(creator.id)));
      tr.append(name, state, skills, text('td', creator.management?.manager || '未分配'), text('td', creatorDate(creator.createdAt)), action); body.append(tr);
    }
    table.append(body); list.append(table);
  }
  $('creators-page').textContent = `第 ${creatorPage} / ${Math.max(1, Math.ceil(creatorTotal / creatorPageSize))} 页 · 共 ${creatorTotal} 位`;
  $('creators-prev').disabled = creatorPage <= 1;
  $('creators-next').disabled = creatorPage * creatorPageSize >= creatorTotal;
}
async function refreshCreators() {
  const request = ++creatorRequest, session = epoch;
  const params = new URLSearchParams({ page: String(creatorPage), pageSize: String(creatorPageSize),
    q: $('creator-search').value.trim(), status: $('creator-status').value, tier: $('creator-tier').value });
  $('creators-error').textContent = ''; $('creator-cards').setAttribute('aria-busy', 'true');
  $('creators-refresh').disabled = true;
  try {
    const data = await api(`/admin/creators?${params}`);
    if (request !== creatorRequest || session !== epoch) return;
    creators = data.items; creatorTotal = data.total; creatorPage = data.page;
    for (const key of ['total', 'pending', 'approved', 'suspended']) $(`creators-${key}`).textContent = data.summary[key];
    renderCreators();
  } catch (error) {
    if (request !== creatorRequest || session !== epoch) return;
    creators = []; creatorTotal = 0; renderCreators();
    $('creator-cards').replaceChildren();
    $('creators-error').textContent = `${error.message} 请点击“刷新创作者”重试。`;
  } finally {
    if (request === creatorRequest && session === epoch) { $('creator-cards').setAttribute('aria-busy', 'false'); $('creators-refresh').disabled = false; }
  }
}
function resetCreatorPage() { creatorPage = 1; return refreshCreators(); }
function clearCreatorDetail() {
  creatorDetailRequest++; selectedCreator = null; $('creator-detail').close(); $('creator-detail-body').replaceChildren();
}
function clearCreatorManagement() {
  clearTimeout(creatorSearchTimer); creatorRequest++; clearCreatorDetail(); creators = []; creatorPage = 1; creatorTotal = 0;
  $('creator-cards').replaceChildren(); $('creators-error').textContent = ''; $('creators-refresh').disabled = false;
}
async function openCreatorDetail(id) {
  const request = ++creatorDetailRequest, session = epoch;
  selectedCreator = null; $('creator-detail-title').textContent = '创作者详情';
  $('creator-detail-body').replaceChildren(text('p', '正在读取资料…'));
  if (!$('creator-detail').open) $('creator-detail').showModal();
  try {
    const data = await api(`/admin/creators/${encodeURIComponent(id)}`);
    if (request !== creatorDetailRequest || session !== epoch || !$('creator-detail').open) return;
    selectedCreator = data.creator; renderCreatorDetail(data);
  } catch (error) {
    if (request !== creatorDetailRequest || session !== epoch) return;
    $('creator-detail-body').replaceChildren(text('p', error.message, 'creator-error'), creatorButton('重新加载', () => openCreatorDetail(id)));
  }
}
function creatorFact(label, value) {
  const entry = text('div'); entry.append(text('dt', label), text('dd', value || '未填写')); return entry;
}
function creatorValue(key, value) {
  if (value === null || value === undefined) return '未设置';
  if (typeof value === 'boolean') return value ? '开启' : '关闭';
  return key === 'tier' ? creatorTiers[value] || value : String(value || '未填写');
}
function renderCreatorDetail({ creator, works }) {
  const root = $('creator-detail-body'); root.replaceChildren();
  $('creator-detail-title').textContent = creator.displayName;
  const info = text('section'), facts = text('dl', '', 'creator-facts');
  info.append(text('h3', '申请资料'), text('span', creatorLabels[creator.status], `creator-status ${creator.status}`));
  for (const [label, value] of [['邮箱', creator.email], ['地区', creator.marketRegion], ['技能', (creator.skillTags || []).join(' / ')],
    ['申请编号', creator.id], ['申请时间', creatorDate(creator.createdAt)], ['更新时间', creatorDate(creator.updatedAt)],
    ['申请协议版本', creator.agreementVersion], ['协议接受时间', creatorDate(creator.agreementAcceptedAt)]]) facts.append(creatorFact(label, value));
  const portfolio = creatorFact('作品集', creator.portfolioUrl);
  try {
    const url = new URL(creator.portfolioUrl);
    if (['http:', 'https:'].includes(url.protocol)) {
      const link = text('a', '打开作品集 ↗'); link.href = url.href; link.target = '_blank'; link.rel = 'noopener noreferrer'; portfolio.append(link);
    }
  } catch { /* Legacy applications may contain a non-URL portfolio description. */ }
  facts.append(portfolio); info.append(facts); root.append(info);

  const form = text('form', '', 'creator-edit');
  form.append(text('h3', '审核与权限'));
  const management = creator.management || {}, fields = text('fieldset', '', 'creator-edit-fields');
  const selectLabel = text('label', '账号状态'), status = actionSelect(creatorLabels, creator.status); status.name = 'status'; selectLabel.append(status);
  const tierLabel = text('label', '创作者等级'), tier = actionSelect(creatorTiers, management.tier || 'standard'); tier.name = 'tier'; tierLabel.append(tier);
  const rate = inputField('平台分成比例（%）', 'commissionRate', management.commissionRate ?? 0, 'number');
  Object.assign(rate.querySelector('input'), { min: '0', max: '100', step: '0.01', required: true });
  const manager = inputField('运营负责人', 'manager', management.manager); manager.querySelector('input').maxLength = 120;
  fields.append(selectLabel, tierLabel, rate, manager);
  for (const key of ['identityVerified', 'agreementSigned', 'payoutReady', 'canPublish', 'canReceiveOrders']) {
    const label = text('label', creatorFields[key], 'creator-checkbox'), check = document.createElement('input');
    check.type = 'checkbox'; check.name = key; check.checked = management[key] === true;
    label.prepend(check); fields.append(label);
  }
  const reasonLabel = text('label', '操作原因 / 审核说明（必填）', 'creator-full'), note = document.createElement('textarea');
  note.name = 'note'; note.required = true; note.maxLength = 1000; note.rows = 3; note.placeholder = '说明审核结论、停用原因或本次权限调整依据'; reasonLabel.append(note); fields.append(reasonLabel);
  fields.append(text('p', '只有已认证的创作者可使用开启的业务权限；停用会暂停投稿和接单，恢复后沿用原权限配置。', 'creator-full'));
  const actions = text('div', '', 'creator-actions creator-full');
  const shortcut = (label, state) => actions.append(creatorButton(label, () => { status.value = state; note.focus(); }));
  if (creator.status === 'pending') { shortcut('通过申请', 'approved'); shortcut('驳回申请', 'rejected'); }
  else if (creator.status === 'suspended') shortcut('恢复认证', 'approved');
  else { shortcut('停用账号', 'suspended'); if (creator.status === 'rejected') shortcut('重新审核', 'pending'); }
  const save = text('button', '保存审核与权限'); save.type = 'submit'; actions.append(save); fields.append(actions);
  const error = text('p', '', 'creator-error'); error.setAttribute('role', 'alert');
  form.append(fields, error); form.onsubmit = event => saveCreator(event, creator, fields, error); root.append(form);

  const workSection = text('section'); workSection.append(text('h3', `关联作品（${works.length}）`));
  if (!works.length) workSection.append(text('p', '该创作者尚未提交作品。'));
  for (const work of works) {
    const entry = text('div', '', 'creator-work');
    const review = work.submissionStatus === 'pending' ? '待审核' : work.reviewStatus === 'approved' || work.submissionStatus === 'approved' ? '审核通过' : work.reviewStatus === 'rejected' || work.submissionStatus === 'rejected' ? '已退回' : '草稿';
    entry.append(text('strong', work.title), text('p', `${work.format === 'package' ? '角色视频包' : '独立视频'} · ${work.clipCount} 个视频 · ${review} · ${{ draft: '未上架', published: '已上架', withdrawn: '已下架' }[work.status] || work.status}`));
    workSection.append(entry);
  }
  root.append(workSection);
  const historySection = text('section'); historySection.append(text('h3', '操作历史'));
  const history = [...(creator.managementHistory || [])].reverse();
  if (!history.length) historySection.append(text('p', '暂无运营操作记录。'));
  for (const entry of history) {
    const event = text('article', '', 'creator-history');
    event.append(text('strong', `${entry.previousStatus ? `${creatorLabels[entry.previousStatus] || entry.previousStatus} → ` : ''}${creatorLabels[entry.status] || entry.status}`),
      text('p', `${creatorDate(entry.at)} · 操作人：${entry.actor || '历史记录未记录'} · 负责人：${entry.manager || '未分配'}`), text('p', entry.note || '未填写原因'));
    for (const [key, change] of Object.entries(entry.changes || {})) event.append(text('div', `${creatorFields[key] || key}：${creatorValue(key, change.from)} → ${creatorValue(key, change.to)}`, 'creator-change'));
    historySection.append(event);
  }
  root.append(historySection);
}
async function saveCreator(event, creator, fields, error) {
  event.preventDefault(); if (creatorSaving || selectedCreator?.id !== creator.id) return;
  const data = new FormData(event.target), note = String(data.get('note') || '').trim();
  if (!note) { error.textContent = '请填写本次操作原因。'; return; }
  const status = data.get('status');
  if (status !== creator.status && ['suspended', 'rejected'].includes(status)
    && !confirm(`确认将“${creator.displayName}”设为${creatorLabels[status]}？\n原因：${note}`)) return;
  const body = { version: creator.version, status, tier: data.get('tier'), commissionRate: Number(data.get('commissionRate')), manager: data.get('manager'), note };
  for (const key of ['identityVerified', 'agreementSigned', 'payoutReady', 'canPublish', 'canReceiveOrders']) body[key] = data.has(key);
  const request = creatorDetailRequest, session = epoch;
  creatorSaving = true; fields.disabled = true; error.textContent = '正在保存…';
  try {
    await api(`/admin/creators/${encodeURIComponent(creator.id)}`, body);
    if (session !== epoch) return;
    $('notice').textContent = `“${creator.displayName}”的审核与权限已更新。`;
    if (request === creatorDetailRequest && $('creator-detail').open) await openCreatorDetail(creator.id);
    await refreshCreators();
  } catch (failure) {
    if (request !== creatorDetailRequest || session !== epoch) return;
    error.replaceChildren(text('span', failure.message), creatorButton('重新读取最新资料', () => {
      if (confirm('重新读取会丢弃当前未保存的修改，是否继续？')) openCreatorDetail(creator.id);
    }));
  } finally { creatorSaving = false; fields.disabled = false; }
}
function initCreatorManagement() {
  Object.assign(messages, { INVALID_CREATOR_PROFILE: '请检查等级、分成比例和权限字段。', INVALID_CREATOR_STATUS: '创作者状态无效。',
    INVALID_CREATOR_QUERY: '筛选条件无效，请清除筛选后重试。', CREATOR_REASON_REQUIRED: '请填写本次操作原因。',
    INVALID_CREATOR_UPDATE: '提交的创作者资料无效。', NOT_FOUND: '记录不存在或已被删除。' });
  $('creator-search').oninput = () => { clearTimeout(creatorSearchTimer); creatorSearchTimer = setTimeout(resetCreatorPage, 250); };
  $('creator-status').onchange = resetCreatorPage; $('creator-tier').onchange = resetCreatorPage;
  $('creators-refresh').onclick = refreshCreators;
  $('creators-prev').onclick = () => { if (creatorPage > 1) { creatorPage--; refreshCreators(); } };
  $('creators-next').onclick = () => { if (creatorPage * creatorPageSize < creatorTotal) { creatorPage++; refreshCreators(); } };
  $('creator-detail-close').onclick = clearCreatorDetail;
  $('creator-detail').addEventListener('close', () => { creatorDetailRequest++; selectedCreator = null; $('creator-detail-body').replaceChildren(); });
}
