let creatorPage = 1, creatorTotal = 0, creatorRequest = 0, creatorDetailRequest = 0, creatorSearchTimer;
let selectedCreator = null, creatorSaving = false;
const creatorPageSize = 20;
function canCreatorPermission(permission) { return typeof canAdmin === 'function' && canAdmin(permission); }
const creatorTiers = { standard: '标准创作者', verified: '认证创作者', partner: '签约伙伴' };
const creatorAbilityLevels = { silver: '白银', gold: '黄金', diamond: '钻石', master: '宗师', legend: '大神' };
const creatorFields = { abilityLevel: '能力等级', tier: '合作类别', commissionRate: '平台分成（%）', manager: '运营负责人', canPublish: '历史投稿权限（现由认证状态决定）',
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
    for (const label of ['创作者', '状态 / 能力等级', '地区 / 擅长方向', '负责人', '申请时间', '操作']) row.append(text('th', label));
    head.append(row); table.append(head); const body = text('tbody');
    for (const creator of creators) {
      const tr = text('tr'), name = text('td');
      name.append(text('strong', creator.displayName), text('p', creator.email || '邮箱待补充'));
      const state = text('td'); state.append(text('span', creatorLabels[creator.status] || creator.status, `creator-status ${creator.status}`), text('p', creatorAbilityLevels[creator.abilityLevel] || '未评级'), text('p', `合作类别：${creatorTiers[creator.management?.tier] || '标准创作者'}`));
      const skills = text('td'); skills.append(text('div', creator.marketRegion || '未填写'), text('p', `擅长角色：${(creator.characterTags || []).join(' / ') || '未填写'}`), text('p', `擅长内容方向：${(creator.skillTags || []).join(' / ') || '未填写'}`));
      const action = text('td'); action.append(creatorButton(creator.status === 'pending' && canCreatorPermission('creators.review') ? '审核申请' : '查看详情', () => openCreatorDetail(creator.id)));
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
    q: $('creator-search').value.trim(), status: $('creator-status').value, tier: $('creator-tier').value,
    abilityLevel: $('creator-ability').value });
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
function releaseCreatorVideos() {
  for (const video of $('creator-detail-body').querySelectorAll('video')) {
    video.pause(); video.removeAttribute('src'); video.load();
  }
}
function clearCreatorDetail() {
  creatorDetailRequest++; selectedCreator = null; releaseCreatorVideos(); $('creator-detail').close(); $('creator-detail-body').replaceChildren();
}
function clearCreatorManagement() {
  clearTimeout(creatorSearchTimer); creatorRequest++; clearCreatorDetail(); creators = []; creatorPage = 1; creatorTotal = 0;
  $('creator-cards').replaceChildren(); $('creators-error').textContent = ''; $('creators-refresh').disabled = false;
}
async function openCreatorDetail(id) {
  const request = ++creatorDetailRequest, session = epoch;
  releaseCreatorVideos();
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
  if (key === 'abilityLevel') return creatorAbilityLevels[value] || '未评级';
  return key === 'tier' ? creatorTiers[value] || value : String(value || '未填写');
}
function renderCreatorDetail({ creator, works = [] }) {
  releaseCreatorVideos();
  const root = $('creator-detail-body'); root.replaceChildren();
  $('creator-detail-title').textContent = creator.displayName;
  const info = text('section'), facts = text('dl', '', 'creator-facts');
  info.append(text('h3', '申请资料'), text('span', creatorLabels[creator.status], `creator-status ${creator.status}`));
  for (const [label, value] of [['邮箱', creator.email], ['地区', creator.marketRegion], ['擅长角色', (creator.characterTags || []).join(' / ')], ['擅长内容方向', (creator.skillTags || []).join(' / ')], ['能力等级', creatorAbilityLevels[creator.abilityLevel] || '未评级'],
    ['申请编号', creator.id], ['申请时间', creatorDate(creator.createdAt)], ['更新时间', creatorDate(creator.updatedAt)],
    ['申请协议版本', creator.agreementVersion], ['协议接受时间', creatorDate(creator.agreementAcceptedAt)]]) facts.append(creatorFact(label, value));
  if (creator.applicationVersion !== 2) {
  const portfolio = creatorFact('作品集', creator.portfolioUrl);
  try {
    const url = new URL(creator.portfolioUrl);
    if (['http:', 'https:'].includes(url.protocol)) {
      const link = text('a', '打开作品集 ↗'); link.href = url.href; link.target = '_blank'; link.rel = 'noopener noreferrer'; portfolio.append(link);
    }
  } catch { /* Legacy applications may contain a non-URL portfolio description. */ }
  facts.append(portfolio);
  }
  info.append(facts); root.append(info);
  if (creator.applicationVersion === 2 || creator.applicationVideos?.length) {
    const videos = creator.applicationVideos || [], section = text('section', '', 'creator-application-videos');
    section.append(text('h3', `认证申请视频（${videos.length}）`), text('p', '申请视频仅供审核。请结合视频数量、质量及创意评定能力等级。技术检查通过不代表认证通过。'));
    if (!videos.length) section.append(text('p', '尚未上传认证申请视频。'));
    for (const item of videos) {
      const card = text('article', '', 'creator-application-video');
      card.append(text('h4', item.name || '申请视频'), text('p', `${(Number(item.bytes || 0) / 1024 / 1024).toFixed(1)} MB · ${creatorDate(item.uploadedAt)} · ${item.inspection?.status === 'checked' && item.inspection.validation === 'decoded' ? '技术检查通过' : '技术检查未通过'}`));
      const video = document.createElement('video'); video.controls = true; video.preload = 'none'; video.playsInline = true;
      video.setAttribute('aria-label', item.name || '认证申请视频');
      video.src = `/admin/creators/${encodeURIComponent(creator.id)}/application-videos/${encodeURIComponent(item.id)}`;
      const feedback = text('p', '', 'creator-error'); feedback.setAttribute('role', 'status');
      video.onerror = () => { feedback.textContent = '视频无法加载，请检查登录状态或重新读取资料后重试。'; };
      card.append(video, feedback); section.append(card);
    }
    root.append(section);
  }

  const form = text('form', '', 'creator-edit');
  form.append(text('h3', '审核与权限'));
  const management = creator.management || {}, fields = text('fieldset', '', 'creator-edit-fields');
  const statusOptions = creator.status === 'draft' ? { draft: '待提交' } : Object.fromEntries(Object.entries(creatorLabels).filter(([key]) => key !== 'draft'));
  const selectLabel = text('label', '账号状态'), status = actionSelect(statusOptions, creator.status); status.name = 'status'; selectLabel.append(status);
  const abilityLabel = text('label', '能力等级'), ability = actionSelect({ '': '未评级', ...creatorAbilityLevels }, creator.abilityLevel || ''); ability.name = 'abilityLevel'; abilityLabel.append(ability);
  const tierLabel = text('label', '合作类别（决定收费资格）'), tier = actionSelect(creatorTiers, management.tier || 'standard'); tier.name = 'tier'; tierLabel.append(tier);
  const rate = inputField('平台分成比例（%）', 'commissionRate', management.commissionRate ?? 0, 'number');
  Object.assign(rate.querySelector('input'), { min: '0', max: '100', step: '0.01', required: true });
  const manager = inputField('运营负责人', 'manager', management.manager); manager.querySelector('input').maxLength = 120;
  fields.append(selectLabel, abilityLabel, tierLabel, rate, manager);
  for (const key of ['identityVerified', 'agreementSigned', 'payoutReady', 'canReceiveOrders']) {
    const label = text('label', creatorFields[key], 'creator-checkbox'), check = document.createElement('input');
    check.type = 'checkbox'; check.name = key; check.checked = management[key] === true;
    label.prepend(check); fields.append(label);
  }
  const reasonLabel = text('label', '不通过 / 停用原因（必填）', 'creator-full'), note = document.createElement('textarea');
  note.name = 'note'; note.maxLength = 1000; note.rows = 3; note.placeholder = '请说明具体问题及需要改进的内容'; reasonLabel.append(note); fields.append(reasonLabel);
  const syncReason = () => { const required = ['rejected', 'suspended'].includes(status.value); reasonLabel.hidden = !required; note.required = required; note.disabled = !required; };
  const publishing = text('p', '', 'creator-full'); publishing.setAttribute('role', 'status');
  const updatePublishing = () => {
    const eligibility = status.value === 'approved' ? '已认证，可投稿。' : status.value === 'suspended' ? '账号已停用，暂停投稿和接单。' : '尚未通过认证，暂不可投稿。';
    const pricing = tier.value === 'partner' ? '签约伙伴可投稿免费及付费内容。' : '该合作类别仅可投稿免费内容。';
    publishing.textContent = `保存后投稿资格：${eligibility}${pricing}`;
  };
  status.onchange = () => { updatePublishing(); syncReason(); }; tier.onchange = updatePublishing; updatePublishing(); syncReason();
  fields.append(publishing, text('p', '所有已认证创作者均可投稿免费内容；标准创作者、认证创作者仅限免费，签约伙伴可选择免费或付费。合作类别与能力等级独立，能力等级不决定投稿或收费资格。独立视频和角色视频包均须平台审核通过后上架。接单仍需开启接单权限。', 'creator-full'));
  const actions = text('div', '', 'creator-actions creator-full');
  const shortcut = (label, state) => { if (canCreatorPermission('creators.review')) actions.append(creatorButton(label, () => { status.value = state; updatePublishing(); syncReason(); if (note.required) note.focus(); else save.focus(); })); };
  if (creator.status === 'pending') { shortcut('通过申请', 'approved'); shortcut('驳回申请', 'rejected'); }
  else if (creator.status === 'suspended') shortcut('恢复认证', 'approved');
  else if (creator.status !== 'draft') { shortcut('停用账号', 'suspended'); if (creator.status === 'rejected') shortcut('重新审核', 'pending'); }
  if (creator.status === 'draft') fields.append(text('p', '申请人尚未正式提交，暂不可通过认证。', 'creator-full'));
  const save = text('button', '保存审核与权限'); save.type = 'submit'; actions.append(save); fields.append(actions);
  const mayReview = canCreatorPermission('creators.review'), mayManage = canCreatorPermission('creators.manage');
  status.disabled = !mayReview; ability.disabled = !mayReview; if (!mayReview) note.disabled = true;
  tier.disabled = !mayManage;
  for (const input of fields.querySelectorAll('input')) input.disabled = !mayManage;
  save.hidden = !mayReview && !mayManage;
  if (save.hidden) fields.append(text('p', '当前账号仅可查看资料，未获授权修改审核结果或运营权限。', 'creator-full'));
  const error = text('p', '', 'creator-error'); error.setAttribute('role', 'alert');
  form.append(fields, error); form.onsubmit = event => saveCreator(event, creator, fields, error); root.append(form);

  const workSection = text('section'); workSection.append(text('h3', `关联作品（${works.length}）`));
  if (!works.length) workSection.append(text('p', '该创作者尚未提交作品。'));
  for (const work of works) {
    const entry = text('div', '', 'creator-work');
    const review = work.submissionStatus === 'pending' ? '待审核' : work.reviewStatus === 'approved' || work.submissionStatus === 'approved' ? '审核通过' : work.reviewStatus === 'rejected' || work.submissionStatus === 'rejected' ? '已退回' : '草稿';
    entry.append(text('strong', work.title), text('p', `${work.format === 'package' ? '角色视频包' : '独立视频'} · ${work.clipCount} 个视频 · ${review} · ${{ draft: '未上架', published: '已上架', withdrawn: '已下架' }[work.status] || work.status}`));
    if (canAdmin('content.view')) entry.append(creatorButton(canAdmin('content.review') ? '查看并审核' : '查看内容', async () => {
      try {
        await refresh();
        const item = items.find(candidate => candidate.id === work.id);
        if (!item) throw new Error('该作品已变更，请刷新创作者资料。');
        $('creator-detail').close(); showView('content');
        selectedItemId = item.id; renderDetail(item); $('content-detail').showModal();
      } catch (error) { $('notice').textContent = error.message; }
    }));
    workSection.append(entry);
  }
  root.append(workSection);
  const historySection = text('section'); historySection.append(text('h3', '操作历史'));
  const history = [...(creator.managementHistory || [])].reverse();
  if (!history.length) historySection.append(text('p', '暂无运营操作记录。'));
  for (const entry of history) {
    const event = text('article', '', 'creator-history');
    event.append(text('strong', `${entry.previousStatus ? `${creatorLabels[entry.previousStatus] || entry.previousStatus} → ` : ''}${creatorLabels[entry.status] || entry.status}`),
      text('p', `${creatorDate(entry.at)} · 操作人：${entry.actor || '历史记录未记录'} · 负责人：${entry.manager || '未分配'}`));
    if (entry.note) event.append(text('p', entry.note));
    for (const [key, change] of Object.entries(entry.changes || {})) event.append(text('div', `${creatorFields[key] || key}：${creatorValue(key, change.from)} → ${creatorValue(key, change.to)}`, 'creator-change'));
    historySection.append(event);
  }
  root.append(historySection);
}
async function saveCreator(event, creator, fields, error) {
  event.preventDefault(); if (creatorSaving || selectedCreator?.id !== creator.id) return;
  const mayReview = canCreatorPermission('creators.review'), mayManage = canCreatorPermission('creators.manage');
  if (!mayReview && !mayManage) { error.textContent = '当前账号没有修改创作者的权限。'; return; }
  const data = new FormData(event.target), status = mayReview ? data.get('status') : creator.status;
  const needsReason = mayReview && ['rejected', 'suspended'].includes(status);
  const note = needsReason ? String(data.get('note') || '').trim() : '';
  if (needsReason && !note) { error.textContent = '请填写不通过或停用原因。'; return; }
  const abilityLevel = mayReview ? String(data.get('abilityLevel') || '') : creator.abilityLevel || '';
  if (creator.status === 'draft' && status !== 'draft') { error.textContent = '申请人尚未正式提交，暂不可审核。'; return; }
  if (mayReview && creator.applicationVersion === 2 && status === 'approved') {
    if (!creator.applicationVideos?.length || !creator.applicationVideos.every(video => video.inspection?.status === 'checked' && video.inspection.validation === 'decoded')) { error.textContent = '至少需要一个申请视频，且所有视频均须技术检查通过才能认证。'; return; }
    if (!Object.hasOwn(creatorAbilityLevels, abilityLevel)) { error.textContent = '请选择能力等级后通过认证。'; return; }
  }
  if (status !== creator.status && ['suspended', 'rejected'].includes(status)
    && !confirm(`确认将“${creator.displayName}”设为${creatorLabels[status]}？\n原因：${note}`)) return;
  const body = { version: creator.version };
  if (mayReview) { body.status = status; body.note = note; if (abilityLevel) body.abilityLevel = abilityLevel; }
  if (mayManage) {
    Object.assign(body, {tier:data.get('tier'), commissionRate:Number(data.get('commissionRate')), manager:data.get('manager')});
    for (const key of ['identityVerified', 'agreementSigned', 'payoutReady', 'canReceiveOrders']) body[key] = data.has(key);
  }
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
  creatorLabels.draft = '待提交';
  Object.assign(messages, { INVALID_CREATOR_PROFILE: '请检查等级、分成比例和权限字段。', INVALID_CREATOR_STATUS: '创作者状态无效。',
    INVALID_CREATOR_QUERY: '筛选条件无效，请清除筛选后重试。', CREATOR_REASON_REQUIRED: '请填写本次操作原因。',
    INVALID_CREATOR_UPDATE: '提交的创作者资料无效。', NOT_FOUND: '记录不存在或已被删除。' });
  $('creator-search').oninput = () => { clearTimeout(creatorSearchTimer); creatorSearchTimer = setTimeout(resetCreatorPage, 250); };
  $('creator-status').onchange = resetCreatorPage; $('creator-tier').onchange = resetCreatorPage; $('creator-ability').onchange = resetCreatorPage;
  $('creators-refresh').onclick = refreshCreators;
  $('creators-prev').onclick = () => { if (creatorPage > 1) { creatorPage--; refreshCreators(); } };
  $('creators-next').onclick = () => { if (creatorPage * creatorPageSize < creatorTotal) { creatorPage++; refreshCreators(); } };
  $('creator-detail-close').onclick = clearCreatorDetail;
  $('creator-detail').addEventListener('close', () => { creatorDetailRequest++; selectedCreator = null; releaseCreatorVideos(); $('creator-detail-body').replaceChildren(); });
}
