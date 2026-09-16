const $ = id => document.getElementById(id);
let items = [], epoch = 0;
let orders = [], creators = [], activeView = 'content';
let layoutState = null, layoutPage = 'collection', draggedLayoutIndex = null, layoutSavedSnapshot = '';
let reviewing = null;
const previews = new Set();
function showConnection(connected) {
  $('login').hidden = connected;
  $('connected').hidden = !connected;
}
function clearPreviews() { for (const url of previews) URL.revokeObjectURL(url); previews.clear(); }
const messages = { UNAUTHORIZED: '登录已过期，请重新登录。', INVALID_CREDENTIALS: '用户名或密码错误。', VERSION_OR_STATE_CONFLICT: '内容已被更新，请刷新后重试。', INVALID_ORDER_TRANSITION: '不能跳过必要步骤，请按流程推进订单。', MEDIA_REVIEW_REQUIRED: '需要先完成素材处理和审核。', INVALID_PACKAGE: '请检查名称、视频数量和标签。' };
async function api(path, body) {
  const response = await fetch(path, { method: body === undefined ? 'GET' : 'POST',
    headers: { 'Content-Type': 'application/json' }, credentials: 'same-origin',
    body: body === undefined ? undefined : JSON.stringify(body) });
  const result = await response.json();
  if (!response.ok) throw new Error(messages[result.code] || '操作失败，请稍后重试。');
  return result;
}
function text(tag, value, className) { const el = document.createElement(tag); el.textContent = value; if (className) el.className = className; return el; }
const orderLabels = { free_review: '待预审', needs_info: '待补充资料', approved_for_quote: '待报价', quoted: '待用户确认报价', in_production: '制作中', quality_review: '待平台质检', user_acceptance: '待用户验收', delivered: '已交付', rejected: '预审未通过', withdrawn: '已撤回' };
const orderSteps = ['free_review','approved_for_quote','quoted','in_production','quality_review','user_acceptance','delivered'];
const orderTransitions = { free_review: ['needs_info','approved_for_quote','rejected'], needs_info: ['free_review','approved_for_quote','rejected'], approved_for_quote: ['quoted','needs_info','rejected'], quoted: ['in_production','needs_info','withdrawn'], in_production: ['quality_review'], quality_review: ['in_production','user_acceptance'], user_acceptance: ['quality_review','delivered'], delivered: [], rejected: ['free_review'], withdrawn: [] };
const creatorLabels = { pending: '待审核', approved: '已认证', rejected: '未通过', suspended: '已停用' };
function showView(view) {
  activeView = view;
  document.querySelectorAll('[data-panel]').forEach(panel => panel.hidden = panel.dataset.panel !== view);
  document.querySelectorAll('[data-view]').forEach(button => button.classList.toggle('active', button.dataset.view === view));
  $('notice').textContent = view === 'content' ? '管理 App 内容目录。' : view === 'orders' ? '管理角色定制业务订单。' : view === 'creators' ? '审核和管理创作者资格。' : '拖拽管理 App 的运营模块。';
}
function actionSelect(options, selected) {
  const select = document.createElement('select');
  for (const [value, label] of Object.entries(options)) { const option = document.createElement('option'); option.value = value; option.textContent = label; option.selected = value === selected; select.append(option); }
  return select;
}
function renderOrders() {
  $('orders-total').textContent = orders.length;
  $('orders-review').textContent = orders.filter(x => x.status === 'free_review').length;
  $('orders-production').textContent = orders.filter(x => x.status === 'in_production').length;
  const visible = orders.filter(x => !$('order-status').value || x.status === $('order-status').value);
  $('order-cards').replaceChildren();
  for (const order of visible) {
    const card = text('article', '', 'card order-card');
    card.append(text('span', orderLabels[order.status] || order.status, 'status'), text('h2', order.characterName),
      text('div', `${order.sourceType} · ${order.marketRegion} · ${order.materialCount}份素材`, 'meta'),
      text('p', `需求：${(order.requestedFeatures || []).join(' / ') || '未填写'}`),
      text('p', `订单号：${order.id}`),
      text('p', order.materialsUploaded ? '私有素材已上传' : '仅同步需求元数据，原始素材未上传'));
    const progress = text('div', '', 'order-progress'), activeIndex = orderSteps.indexOf(order.status);
    orderSteps.forEach((step, index) => { const node = text('div', '', `order-step${index < activeIndex ? ' done' : index === activeIndex ? ' current' : ''}`); node.append(text('span', index < activeIndex ? '✓' : String(index + 1)), text('small', orderLabels[step])); progress.append(node); });
    card.append(progress);
    const note = document.createElement('textarea'); note.rows = 2; note.maxLength = 1000; note.placeholder = '填写本次处理说明，用户端后续可同步查看';
    const actions = text('div', '', 'order-actions');
    for (const next of orderTransitions[order.status] || []) {
      const button = text('button', orderLabels[next], next === 'rejected' || next === 'withdrawn' ? 'danger' : next === 'needs_info' ? 'secondary' : '');
      button.onclick = async () => { if ((next === 'needs_info' || next === 'rejected') && !note.value.trim()) { $('notice').textContent = '退回或拒绝时必须填写处理说明。'; note.focus(); return; } for (const item of actions.querySelectorAll('button')) item.disabled = true; try { await api(`/admin/customization-orders/${encodeURIComponent(order.id)}`, { version: order.version, status: next, note: note.value }); await refreshOrders(); $('notice').textContent = `订单已更新为“${orderLabels[next]}”。`; } catch (error) { $('notice').textContent = error.message; for (const item of actions.querySelectorAll('button')) item.disabled = false; } };
      actions.append(button);
    }
    card.append(text('h3', '下一步处理'), note, actions);
    const history = text('details', '', 'order-history'); history.append(text('summary', `处理记录（${(order.workflowHistory || []).length}）`));
    for (const item of [...(order.workflowHistory || [])].reverse()) history.append(text('p', `${new Date(item.at).toLocaleString()}　${orderLabels[item.from] || item.from} → ${orderLabels[item.to] || item.to}${item.note ? `｜${item.note}` : ''}`));
    card.append(history); $('order-cards').append(card);
  }
  if (!visible.length) $('order-cards').append(text('p', '当前没有定制订单。App 更新并提交新需求后会显示在这里。', 'empty'));
}
function renderCreators() {
  $('creators-total').textContent = creators.length;
  $('creators-pending').textContent = creators.filter(x => x.status === 'pending').length;
  $('creators-approved').textContent = creators.filter(x => x.status === 'approved').length;
  const visible = creators.filter(x => !$('creator-status').value || x.status === $('creator-status').value);
  $('creator-cards').replaceChildren();
  for (const creator of visible) {
    const card = text('article', '', 'card');
    card.append(text('span', creatorLabels[creator.status] || creator.status, 'status'), text('h2', creator.displayName),
      text('div', `${creator.marketRegion} · ${(creator.skillTags || []).join(' / ') || '未填写技能'}`, 'meta'),
      text('p', `邮箱：${creator.email || '旧申请待补充'}`),
      text('p', `作品集：${creator.portfolioUrl || '未填写'}`), text('p', `申请编号：${creator.id}`));
    const select = actionSelect(creatorLabels, creator.status), note = document.createElement('input'); note.placeholder = '审核说明（建议填写）';
    const save = text('button', '保存审核结果', 'secondary');
    save.onclick = async () => { save.disabled = true; try { await api(`/admin/creators/${encodeURIComponent(creator.id)}`, { version: creator.version, status: select.value, note: note.value }); await refreshCreators(); $('notice').textContent = '创作者状态已更新。'; } catch (error) { $('notice').textContent = error.message; save.disabled = false; } };
    card.append(select, note, save); $('creator-cards').append(card);
  }
  if (!visible.length) $('creator-cards').append(text('p', '当前没有创作者申请。App 更新并提交申请后会显示在这里。', 'empty'));
}
async function refreshOrders() { orders = (await api('/admin/customization-orders')).items; renderOrders(); }
async function refreshCreators() { creators = (await api('/admin/creators')).items; renderCreators(); }
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
    const row = text('div', '', 'layout-block'); row.draggable = true;
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
function render() {
  clearPreviews();
  $('total').textContent = items.length;
  $('published').textContent = items.filter(x => x.status === 'published').length;
  $('drafts').textContent = items.filter(x => x.status === 'draft').length;
  const visible = items.filter(x => (! $('status').value || x.status === $('status').value)
    && `${x.title} ${x.tags.join(' ')}`.toLowerCase().includes($('search').value.trim().toLowerCase()));
  $('cards').replaceChildren();
  for (const item of visible) {
    const card = text('article', '', 'card');
    card.append(text('span', { published: '已发布', draft: '草稿', withdrawn: '已下架' }[item.status], 'status'),
      text('h2', item.title), text('div', `${item.source === 'hildors' ? 'HILDORS出品' : '创作者作品'} · ${item.format === 'single' ? '独立视频' : '角色视频包'} · ${item.clips.length}个视频`, 'meta'),
      text('p', item.tags.join(' / ') || '未设置题材标签'));
    const list = document.createElement('ul');
    for (const clip of item.clips) {
      const row = text('li', clip.title);
      if (clip.media) {
        row.append(text('p', `${(clip.media.bytes / 1024 / 1024).toFixed(1)} MB · 待审核 · 待设备适配`));
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
        if (item.status === 'draft') {
          const check = text('button', inspection ? '重新检查素材' : '检查并生成缩略图', 'secondary');
          check.onclick = async () => {
            check.disabled = true; check.textContent = '正在检查…';
            try {
              const result = await api(`/admin/packages/${encodeURIComponent(item.id)}/clips/${encodeURIComponent(clip.id)}/inspect`, {});
              await refresh();
              const checked = result.clips.find(c => c.id === clip.id)?.media?.inspection;
              $('notice').textContent = checked?.status === 'checked' ? '编码检查和缩略图已完成，仍需内容审核及设备适配。' : '检查未通过，请查看素材提示后重试。';
            } catch (error) { $('notice').textContent = error.message; check.disabled = false; check.textContent = '重试检查'; }
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
      if (item.status === 'draft') {
        const label = text('label', clip.media ? '替换MP4素材' : '上传MP4素材');
        const input = document.createElement('input'); input.type = 'file'; input.accept = '.mp4,video/mp4';
        input.onchange = async () => {
          const file = input.files[0]; if (!file) return;
          if (file.size > 256 * 1024 * 1024) { $('notice').textContent = '本地原型单次上传限制为256MB。'; input.value = ''; return; }
          input.disabled = true; $('notice').textContent = '正在上传素材，请保持页面打开…';
          try {
            const response = await fetch(`/admin/packages/${encodeURIComponent(item.id)}/clips/${encodeURIComponent(clip.id)}/media`, {
              method: 'PUT', credentials: 'same-origin', headers: { 'Content-Type': 'video/mp4', 'If-Match': String(item.version) }, body: file });
            const result = await response.json();
            if (!response.ok) throw new Error(messages[result.code] || '上传失败，请确认是有效的MP4文件后重试。');
            await refresh(); $('notice').textContent = '素材已保存，等待编码检查、审核和设备适配。';
          } catch (error) { $('notice').textContent = error.message; input.disabled = false; }
        };
        label.append(input); row.append(label);
      }
      list.append(row);
    }
    const allMedia = item.clips.every(c => c.media);
    const allChecked = item.clips.every(c => c.media?.inspection?.status === 'checked');
    card.append(list, text('p', item.demo ? '内置演示素材 · 厂家转码待接入' : item.status === 'published' ? '已发布到 App 内容目录' : !allMedia ? '下一步：为每个视频上传 MP4 素材' : !allChecked ? '下一步：检查全部素材并生成缩略图' : item.review?.decision === 'approved' ? '审核已通过，可发布到 App' : '素材已就绪，可审核并发布到 App', 'workflow-hint'));
    if (item.review) card.append(text('p', `审核：${item.review.decision === 'approved' ? '已通过' : '退回修改'} · ${item.review.note}`));
    if (item.status === 'draft' && allChecked && item.review?.decision !== 'approved') {
      const reviewButton = text('button', '审核并发布到 App', 'publish-action');
      reviewButton.onclick = () => {
        reviewing = item; $('review-form').reset(); $('review-error').textContent = '';
        $('review-title').textContent = item.title; $('review-dialog').showModal();
      };
      card.append(reviewButton);
    }
    if (item.status === 'draft' && !allChecked) {
      const unavailable = text('button', allMedia ? '完成素材检查后可发布' : '上传全部素材后可发布', 'publish-action');
      unavailable.disabled = true; card.append(unavailable);
    }
    if (item.status === 'draft' && item.review?.decision === 'approved') {
      const publish = text('button', '发布到 App', 'publish-action');
      publish.onclick = async () => {
        if (!confirm('发布后将出现在本地目录接口中，硬件下载与转码仍未开放。确认发布？')) return;
        publish.disabled = true;
        try { await api(`/admin/packages/${item.id}/publish`, { version: item.version }); await refresh(); $('notice').textContent = '目录已发布。设备适配及云端下载仍未开放。'; }
        catch (error) { $('notice').textContent = error.message; publish.disabled = false; }
      };
      card.append(publish);
    }
    if (item.status === 'published') {
      const button = text('button', '下架内容', 'secondary');
      button.onclick = async () => {
        if (!confirm(`确认下架“${item.title}”？下架后目录不再展示。`)) return;
        button.disabled = true;
        try { await api(`/admin/packages/${encodeURIComponent(item.id)}/withdraw`, { version: item.version }); await refresh(); $('notice').textContent = '内容已下架。'; }
        catch (error) { $('notice').textContent = error.message; button.disabled = false; }
      };
      card.append(button);
    }
    $('cards').append(card);
  }
  if (!visible.length) $('cards').append(text('p', '暂无符合条件的内容。', 'empty'));
}
async function refresh() {
  const current = epoch;
  const result = await api('/admin/packages');
  if (current !== epoch) return;
  items = result.items; render(); showView(activeView);
}
$('login').onsubmit = async event => {
  event.preventDefault(); epoch++;
  $('workspace').hidden = true;
  try { await api('/admin/login', { username: $('username').value.trim(), password: $('password').value }); $('password').value = ''; await refresh(); showConnection(true); $('notice').textContent = '后台已登录。'; }
  catch (error) { $('password').value = ''; showConnection(false); $('notice').textContent = error.message; }
};
$('logout').onclick = async () => { epoch++; await api('/admin/logout', {}).catch(() => {}); clearPreviews(); items = []; orders = []; creators = []; layoutState = null; reviewing = null; showConnection(false); document.querySelectorAll('[data-panel]').forEach(x => x.hidden = true); $('cards').replaceChildren(); $('editor').close(); $('review-dialog').close(); $('notice').textContent = '已安全退出后台。'; };
$('refresh').onclick = async () => { try { await refresh(); $('notice').textContent = '内容已刷新。'; } catch (error) { $('notice').textContent = error.message; } };
$('search').oninput = render; $('status').onchange = render;
$('order-status').onchange = renderOrders; $('creator-status').onchange = renderCreators;
$('orders-refresh').onclick = () => refreshOrders().catch(error => $('notice').textContent = error.message);
$('creators-refresh').onclick = () => refreshCreators().catch(error => $('notice').textContent = error.message);
document.querySelectorAll('[data-view]').forEach(button => button.onclick = async () => {
  try { if (button.dataset.view === 'orders') await refreshOrders(); if (button.dataset.view === 'creators') await refreshCreators(); if (button.dataset.view === 'layout') await refreshLayout(); showView(button.dataset.view); }
  catch (error) { $('notice').textContent = error.message; }
});
document.querySelectorAll('[data-layout-page]').forEach(button => button.onclick = () => { layoutPage = button.dataset.layoutPage; renderLayout(); });
$('layout-save').onclick = async () => { try { layoutState = await api('/admin/layout/draft', { version: layoutState.version, layout: layoutState.draft }); layoutSavedSnapshot = JSON.stringify(layoutState.draft); renderLayout(); $('notice').textContent = '页面装修草稿已保存，尚未影响用户。'; } catch (error) { $('notice').textContent = error.message; } };
$('layout-publish').onclick = async () => { if (JSON.stringify(layoutState.draft) !== layoutSavedSnapshot) { $('notice').textContent = '请先保存草稿，再发布到 App。'; return; } const visible = Object.values(layoutState.draft.pages).flat().filter(x => x.visible).length; if (!confirm(`确认发布预览中的布局？\n本次共显示 ${visible} 个模块，用户下次刷新后生效。`)) return; try { layoutState = await api('/admin/layout/publish', { version: layoutState.version }); layoutSavedSnapshot = JSON.stringify(layoutState.draft); renderLayout(); $('layout-dirty').textContent = '已发布'; $('layout-dirty').className = 'layout-dirty published'; $('notice').textContent = '新版布局已发布到 App。'; } catch (error) { $('notice').textContent = error.message; } };
$('layout-rollback').onclick = async () => { if (JSON.stringify(layoutState.draft) !== layoutSavedSnapshot && !confirm('当前有未保存修改，回滚将丢弃这些修改。是否继续？')) return; if (!confirm('确认恢复上一版已发布布局？恢复后会立即影响 App。')) return; try { layoutState = await api('/admin/layout/rollback', { version: layoutState.version }); layoutSavedSnapshot = JSON.stringify(layoutState.draft); renderLayout(); $('notice').textContent = '已恢复上一版布局。'; } catch (error) { $('notice').textContent = error.message; } };
window.addEventListener('beforeunload', event => { if (layoutState && JSON.stringify(layoutState.draft) !== layoutSavedSnapshot) { event.preventDefault(); event.returnValue = ''; } });
$('new').onclick = () => { $('create').reset(); $('form-error').textContent = ''; $('editor').showModal(); };
$('close').onclick = () => $('editor').close();
$('review-close').onclick = () => $('review-dialog').close();
$('review-form').onsubmit = async event => {
  event.preventDefault(); if (!reviewing) return;
  const data = new FormData(event.target);
  if (data.get('decision') === 'approved' && (!data.has('rightsConfirmed') || !data.get('rightsReference').trim())) {
    $('review-error').textContent = '通过审核前，请核对授权并填写材料记录。'; return;
  }
  $('review-save').disabled = true;
  try {
    const reviewed = await api(`/admin/packages/${reviewing.id}/review`, { version: reviewing.version,
      decision: data.get('decision'), note: data.get('note'), rightsReference: data.get('rightsReference'), rightsConfirmed: data.has('rightsConfirmed') });
    if (data.get('decision') === 'approved') {
      await api(`/admin/packages/${reviewing.id}/publish`, { version: reviewed.version });
      $('notice').textContent = '审核通过，内容已发布到 App 目录。';
    } else { $('notice').textContent = '内容已退回修改，未发布。'; }
    $('review-dialog').close(); await refresh();
  } catch (error) { $('review-error').textContent = error.message; }
  finally { $('review-save').disabled = false; }
};
$('create').onsubmit = async event => {
  event.preventDefault(); const form = new FormData(event.target);
  const names = form.get('clips').split('\n').map(x => x.trim()).filter(Boolean);
  if (form.get('format') === 'single' && names.length !== 1) { $('form-error').textContent = '独立视频只能填写一条；多条请选择角色视频包。'; return; }
  $('save').disabled = true;
  try {
    await api('/admin/packages', { title: form.get('title'), source: form.get('source'), format: form.get('format'),
      tags: [...new Set(form.get('tags').split(/[,，]/).map(x => x.trim()).filter(Boolean))],
      clips: names.map(name => ({ id: crypto.randomUUID(), title: name })) });
    $('editor').close(); await refresh(); $('notice').textContent = '草稿已保存。下一步需要补充素材并审核。';
  } catch (error) { $('form-error').textContent = error.message; }
  finally { $('save').disabled = false; }
};

$('notice').textContent = '正在检查登录状态…';
refresh().then(() => { showConnection(true); $('notice').textContent = '后台已登录。'; })
  .catch(() => { showConnection(false); $('workspace').hidden = true; $('notice').textContent = '请使用管理员账号登录。'; });
