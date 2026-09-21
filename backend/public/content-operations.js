const contentOperationBusy = new Set();
const contentStates = [['','全部内容'],['draft','草稿'],['pending','待审核'],['approved','待上架'],['published','已上架'],['withdrawn','已下架'],['rejected','已退回'],['deleted','回收站']];
function renderContentTabs() {
  const target = $('content-state-tabs');
  target.replaceChildren();
  for (const [state,label] of contentStates) {
    const count = items.filter(item => state ? contentState(item) === state : !item.deletedAt).length;
    const button = text('button', `${label} ${count}`, 'content-state-tab');
    button.type = 'button'; button.dataset.state = state;
    button.classList.toggle('active', $('status').value === state);
    button.setAttribute('aria-pressed', String($('status').value === state));
    button.onclick = () => { $('status').value = state; resetPage(); };
    target.append(button);
  }
}
function contentNextStep(item) {
  if (item.deletedAt) return '已移入回收站，恢复后仍需按流程上架';
  if (item.governance?.hold) return '内容存在治理限制，请先处理版权或违规问题';
  return ({draft: '完善介绍和视频素材后提交审核', pending: '等待平台审核，通过后进入待上架', approved: '审核已通过，可以上架', published: '正在内容库展示，可下架后修改管理', withdrawn: '已停止展示，可重新上架或删除', rejected: '根据退回说明修改后重新送审'})[contentState(item)] || '';
}
function contentActionButton(item, action, label, permission) {
  const button = text('button', label, action === 'delete' ? 'secondary danger-action' : 'secondary');
  button.dataset.permission = permission;
  button.disabled = contentOperationBusy.has(item.id);
  button.onclick = () => runContentAction(item, action);
  return button;
}
function appendContentActions(target, item) {
  const state = contentState(item);
  if (state === 'deleted') target.append(contentActionButton(item, 'restore', '恢复内容', 'content.delete'));
  else {
    if (state === 'approved' || state === 'withdrawn') target.append(contentActionButton(item, 'publish', state === 'withdrawn' ? '重新上架' : '上架', 'content.publish'));
    if (state === 'published') target.append(contentActionButton(item, 'withdraw', '下架', 'content.withdraw'));
    if (['draft','rejected','withdrawn'].includes(state)) target.append(contentActionButton(item, 'delete', '删除', 'content.delete'));
  }
}
async function runContentAction(item, action) {
  if (contentOperationBusy.has(item.id)) return;
  const prompts = {
    publish: `确认${item.status === 'withdrawn' ? '重新' : ''}上架“${item.title}”？系统将校验审核与素材状态，通过后对用户可见。`,
    withdraw: `确认下架“${item.title}”？下架后不再出现在内容库，可稍后重新上架。`,
    delete: `确认删除“${item.title}”？内容将移入回收站，可恢复；不会立即销毁视频文件。`,
    restore: `确认恢复“${item.title}”？恢复后不会自动上架。`,
  };
  if (!prompts[action] || !confirm(prompts[action])) return;
  contentOperationBusy.add(item.id); render();
  try {
    await api(`/admin/packages/${encodeURIComponent(item.id)}/${action}`, {version:item.version});
    await refresh();
    contentNotice(({publish:'内容已上架。',withdraw:'内容已下架。',delete:'内容已移入回收站。',restore:'内容已恢复，请检查后再上架。'})[action]);
  } catch (error) { contentNotice(error.message); }
  finally { contentOperationBusy.delete(item.id); render(); }
}
