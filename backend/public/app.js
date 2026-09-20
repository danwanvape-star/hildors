const $ = id => document.getElementById(id);
let items = [], epoch = 0;
let orders = [], creators = [], activeView = 'content';
let layoutState = null, layoutPage = 'collection', draggedLayoutIndex = null, layoutSavedSnapshot = '';
let reviewing = null, reviewingClip = null, metadataItem = null, selectedItemId = null;
const uploadedClips = item => item.clips.filter(c => c.media || c.bundledAsset);
const liveClips = item => item.status === 'published' ? uploadedClips(item).filter(c => !c.visibility || c.visibility === 'published') : [];
function contentNotice(message) { $('notice').textContent = message; const progress = $('content-progress'); if (progress) progress.textContent = message; }
let contentTags = [], contentPage = 1;
const contentPageSize = 20;
const previews = new Set();
function showConnection(connected) {
  $('login').hidden = connected;
  $('connected').hidden = !connected;
}
function clearPreviews() { for (const url of previews) URL.revokeObjectURL(url); previews.clear(); }
const messages = { PASSWORD_CHANGE_REQUIRED:'请先修改本人密码，再进入业务模块。', OPERATOR_INVALID_CREDENTIALS:'当前密码不正确。', OPERATOR_PASSWORD_REUSED:'新密码不能与当前密码相同。', OPERATOR_INVALID_PASSWORD:'密码须为 12–128 个字符。', FORBIDDEN: '当前账号没有此操作权限，请联系管理员。', PERMISSION_DENIED: '当前账号没有此操作权限，请联系管理员。', CONTENT_GOVERNANCE_HOLD: '内容存在治理限制，请先处理相关问题。', LOGIN_RATE_LIMITED: '登录尝试过多，请稍后再试。', UNAUTHORIZED: '登录已过期，请重新登录。', INVALID_CREDENTIALS: '用户名或密码错误。', VERSION_OR_STATE_CONFLICT: '内容已被更新，请刷新后重试。', INVALID_ORDER_TRANSITION: '不能跳过必要步骤，请按流程推进订单。', ORDER_QUOTE_REQUIRED: '报价时必须填写金额、币种和预计工期。', ORDER_PRODUCTION_REQUIRED: '进入制作前必须指定负责人和截止日期。', ORDER_DELIVERABLE_REQUIRED: '提交质检前必须填写成品文件或任务地址。', ORDER_QC_REQUIRED: '平台质检全部通过后才能提交用户验收。', ORDER_DELIVERY_REQUIRED: '完成交付前必须填写最终交付记录。', MEDIA_REVIEW_REQUIRED: '需要先完成素材处理和审核。', PACKAGE_COVER_REQUIRED: '角色视频包必须先上传角色主图。', INVALID_PACKAGE: '请检查名称、视频数量和标签。' };
Object.assign(messages, { ORDER_USER_CONFIRMATION_REQUIRED:'请等待用户在 App 中亲自确认。', ORDER_CREATOR_INELIGIBLE:'该创作者未认证或没有接单权限，请重新选择。', ORDER_SELF_ASSIGNMENT:'不能将订单分配给下单用户本人。', ORDER_APPLICATION_REQUIRED:'请从已报名创作者中选择制作人。', ORDER_DISPATCH_STAGE:'当前订单状态不允许派单，请重新加载详情。', ORDER_CREATOR_REQUIRED:'请先选择具备接单资格的创作者。', ORDER_NOTE_REQUIRED:'请填写本次处理说明。', ORDER_QUOTE_PROPOSAL_REQUIRED:'请等待创作者提交建议报价。', ORDER_ALREADY_ASSIGNED:'订单已有制作人，请重新加载详情。' });
async function api(path, body) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), body === undefined ? 15000 : 45000);
  try {
    const response = await fetch(path, { method: body === undefined ? 'GET' : 'POST',
      headers: { 'Content-Type': 'application/json' }, credentials: 'same-origin', signal: controller.signal,
      body: body === undefined ? undefined : JSON.stringify(body) });
    const result = await response.json();
    if (!response.ok) throw Object.assign(new Error(messages[result.code] || '操作失败，请稍后重试。'), {status:response.status,code:result.code});
    return result;
  } catch (error) {
    if (controller.signal.aborted) throw Object.assign(new Error(body === undefined ? '连接超时，请重新加载页面。' : '请求超时，操作结果尚未确认。请先刷新核对，勿重复提交。'), {code:'REQUEST_TIMEOUT'});
    throw error;
  } finally { clearTimeout(timer); }
}
function text(tag, value, className) { const el = document.createElement(tag); el.textContent = value; if (className) el.className = className; return el; }
const orderLabels = { free_review: '待预审', needs_info: '待补充资料', approved_for_quote: '待报价', quoted: '待用户确认报价', in_production: '制作中', quality_review: '待平台质检', user_acceptance: '待用户验收', delivered: '已交付', rejected: '预审未通过', withdrawn: '已撤回' };
const orderSteps = ['free_review','approved_for_quote','quoted','in_production','quality_review','user_acceptance','delivered'];
const orderTransitions = { free_review: ['needs_info','approved_for_quote','rejected'], needs_info: ['free_review','approved_for_quote','rejected'], approved_for_quote: ['quoted','needs_info','rejected'], quoted: ['in_production','needs_info','withdrawn'], in_production: ['quality_review'], quality_review: ['in_production','user_acceptance'], user_acceptance: ['quality_review','delivered'], delivered: [], rejected: ['free_review'], withdrawn: [] };
const creatorLabels = { pending: '待审核', approved: '已认证', rejected: '未通过', suspended: '已停用' };
function inputField(label, name, value = '', type = 'text') {
  const wrap = text('label', label); const input = document.createElement('input');
  input.name = name; input.type = type; input.value = value ?? ''; wrap.append(input); return wrap;
}
function orderFields(next, order) {
  const fields = text('div', '', 'order-fields'), saved = order.workflow || {};
  if (next === 'quoted') fields.append(inputField('报价金额', 'quoteAmount', saved.quoteAmount, 'number'), inputField('币种', 'currency', saved.currency || 'USD'), inputField('预计工期（天）', 'deliveryDays', saved.deliveryDays, 'number'));
  if (next === 'in_production') fields.append(inputField('制作负责人', 'assignee', saved.assignee), inputField('计划交付日期', 'dueAt', saved.dueAt, 'date'));
  if (next === 'quality_review') fields.append(inputField('成品文件/任务地址', 'deliverableReference', saved.deliverableReference));
  if (next === 'user_acceptance') { const label = text('label', ' 平台已完成画面、声音、授权及设备适配检查'); const check = document.createElement('input'); check.type = 'checkbox'; check.name = 'qcPassed'; label.prepend(check); fields.append(label); }
  if (next === 'delivered') fields.append(inputField('最终交付包编号或地址', 'deliveryReference', saved.deliveryReference));
  return fields;
}
function showView(view) {
  activeView = view;
  $('console-main').classList.toggle('orders-mode', view === 'orders');
  const titles = { content: ['内容管理', '管理角色内容、创作者投稿与上架进度。'], orders: ['角色定制 · 历史报价订单', '审核需求、分配创作者并跟进制作交付。'], creators: ['创作者管理', '审核创作者资格与管理接单权限。'], audit: ['运营日志', '查看操作记录与操作人。'], operators: ['运营账号', '按岗位创建账号并逐项分配管理权限。'], empty: ['运营工作台', '当前账号尚未分配业务模块。'], layout: ['APP界面装修', '管理 App 页面模块与发布版本。'] };
  $('view-title').textContent = titles[view][0];
  $('view-subtitle').textContent = titles[view][1];
  document.querySelectorAll('[data-panel]').forEach(panel => panel.hidden = panel.dataset.panel !== view);
  document.querySelectorAll('[data-view]').forEach(button => button.classList.toggle('active', button.dataset.view === view));
  $('notice').textContent = view === 'content' ? '管理 App 内容目录。' : view === 'orders' ? '管理角色定制业务订单。' : view === 'creators' ? '审核和管理创作者资格。' : '拖拽管理 App 的运营模块。';
}
function actionSelect(options, selected) {
  const select = document.createElement('select');
  for (const [value, label] of Object.entries(options)) { const option = document.createElement('option'); option.value = value; option.textContent = label; option.selected = value === selected; select.append(option); }
  return select;
}
function renderLayout() {
  if (!layoutState) return;
  $('layout-version').textContent = `草稿版本 ${layoutState.version}`;
  updateLayoutDirty();
  $('layout-rollback').disabled = !layoutState.canRollback;
  document.querySelectorAll('[data-layout-page]').forEach(button => button.classList.toggle('active', button.dataset.layoutPage === layoutPage));
  $('layout-preview-title').textContent = layoutPage === 'collection' ? '藏品' : '发现';
  const blocks = layoutState.draft.pages[layoutPage];
  $('layout-blocks').replaceChildren(); $('layout-preview').replaceChildren();
  blocks.forEach((block, index) => {
    const row = text('div', '', 'layout-block'); row.draggable = canAdmin('layout.edit');
    row.ondragstart = () => { draggedLayoutIndex = index; row.classList.add('dragging'); };
    row.ondragend = () => { draggedLayoutIndex = null; row.classList.remove('dragging'); };
    row.ondragover = event => event.preventDefault();
    row.ondrop = event => { event.preventDefault(); if (draggedLayoutIndex === null || draggedLayoutIndex === index) return; const [moved] = blocks.splice(draggedLayoutIndex, 1); blocks.splice(index, 0, moved); renderLayout(); };
    const handle = text('span', '☷', 'layout-handle');
    const fields = text('div', '', 'layout-fields');
    fields.append(text('strong', block.type));
    const title = document.createElement('input'); title.value = block.title; title.maxLength = 40; title.oninput = () => { block.title = title.value; renderLayoutPreview(); updateLayoutDirty(); }; fields.append(title);
    const options = text('div', '', 'layout-options');
    const visible = document.createElement('input'); visible.type = 'checkbox'; visible.checked = block.visible; visible.onchange = () => { block.visible = visible.checked; renderLayout(); };
    const visibleLabel = text('label', ' 显示'); visibleLabel.prepend(visible);
    const columns = document.createElement('select'); for (const count of [1,2,3]) { const option = document.createElement('option'); option.value = count; option.textContent = `${count}列`; option.selected = count === block.columns; columns.append(option); } columns.onchange = () => { block.columns = Number(columns.value); renderLayout(); };
    options.append(visibleLabel, columns); row.append(handle, fields, options); $('layout-blocks').append(row);
  });
  if (!canAdmin('layout.edit')) for (const control of $('layout-blocks').querySelectorAll('input,select')) control.disabled = true;
  applyAdminPermissions();
  renderLayoutPreview();
}
function updateLayoutDirty() {
  const dirty = Boolean(layoutSavedSnapshot) && JSON.stringify(layoutState.draft) !== layoutSavedSnapshot;
  $('layout-dirty').textContent = dirty ? '有未保存修改' : '草稿已保存';
  $('layout-dirty').className = `layout-dirty${dirty ? ' unsaved' : ''}`;
  $('layout-publish').disabled = dirty;
}
function renderLayoutPreview() {
  if (!layoutState) return; const target = $('layout-preview'); target.replaceChildren();
  for (const block of layoutState.draft.pages[layoutPage].filter(block => block.visible)) {
    const card = text('div', '', 'preview-block'); card.append(text('strong', block.title));
    const grid = text('div', '', 'preview-grid'); grid.style.gridTemplateColumns = `repeat(${block.columns},1fr)`;
    for (let i = 0; i < block.columns * (block.columns === 1 ? 1 : 2); i++) grid.append(text('span', '', 'preview-tile'));
    card.append(grid); target.append(card);
  }
}
async function refreshLayout() { layoutState = await api('/admin/layout'); layoutSavedSnapshot = JSON.stringify(layoutState.draft); renderLayout(); }
function contentState(item) {
  if (item.deletedAt) return 'deleted';
  if (item.status !== 'draft') return item.status;
  return item.submissionStatus || (item.review?.decision === 'approved' ? 'approved' : item.review?.decision === 'rejected' ? 'rejected' : 'draft');
}
const contentStateLabels = {draft:'草稿', pending:'待审核', approved:'待上架', rejected:'已退回', published:'已上架', withdrawn:'已下架', deleted:'已删除'};
function resetPage() { contentPage = 1; render(); }
function render() {
  renderContentTabs();
  $('creator-pending-count').textContent = String(items.filter(x => x.source === 'creator' && contentState(x) === 'pending').length);
  const creatorQueue = $('source-filter').value === 'creator' && $('status').value === 'pending';
  $('creator-review-guide').hidden = !creatorQueue;
  $('total').textContent = items.filter(x => !x.deletedAt).length;
  $('published').textContent = items.filter(x => !x.deletedAt && x.status === 'published').length;
  $('drafts').textContent = items.filter(x => !x.deletedAt && x.status === 'draft').length;
  const query = $('search').value.trim().toLowerCase();
  const visible = items.filter(x => ($('status').value ? contentState(x) === $('status').value : !x.deletedAt)
    && (!$('source-filter').value || x.source === $('source-filter').value)
    && (!$('format-filter').value || x.format === $('format-filter').value)
    && (!$('tag-filter').value || x.tags.includes($('tag-filter').value))
    && `${x.title} ${x.creator?.name || ''} ${x.tags.join(' ')}`.toLowerCase().includes(query));
  const pages = Math.max(1, Math.ceil(visible.length / contentPageSize));
  contentPage = Math.min(contentPage, pages);
  $('result-count').textContent = `共 ${visible.length} 条内容`;
  $('page-info').textContent = `第 ${contentPage} / ${pages} 页 · 每页 ${contentPageSize} 条`;
  $('prev-page').disabled = contentPage <= 1; $('next-page').disabled = contentPage >= pages;
  $('cards').replaceChildren();
  for (const item of visible.slice((contentPage - 1) * contentPageSize, contentPage * contentPageSize)) {
    const row = text('article', '', 'content-row');
    const cover = text('div', '', 'content-thumb');
    const media = item.clips.find(x => x.media?.inspection?.status === 'checked')?.media;
    if (item.cover || media) {
      const image = document.createElement('img'); image.loading = 'lazy'; image.alt = `${item.title}封面`;
      image.src = item.cover ? `/admin/covers/${encodeURIComponent(item.cover.id)}?variant=thumbnail` : `/admin/media/${encodeURIComponent(media.id)}/thumbnail`;
      cover.append(image);
    } else cover.append(text('span', item.format === 'package' ? '角色包' : '视频'));
    const info = text('div', '', 'content-info');
    info.append(text('h2', item.title), text('p', item.tags.join(' · ') || '题材待补充'), text('p', contentNextStep(item), 'content-next-step'));
    const attribution = text('div', '', 'content-attribution');
    attribution.append(text('strong', item.source === 'hildors' ? 'HILDORS 出品' : '创作者出品'), text('small', item.source === 'creator' ? item.creator?.name || '历史创作者' : '官方内容'));
    const format = text('div', '', 'content-format');
    format.append(text('span', item.format === 'package' ? '角色视频包' : '单视频'), text('small', `${uploadedClips(item).length} 个视频 · ${liveClips(item).length} 已上架`));
    const status = text('span', contentStateLabels[contentState(item)] || '草稿', `content-status ${contentState(item)}`);
    const open = text('button', contentState(item) === 'pending' ? '查看并审核' : '查看详情', 'secondary');
    open.onclick = () => { selectedItemId = item.id; renderDetail(item); $('content-detail').showModal(); };
    const actions = text('div', '', 'content-row-actions');
    actions.append(open); appendContentActions(actions, item);
    row.append(cover, info, attribution, format, status, actions); $('cards').append(row);
  }
  if (!visible.length) $('cards').append(text('p', creatorQueue ? '暂无待审核的创作者投稿。创作者需要在 App 中点击「提交审核」；仅上传的视频可切换状态为「草稿」查看。' : '暂无符合条件的内容。', 'empty'));
  if (typeof applyAdminPermissions === 'function') applyAdminPermissions();
}
async function openCreatorSubmissions() {
  $('search').value = ''; $('format-filter').value = ''; $('tag-filter').value = '';
  $('source-filter').value = 'creator'; $('status').value = 'pending'; contentPage = 1;
  showView('content'); render();
  try { await refresh(); $('notice').textContent = '创作者投稿审核：打开「查看并审核」，检查视频后通过或退回；通过后单独上架。'; }
  catch (error) { $('notice').textContent = error.message; }
}
function refreshTagFilter() {
  const selected = $('tag-filter').value;
  const all = new Set([...contentTags.map(t => t.name), ...items.flatMap(x => x.tags)]);
  const first = text('option', '全部题材'); first.value = ''; $('tag-filter').replaceChildren(first);
  for (const name of all) { const option = text('option', name); option.value = name; $('tag-filter').append(option); }
  $('tag-filter').value = all.has(selected) ? selected : '';
}
function renderTagOptions(id, selected = []) {
  const target = $(id); target.replaceChildren();
  const choices = contentTags.filter(t => t.active || selected.includes(t.name));
  for (const name of selected) if (!choices.some(t => t.name === name)) choices.push({ name, active:false });
  for (const tag of choices) {
    const label = text('label', `${tag.name}${tag.active ? '' : '（历史标签）'}`, 'tag-choice');
    const input = document.createElement('input'); input.type = 'checkbox'; input.value = tag.name; input.checked = selected.includes(tag.name);
    label.prepend(input); target.append(label);
  }
  if (!choices.length) target.append(text('p', '暂无可用标签，请先在标签库中添加。'));
}
function selectedTags(id) { return [...$(id).querySelectorAll('input:checked')].map(x => x.value); }
function openMetadata(item) {
  metadataItem = item;
  $('metadata-form').elements.title.value = item.title;
  $('metadata-form').elements.description.value = item.description || '';
  $('metadata-form').elements.englishTitle.value = item.translations?.en?.title || '';
  $('metadata-form').elements.englishDescription.value = item.translations?.en?.description || '';
  $('clip-translations').replaceChildren();
  const missing = [];
  if (!item.translations?.en?.title?.trim()) missing.push('角色名称');
  if (!item.translations?.en?.description?.trim()) missing.push('角色背景');
  item.clips.forEach((clip,index) => {
    const section = document.createElement('fieldset'); section.append(text('legend', '视频：' + clip.title));
    for (const [language,label] of [['zh','中文'],['en','英文']]) {
      for (const [key,caption,limit] of [['title','名称',120],['description','介绍',10000]]) {
        const field = document.createElement(key === 'title' ? 'input' : 'textarea');
        field.name = 'clip' + (language === 'en' ? 'English' : 'Chinese') + (key === 'title' ? 'Title' : 'Description') + index;
        field.maxLength = limit; field.value = clip.translations?.[language]?.[key] || (language === 'zh' ? clip[key] || '' : '');
        const wrapper = text('label',label + caption); wrapper.append(field); section.append(wrapper);
      }
    }
    if (!clip.translations?.en?.title?.trim() || !clip.translations?.en?.description?.trim()) missing.push('视频“' + clip.title + '”');
    $('clip-translations').append(section);
  });
  $('translation-warning').textContent = missing.length ? '英文缺译：' + missing.join('、') + '。保存不会自动补译或上架。' : '英文文案已填写，请由运营确认翻译质量。';
  renderTagOptions('metadata-tags', item.tags); $('metadata-error').textContent = ''; $('metadata-dialog').showModal();
}
function addTagRow(tag = {id:crypto.randomUUID(),name:'',active:true}) {
  const row = text('div', '', 'tag-management-row'); row.dataset.id = tag.id;
  const name = document.createElement('input'); name.value = tag.name; name.maxLength = 32; name.required = true; name.setAttribute('aria-label', '标签名称');
  const label = text('label', '启用'); const active = document.createElement('input'); active.type = 'checkbox'; active.checked = tag.active; label.prepend(active);
  const english = document.createElement('input'); english.className = 'tag-english'; english.maxLength = 32;
  english.value = tag.translations?.en?.name || ''; english.placeholder = '英文标签（缺译时回退原文）'; english.setAttribute('aria-label', '英文标签名称');
  row.translationValue = tag.translations || {};
  row.append(name, english, label); $('tag-rows').append(row); name.focus?.();
}
Object.assign(messages, { CONTENT_TAG_REQUIRED: '请至少选择一个题材标签。', INVALID_CONTENT_TAGS: '标签无效或已停用，请刷新标签库后重选。', INVALID_PACKAGE: '请检查名称、背景介绍、视频清单和题材标签。' });
function renderDetail(item) {
  clearPreviews();
  if (item.deletedAt) {
    const archived = text('section'); archived.append(text('h2', item.title), text('p', contentNextStep(item)));
    appendContentActions(archived, item); $('detail-body').replaceChildren(archived);
    if (typeof applyAdminPermissions === 'function') applyAdminPermissions();
    return;
  }
  const canEditMedia = item.status === 'draft' && !item.ownerId && canAdmin('content.upload');
    const card = text('article', '', 'card');
    card.classList.add(item.format === 'package' ? 'package-card' : 'single-card');
    if (item.format === 'package') {
      const cover = document.createElement('div'); cover.className = 'package-cover';
      if (item.cover) { const image = document.createElement('img'); image.src = `/admin/covers/${encodeURIComponent(item.cover.id)}?variant=preview`; image.alt = `${item.title}角色主图`; cover.append(image); }
      else cover.append(text('span', '角色主图待上传'));
      card.append(cover);
    }
    card.append(text('span', contentStateLabels[contentState(item)], 'status'),
      text('h2', item.title), text('div', `${item.source === 'hildors' ? 'HILDORS 出品' : '创作者出品'} · ${item.format === 'single' ? '独立视频' : '角色视频包'} · ${uploadedClips(item).length} 个视频 · ${liveClips(item).length} 已上架`, 'meta'),
      text('p', item.tags.join(' / ') || '未设置题材标签'));
    card.append(text('p', `内容编号：${item.contentCode || item.id}`, 'content-code'));
    const progress = text('p', '', 'upload-progress'); progress.id = 'content-progress'; progress.setAttribute('role','status'); card.append(progress);
    if (canEditMedia && item.format === 'package') {
      const coverLabel = text('label', item.cover ? '替换角色主图' : '上传角色主图（必需）'); const coverInput = document.createElement('input'); coverInput.type = 'file'; coverInput.accept = 'image/jpeg,image/png';
      coverInput.onchange = async () => { const file = coverInput.files[0]; if (!file) return; coverInput.disabled = true; try { const response = await fetch(`/admin/packages/${encodeURIComponent(item.id)}/cover`, { method: 'PUT', credentials: 'same-origin', headers: { 'Content-Type': file.type, 'If-Match': String(item.version) }, body: file }); const result = await response.json(); if (!response.ok) throw new Error(messages[result.code] || '主图上传失败。'); await refresh(); $('notice').textContent = '角色主图已保存。'; } catch (error) { $('notice').textContent = error.message; coverInput.disabled = false; } }; coverLabel.append(coverInput); card.append(coverLabel);
    }
    const folderTitle = item.format === 'package' ? text('h3', `包内视频（${uploadedClips(item).length}）`) : null; if (folderTitle) card.append(folderTitle);
    if (canAdmin('content.upload') && item.format === 'package' && !item.ownerId && ['draft','published'].includes(item.status)) {
      const label = text('label', '上传 / 追加视频（可多选 MP4）');
      const input = document.createElement('input'); input.type = 'file'; input.accept = '.mp4,video/mp4'; input.multiple = true;
      input.onchange = async () => {
        const files = Array.from(input.files || []); if (!files.length) return;
        if (files.some(f => f.size > 256 * 1024 * 1024)) { $('notice').textContent = '每个视频不能超过 256MB。'; return; }
        input.disabled = true; let current = item, completed = 0, failed = 0, uploadMessage = '';
        try {
          for (const file of files) {
            contentNotice(`正在上传并自动生成缩略图 ${completed + 1}/${files.length}：${file.name}，请保持页面打开。`);
            const response = await fetch(`/admin/packages/${encodeURIComponent(item.id)}/clips?filename=${encodeURIComponent(file.name)}&process=auto`, {
              method: 'PUT', credentials: 'same-origin', headers: { 'Content-Type': 'video/mp4', 'If-Match': String(current.version) }, body: file });
            const result = await response.json(); if (!response.ok) throw new Error(messages[result.code] || '上传失败');
            current = result; completed++; if (result.clips.at(-1)?.media?.inspection?.status !== 'checked') failed++;
          }
          uploadMessage = failed ? `已上传 ${completed} 个视频，其中 ${failed} 个处理失败，请查看对应视频后重试。` : `已上传 ${completed} 个视频，缩略图已自动生成，可继续审核。`;
        } catch (error) { uploadMessage = `已成功上传 ${completed} 个，后续上传已停止：${error.message}`; }
        finally { input.disabled = false; await refresh().catch(() => {}); contentNotice(uploadMessage); }
      };
      label.append(input); card.append(label);
    }
    const list = document.createElement('ul');
    for (const clip of item.clips) {
      if (item.format === 'package' && !clip.media) continue;
      const canEditClip = canAdmin('content.upload') && !item.ownerId && (canEditMedia || (item.status === 'published' && ['draft','withdrawn'].includes(clip.visibility)));
      const row = text('li', '', 'clip-row'); row.append(text('h4',clip.title));
      row.append(createClipPricingEditor(item, clip, { save: api, onSaved: async () => { await refresh(); contentNotice('单条视频价格已保存。'); } }));
      row.append(text('p', clip.visibility === 'withdrawn' ? '已下架' : item.status === 'published' && clip.visibility !== 'draft' ? '已上架' : clip.media?.inspection?.status === 'checked' ? '缩略图已生成 · 待审核上架' : clip.media ? '待自动处理 / 处理失败' : '待上传'));
      if (clip.media) {
        row.append(text('p', `${(clip.media.bytes / 1024 / 1024).toFixed(1)} MB · 视频素材`));
        const inspection = clip.media.inspection;
        if (inspection?.status === 'checked') {
          row.append(text('p', `${inspection.width}×${inspection.height} · ${inspection.durationSeconds.toFixed(1)}秒 · ${inspection.videoCodec} · 编码检查通过`));
          const current = epoch;
          fetch(`/admin/media/${clip.media.id}/thumbnail`, { credentials: 'same-origin' })
            .then(response => { if (!response.ok) throw new Error(); return response.blob(); })
            .then(blob => {
              if (current !== epoch || !row.isConnected) return;
              const url = URL.createObjectURL(blob); previews.add(url);
              const image = document.createElement('img'); image.src = url; image.alt = `${clip.title}缩略图`; image.className = 'thumbnail'; row.prepend(image);
            }).catch(() => { if (row.isConnected) row.append(text('p', '缩略图暂不可用，可重新检查素材。')); });
        } else if (inspection?.status === 'processing') {
          row.append(text('p', '检查进行中；若服务曾重启，可重新检查。'));
        } else if (inspection?.status === 'failed') {
          row.append(text('p', ({ TOOLS_UNAVAILABLE: '视频工具尚未就绪，请配置后重试。', PROCESSING_LIMIT: '超过本地处理范围：最长10分钟、最大4096像素。', PROCESSING_TIMEOUT: '处理超时，可稍后重试。', INVALID_VIDEO: '无法完整解码，请检查视频或重新上传。' })[inspection.code] || '视频检查失败，请重试。'));
        }
        if (canEditClip && inspection?.status !== 'checked') {
          const check = text('button', inspection?.status === 'failed' ? '重试生成缩略图' : '继续处理素材', 'secondary');
          check.onclick = async () => {
            check.disabled = true; check.textContent = '正在检查…';
            try {
              const result = await api(`/admin/packages/${encodeURIComponent(item.id)}/clips/${encodeURIComponent(clip.id)}/inspect`, {});
              await refresh();
              const checked = result.clips.find(c => c.id === clip.id)?.media?.inspection;
              contentNotice(checked?.status === 'checked' ? '缩略图已生成，可继续审核。' : '处理失败，请查看素材提示后重试。');
            } catch (error) { contentNotice(error.message); check.disabled = false; check.textContent = '重试生成缩略图'; }
          };
          row.append(check);
        }
        const play = text('button', '预览素材', 'secondary');
        play.onclick = async () => {
          play.disabled = true; const current = epoch;
          try {
            const response = await fetch(`/admin/media/${clip.media.id}`, { credentials: 'same-origin' });
            if (!response.ok) throw new Error('无法加载视频，请重新连接后台。');
            const blob = await response.blob();
            if (current !== epoch || !row.isConnected) return;
            const url = URL.createObjectURL(blob); previews.add(url);
            const video = document.createElement('video'); video.controls = true; video.src = url; video.preload = 'metadata';
            video.onerror = () => { $('notice').textContent = '浏览器无法解码此素材，需要后续转码处理。'; };
            row.append(video); play.remove();
          } catch (error) { $('notice').textContent = error.message; play.disabled = false; }
        };
        row.append(play);
      }
      if (canEditClip) {
        const label = text('label', clip.media ? '替换MP4素材' : '上传MP4素材');
        const input = document.createElement('input'); input.type = 'file'; input.accept = '.mp4,video/mp4';
        input.onchange = async () => {
          const file = input.files[0]; if (!file) return;
          if (file.size > 256 * 1024 * 1024) { $('notice').textContent = '本地原型单次上传限制为256MB。'; input.value = ''; return; }
          input.disabled = true; contentNotice('正在上传并自动生成缩略图，请保持页面打开…');
          try {
            const response = await fetch(`/admin/packages/${encodeURIComponent(item.id)}/clips/${encodeURIComponent(clip.id)}/media?process=auto`, {
              method: 'PUT', credentials: 'same-origin', headers: { 'Content-Type': 'video/mp4', 'If-Match': String(item.version) }, body: file });
            const result = await response.json();
            if (!response.ok) throw new Error(messages[result.code] || '上传失败，请确认是有效的MP4文件后重试。');
            await refresh(); contentNotice(result.clips.find(c => c.id === clip.id)?.media?.inspection?.status === 'checked' ? '视频已保存，缩略图已自动生成。' : '视频已保存，但自动处理失败，请查看提示后重试。');
          } catch (error) { contentNotice(error.message); input.disabled = false; }
        };
        label.append(input);
        if (clip.media) { const replacement = document.createElement('details'); replacement.append(text('summary','替换视频'),label); row.append(replacement); }
        else row.append(label);
      }
      if (item.format === 'package' && clip.media && ['draft','published','withdrawn'].includes(item.status) && (!item.ownerId || ['published','withdrawn'].includes(item.status))) {
        if (clip.visibility !== 'withdrawn') {
          const withdraw = text('button', '单独下架此视频', 'secondary');
          withdraw.dataset.permission = 'content.withdraw';
      withdraw.onclick = async () => {
            if (!confirm(`确认下架“${clip.title}”？包内其他视频不受影响。`)) return;
            withdraw.disabled = true;
            try { await api(`/admin/packages/${encodeURIComponent(item.id)}/clips/${encodeURIComponent(clip.id)}/withdraw`, { version: item.version }); await refresh(); $('notice').textContent = '该视频已下架。'; }
            catch (error) { $('notice').textContent = error.message; withdraw.disabled = false; }
          }; row.append(withdraw);
        }
        if (['draft','withdrawn'].includes(item.status) && clip.visibility === 'withdrawn') {
          const restore = text('button', '恢复至草稿', 'secondary');
          restore.dataset.permission = 'content.delete';
      restore.onclick = async () => { restore.disabled = true; try { await api(`/admin/packages/${encodeURIComponent(item.id)}/clips/${encodeURIComponent(clip.id)}/restore`, {version:item.version}); await refresh(); } catch(error) { $('notice').textContent = error.message; restore.disabled = false; } };
          row.append(restore);
        }
        if (canAdmin('content.review') && canAdmin('content.publish') && item.status === 'published' && ['draft','withdrawn'].includes(clip.visibility) && clip.media.inspection?.status === 'checked') {
          const publish = text('button', '审核并上架此视频');
          publish.dataset.permission = 'content.publish';
      publish.onclick = () => { reviewingClip = { item, clip }; $('clip-review-form').reset(); $('clip-review-title').textContent = clip.title; $('clip-review-error').textContent = ''; $('clip-review-dialog').showModal(); };
          row.append(publish);
        }
      }
      list.append(row);
    }
    const active = item.clips.filter(c => c.visibility !== 'withdrawn' && (item.format !== 'package' || c.media));
    const allMedia = active.length > 0 && active.every(c => c.media);
    const allChecked = active.length > 0 && active.every(c => c.media?.inspection?.status === 'checked');
    const coverReady = item.format === 'single' || Boolean(item.cover) || item.demo;
    if (item.ownerId && item.status === 'draft' && ['draft','rejected'].includes(item.submissionStatus)) card.append(text('p', item.submissionStatus === 'rejected' ? '已退回修改，等待创作者修改后重新提交审核。' : '创作者已保存草稿，尚未提交审核。请由创作者在 App 中完成上传并点击「提交审核」。', 'workflow-hint'));
    card.append(list, text('p', item.ownerId && item.status === 'draft' && ['draft','rejected'].includes(item.submissionStatus) ? '作品尚未进入平台审核队列。' : item.demo ? '内置演示素材' : item.status === 'published' ? '已发布到 App 内容目录' : !coverReady ? '下一步：上传角色主图' : !allMedia ? '下一步：上传视频，可一次选择多个文件' : !allChecked ? '视频正在处理或处理失败，请查看各条视频的状态' : item.review?.decision === 'approved' ? '审核已通过，可发布到 App' : '素材已就绪，可审核入库', 'workflow-hint'));
    if (item.review) card.append(text('p', `审核：${item.review.decision === 'approved' ? '已通过' : '退回修改'} · ${item.review.note}`));
    if (item.status === 'draft' && (item.ownerId ? item.submissionStatus === 'pending' : coverReady && allChecked && item.review?.decision !== 'approved')) {
      const reviewButton = text('button', '审核内容', 'publish-action');
      reviewButton.dataset.permission = 'content.review';
      reviewButton.onclick = () => {
        reviewing = item; $('review-form').reset(); syncReviewDecision(); $('review-error').textContent = '';
        $('review-title').textContent = `${item.title} · ${item.contentCode || item.id}`; $('review-dialog').showModal();
      };
      card.append(reviewButton);
    }
    if (canEditMedia && !allChecked) {
      const unavailable = text('button', allMedia ? '视频处理完成后可审核' : '上传视频后可审核', 'publish-action');
      unavailable.disabled = true; card.append(unavailable);
    }
    const managementActions = text('div', '', 'content-detail-actions');
    appendContentActions(managementActions, item); card.append(managementActions);

  card.append(text('h3', '角色背景介绍'), text('p', item.description || '背景介绍待补充', 'story-text'));
  if (!item.ownerId || (item.status === 'draft' && ['draft','rejected'].includes(item.submissionStatus))) {
    const edit = text('button', '编辑名称、题材与介绍', 'secondary'); edit.dataset.permission = 'content.edit';
    edit.onclick = () => openMetadata(item); card.append(edit);
  }
  $('detail-body').replaceChildren(card);
  if (typeof applyAdminPermissions === 'function') applyAdminPermissions();
}
const adminViews = {content:'content.view', orders:'orders.view', creators:'creators.view', layout:'layout.view', operators:'operators.manage', audit:'audit.view'};
async function loadAdminView(view) {
  const current = epoch;
  if (!Object.hasOwn(adminViews, view) || !canAdmin(adminViews[view])) return;
  if (view === 'content') await refresh();
  if (view === 'orders') await refreshOrders();
  if (view === 'creators') await refreshCreators();
  if (view === 'layout') await refreshLayout();
  if (view === 'operators') await refreshOperators();
  if (view === 'audit') await refreshAudit();
  if (current !== epoch) return;
  showView(view); applyAdminPermissions();
}
async function startAdminSession() {
  const current = epoch;
  const identity = await refreshAdminIdentity();
  if (!identity || current !== epoch) return;
  showConnection(true); $('startup-recovery').hidden = true;
  if (identity.actor.mustChangePassword) { showView('empty'); $('view-subtitle').textContent = '完成本人密码设置后即可进入已授权模块。'; showConnection(true); $('notice').textContent = '请先修改本人密码，再进入业务模块。'; openOwnPassword(); return; }
  const requested = window.location?.hash?.slice(1);
  if (requested && Object.hasOwn(adminViews, requested) && canAdmin(adminViews[requested])) activeView = requested;
  const view = Object.hasOwn(adminViews, activeView) && canAdmin(adminViews[activeView]) ? activeView : Object.keys(adminViews).find(key => canAdmin(adminViews[key]));
  if (view) { showView(view); await loadAdminView(view); }
  else { showView('empty'); $('notice').textContent = ['governance.view','plans.view','account_deletions.view'].some(canAdmin) ? '请从左侧进入已授权的管理模块。' : '当前账号暂无可用业务模块，请联系管理员分配权限。'; }
  if (current === epoch) $('session-retry').hidden = true;
}
function handleSessionFailure(error) {
  if (error.status === 401) { $('startup-recovery').hidden = true; endAdminSession(); $('notice').textContent = '登录已失效，请重新登录。'; $('session-retry').hidden = true; return; }
  $('notice').textContent = error.status === 403 ? '当前账号没有此页面的权限，可切换其他菜单。' : '页面暂时加载失败，请重试。无需重复登录。';
  $('session-retry').hidden = false;
}
async function restoreAdminSession() {
  const current = epoch;
  $('login').hidden = true; $('session-retry').hidden = true; $('startup-recovery').hidden = false;
  $('notice').textContent = '正在检查登录状态…';
  try { await startAdminSession(); }
  catch (error) { if (current === epoch) handleSessionFailure(error); }
  finally { if (current === epoch) $('startup-recovery').hidden = true; }
}
async function refresh() {
  const current = epoch;
  const [result, tagsResult] = await Promise.all([api('/admin/packages'), api('/admin/content-tags')]);
  if (current !== epoch) return;
  items = result.items; contentTags = tagsResult.items; refreshTagFilter(); render(); showView(activeView);
  if (selectedItemId && $('content-detail').open) { const selected = items.find(x => x.id === selectedItemId); if (selected) renderDetail(selected); }
}
$('login').onsubmit = async event => {
  event.preventDefault(); epoch++;
  $('workspace').hidden = true;
  try { await api('/admin/login', { username: $('username').value.trim(), password: $('password').value }); $('password').value = ''; await restoreAdminSession(); }
  catch (error) { $('password').value = ''; showConnection(false); $('notice').textContent = error.message; }
};
function endAdminSession() { epoch++; clearOperatorManagement(); clearAudit(); clearOrderDetail(); clearCreatorManagement(); clearPreviews(); items = []; orders = []; creators = []; layoutState = null; reviewing = null; showConnection(false); document.querySelectorAll('[data-panel]').forEach(x => x.hidden = true); $('cards').replaceChildren(); for (const id of ['editor','review-dialog','content-detail','metadata-dialog','tags-dialog','clip-review-dialog']) $(id).close(); selectedItemId = null; $('notice').textContent = '已安全退出后台。'; }
$('logout').onclick = async () => { endAdminSession(); await api('/admin/logout', {}).catch(() => {}); };
$('refresh').onclick = async () => { try { await refresh(); $('notice').textContent = '内容已刷新。'; } catch (error) { $('notice').textContent = error.message; } };
$('creator-submissions').onclick = openCreatorSubmissions;
$('search').oninput = resetPage; for (const id of ['status','source-filter','format-filter','tag-filter']) $(id).onchange = resetPage;
$('order-status').onchange = resetOrderPage;
$('orders-refresh').onclick = () => refreshOrders().catch(error => $('notice').textContent = error.message);
$('creators-refresh').onclick = () => refreshCreators().catch(error => $('notice').textContent = error.message);
document.querySelectorAll('[data-view]').forEach(button => button.onclick = async () => {
  const current = epoch;
  try { await loadAdminView(button.dataset.view); $('session-retry').hidden = true; }
  catch (error) { if (current === epoch) handleSessionFailure(error); }
});
document.querySelectorAll('[data-layout-page]').forEach(button => button.onclick = () => { layoutPage = button.dataset.layoutPage; renderLayout(); });
$('layout-save').onclick = async () => { try { layoutState = await api('/admin/layout/draft', { version: layoutState.version, layout: layoutState.draft }); layoutSavedSnapshot = JSON.stringify(layoutState.draft); renderLayout(); $('notice').textContent = '页面装修草稿已保存，尚未影响用户。'; } catch (error) { $('notice').textContent = error.message; } };
$('layout-publish').onclick = async () => { if (JSON.stringify(layoutState.draft) !== layoutSavedSnapshot) { $('notice').textContent = '请先保存草稿，再发布到 App。'; return; } const visible = Object.values(layoutState.draft.pages).flat().filter(x => x.visible).length; if (!confirm(`确认发布预览中的布局？\n本次共显示 ${visible} 个模块，用户下次刷新后生效。`)) return; try { layoutState = await api('/admin/layout/publish', { version: layoutState.version }); layoutSavedSnapshot = JSON.stringify(layoutState.draft); renderLayout(); $('layout-dirty').textContent = '已发布'; $('layout-dirty').className = 'layout-dirty published'; $('notice').textContent = '新版布局已发布到 App。'; } catch (error) { $('notice').textContent = error.message; } };
$('layout-rollback').onclick = async () => { if (JSON.stringify(layoutState.draft) !== layoutSavedSnapshot && !confirm('当前有未保存修改，回滚将丢弃这些修改。是否继续？')) return; if (!confirm('确认恢复上一版已发布布局？恢复后会立即影响 App。')) return; try { layoutState = await api('/admin/layout/rollback', { version: layoutState.version }); layoutSavedSnapshot = JSON.stringify(layoutState.draft); renderLayout(); $('notice').textContent = '已恢复上一版布局。'; } catch (error) { $('notice').textContent = error.message; } };
window.addEventListener('beforeunload', event => { if (layoutState && JSON.stringify(layoutState.draft) !== layoutSavedSnapshot) { event.preventDefault(); event.returnValue = ''; } });
function syncCreateFormat() {
  const packaged = $('format').value === 'package';
  $('clip-names-field').hidden = packaged;
  $('clip-names').required = !packaged;
  $('clip-names').disabled = packaged;
  $('package-upload-hint').hidden = !packaged;
}
$('format').onchange = syncCreateFormat;
$('new').onclick = () => { $('create').reset(); syncCreateFormat(); renderTagOptions('create-tags'); $('form-error').textContent = ''; $('editor').showModal(); };
$('close').onclick = () => $('editor').close();
$('review-close').onclick = () => $('review-dialog').close();
function syncReviewDecision() {
  const rejected = $('review-decision').value === 'rejected';
  $('review-reason-field').hidden = !rejected; $('review-reason').required = rejected; $('review-reason').disabled = !rejected;
}
$('review-decision').onchange = syncReviewDecision;
$('clip-review-close').onclick = () => { reviewingClip = null; $('clip-review-dialog').close(); };
$('clip-review-form').onsubmit = async event => {
  event.preventDefault(); if (!reviewingClip) return;
  const {item,clip} = reviewingClip;
  $('clip-review-save').disabled = true;
  try {
    await api(`/admin/packages/${encodeURIComponent(item.id)}/clips/${encodeURIComponent(clip.id)}/publish`, {
      version:item.version });
    $('clip-review-dialog').close(); reviewingClip = null; await refresh(); $('notice').textContent = '该视频已审核上架，其他视频保持不变。';
  } catch(error) { $('clip-review-error').textContent = error.message; }
  finally { $('clip-review-save').disabled = false; }
};
$('review-form').onsubmit = async event => {
  event.preventDefault(); if (!reviewing) return;
  const data = new FormData(event.target);
  if (data.get('decision') === 'rejected' && !data.get('note')?.trim()) {
    $('review-error').textContent = '请填写退回原因。'; return;
  }
  $('review-save').disabled = true;
  try {
    await api(`/admin/packages/${reviewing.id}/review`, { version: reviewing.version,
      decision: data.get('decision'), ...(data.get('decision') === 'rejected' ? {note:data.get('note')} : {}) });
    $('review-dialog').close(); await refresh();
    $('notice').textContent = data.get('decision') === 'approved' ? '审核通过，已入库，等待运营上架。' : '内容已退回修改，未发布。';
  } catch (error) { $('review-error').textContent = error.message; }
  finally { $('review-save').disabled = false; }
};
$('create').onsubmit = async event => {
  event.preventDefault(); const form = new FormData(event.target);
  const packaged = form.get('format') === 'package';
  const tags = selectedTags('create-tags');
  if (!tags.length) { $('form-error').textContent = '请至少选择一个题材标签。'; return; }
  const names = packaged ? []
    : (form.get('clips') || '').split('\n').map(x => x.trim()).filter(Boolean);
  if (form.get('format') === 'single' && names.length !== 1) { $('form-error').textContent = '独立视频只能填写一条；多条请选择角色视频包。'; return; }
  $('save').disabled = true;
  try {
    const created = await api('/admin/packages', { title: form.get('title'), description: form.get('description'), format: form.get('format'),
      tags,
      clips: names.map(name => ({ id: crypto.randomUUID(), title: name })) });
    $('editor').close(); await refresh(); selectedItemId = created.id; renderDetail(created); $('content-detail').showModal();
    contentNotice(packaged ? '角色包已创建，请上传角色主图和视频。' : '内容已创建，请上传视频，系统会自动生成缩略图。');
  } catch (error) { $('form-error').textContent = error.message; }
  finally { $('save').disabled = false; }
};

$('prev-page').onclick = () => { contentPage--; render(); };
$('next-page').onclick = () => { contentPage++; render(); };
$('detail-close').onclick = () => $('content-detail').close();
$('content-detail').addEventListener('close', () => { selectedItemId = null; clearPreviews(); $('detail-body').replaceChildren(); });
$('metadata-close').onclick = () => $('metadata-dialog').close();
$('metadata-form').onsubmit = async event => {
  event.preventDefault(); if (!metadataItem) return;
  const data = new FormData(event.target); $('metadata-save').disabled = true;
  try {
    await api(`/admin/packages/${encodeURIComponent(metadataItem.id)}/metadata`, { version: metadataItem.version,
      title: data.get('title'), description: data.get('description'), tags: selectedTags('metadata-tags'),
      translations: { ...metadataItem.translations, zh:{title:data.get('title'),description:data.get('description')}, en:{title:data.get('englishTitle'),description:data.get('englishDescription')} },
      clipTranslations: metadataItem.clips.map((clip,index) => ({id:clip.id,translations:{...clip.translations,
        zh:{title:data.get('clipChineseTitle'+index),description:data.get('clipChineseDescription'+index)},
        en:{title:data.get('clipEnglishTitle'+index),description:data.get('clipEnglishDescription'+index)}}})) });
    $('metadata-dialog').close(); await refresh(); $('notice').textContent = '内容介绍已更新。';
  } catch (error) { $('metadata-error').textContent = error.message; }
  finally { $('metadata-save').disabled = false; }
};
$('manage-tags').onclick = async () => {
  try { contentTags = (await api('/admin/content-tags')).items; $('tag-rows').replaceChildren(); contentTags.forEach(addTagRow); $('tags-error').textContent = ''; $('tags-dialog').showModal(); }
  catch (error) { $('notice').textContent = error.message; }
};
$('tags-close').onclick = () => $('tags-dialog').close();
$('tag-add').onclick = () => addTagRow();
$('tags-form').onsubmit = async event => {
  event.preventDefault(); $('tags-save').disabled = true;
  const tags = [...$('tag-rows').children].map(row => ({id:row.dataset.id, name:row.querySelector('input:not([type=checkbox])').value.trim(), active:row.querySelector('[type=checkbox]').checked, translations:{...row.translationValue,zh:{name:row.querySelector('input:not([type=checkbox])').value.trim()},en:{name:row.querySelector('.tag-english').value.trim()}}}));
  try {
    contentTags = (await api('/admin/content-tags', {items:tags})).items;
    $('tags-dialog').close(); refreshTagFilter(); $('notice').textContent = '题材标签库已更新。';
  } catch (error) { $('tags-error').textContent = error.message; }
  finally { $('tags-save').disabled = false; }
};
initCreatorManagement();
initOperatorManagement();
initAuditManagement();
$('notice').textContent = '正在检查登录状态…';
$('session-retry').onclick = () => restoreAdminSession();
restoreAdminSession();
