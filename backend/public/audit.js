let auditRequest = 0;
function canViewAudit() { return typeof canAdmin === 'function' && canAdmin('audit.view'); }
function clearAudit() {
  ++auditRequest;
  if ($('audit-records')) $('audit-records').replaceChildren();
  if ($('audit-message')) $('audit-message').textContent = '';
  if ($('audit-refresh')) $('audit-refresh').disabled = false;
}
function auditDate(value) { const date = new Date(value); return value && Number.isFinite(date.getTime()) ? date.toLocaleString('zh-CN') : '未记录'; }
const auditActionLabels = {createOperator:'创建运营账号',updateOperator:'修改运营账号',resetOperatorPassword:'重置运营密码',createPackage:'创建内容',updatePackage:'编辑内容',deletePackage:'删除内容',publishPackage:'上架内容',withdrawPackage:'下架内容',reviewPackage:'审核内容',publishClip:'上架单条视频',withdrawClip:'下架单条视频',updateClipPricing:'调整视频价格',reviewCreator:'审核创作者',updateOrder:'处理订单',dispatchOrder:'派单',recoverOrder:'恢复历史订单',saveLayout:'保存页面草稿',publishLayout:'发布页面',rollbackLayout:'回滚页面'};
Object.assign(auditActionLabels, {'operator.create':'创建运营账号','operator.update':'修改运营账号','operator.password':'重置运营密码',updateMetadata:'编辑内容介绍',saveContentTags:'更新题材标签',transition:'更改内容上架状态',transitionClip:'更改单条视频上架状态',review:'审核内容',restorePackage:'恢复内容',updateCustomizationOrderWorkflow:'处理订单',saveLayoutDraft:'保存页面草稿',manageCreator:'修改创作者审核与权限'});
async function refreshAudit() {
  if (!canViewAudit()) { clearAudit(); return; }
  const request = ++auditRequest, target = $('audit-records'), message = $('audit-message'), refresh = $('audit-refresh');
  if (!target || !message) return;
  target.replaceChildren(); message.textContent = '正在读取运营日志…'; if (refresh) refresh.disabled = true;
  try {
    const data = await api('/admin/audit');
    if (request !== auditRequest || !canViewAudit()) return;
    const operations = Array.isArray(data.operations) ? data.operations : [];
    if (!operations.length) { message.textContent = '暂无运营操作记录。'; return; }
    const table = text('table', '', 'creator-table'), head = text('thead'), header = text('tr');
    for (const label of ['操作时间', '操作账号', '操作', '目标编号', '所需权限']) header.append(text('th', label));
    head.append(header); table.append(head); const body = text('tbody');
    for (const entry of operations) {
      const row = text('tr');
      row.append(text('td', auditDate(entry.createdAt)), text('td', entry.actor || entry.actorId || '未记录'), text('td', auditActionLabels[entry.action] || entry.action || '未记录'), text('td', entry.targetId || '—'), text('td', Array.isArray(entry.permissions) ? entry.permissions.join('、') || '—' : '—'));
      body.append(row);
    }
    table.append(body); target.append(table); message.textContent = `最近 ${operations.length} 条运营操作记录（最多 500 条）。`;
  } catch (error) { if (request === auditRequest && canViewAudit()) { target.replaceChildren(); message.textContent = `${error.message} 请刷新日志后重试。`; } }
  finally { if (request === auditRequest && refresh) refresh.disabled = false; }
}
function initAuditManagement() { if ($('audit-refresh')) $('audit-refresh').onclick = refreshAudit; }
