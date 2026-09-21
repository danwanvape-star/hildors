let adminActor = null, adminPermissionSet = new Set(), adminIdentityRequest = 0;
let operatorItems = [], operatorCatalog = [], operatorPresets = [], operatorRequest = 0, operatorEditing = null, operatorSaving = false;
const operatorPermissionInputs = new Map();
function canAdmin(permission) { return Boolean(adminActor) && (adminActor.isRoot === true || adminPermissionSet.has(permission)); }
function applyAdminPermissions() {
  for (const element of document.querySelectorAll('[data-permission]')) element.hidden = !canAdmin(element.dataset.permission);
}
async function refreshAdminIdentity() {
  const request = ++adminIdentityRequest;
  adminActor = null; adminPermissionSet.clear(); applyAdminPermissions();
  try {
    const data = await api('/admin/me');
    if (request !== adminIdentityRequest) return null;
    if (!data.actor || !Array.isArray(data.permissions)) throw new Error('无法确认当前账号权限，请重新登录。');
    adminActor = data.actor; adminPermissionSet = new Set(data.permissions); applyAdminPermissions();
    return data;
  } catch (error) {
    if (request === adminIdentityRequest) { adminActor = null; adminPermissionSet.clear(); applyAdminPermissions(); }
    throw error;
  }
}
function operatorButton(label, handler) { const button = text('button', label, 'secondary'); button.type = 'button'; button.onclick = handler; return button; }
function operatorError(message) { const el = $('operators-error'); if (el) el.textContent = message; }
function closeOperatorEditor() {
  const dialog = $('operator-editor'); if (dialog) dialog.close();
  for (const id of ['operator-password', 'operator-password-confirm']) if ($(id)) $(id).value = '';
  operatorEditing = null;
}
function clearOperatorManagement() {
  ++adminIdentityRequest; ++operatorRequest; adminActor = null; adminPermissionSet.clear();
  operatorItems = []; operatorCatalog = []; operatorPresets = []; operatorPermissionInputs.clear();
  operatorSaving = false; closeOperatorEditor();
  if ($('operator-cards')) $('operator-cards').replaceChildren();
  operatorError(''); applyAdminPermissions();
}
async function refreshOperators() {
  if (!canAdmin('operators.manage')) return;
  const request = ++operatorRequest, identity = adminIdentityRequest;
  operatorError(''); if ($('operators-refresh')) $('operators-refresh').disabled = true;
  try {
    const [accounts, permissions] = await Promise.all([api('/admin/operators'), api('/admin/permissions')]);
    if (request !== operatorRequest || identity !== adminIdentityRequest || !canAdmin('operators.manage')) return;
    operatorItems = accounts.items; operatorCatalog = permissions.catalog; operatorPresets = permissions.presets;
    renderOperators();
  } catch (error) {
    if (request === operatorRequest && identity === adminIdentityRequest) { operatorItems = []; if ($('operator-cards')) $('operator-cards').replaceChildren(); operatorError(`${error.message} 请刷新账号列表后重试。`); }
  } finally { if (request === operatorRequest && $('operators-refresh')) $('operators-refresh').disabled = false; }
}
function renderOperators() {
  const list = $('operator-cards'); if (!list) return; list.replaceChildren();
  const root = text('article', '', 'operator-root'); root.append(text('strong', '主管理员（环境配置账号）'), text('p', '拥有全部权限，由服务器环境配置维护，不能在此编辑或停用。')); list.append(root);
  if (!operatorItems.length) { list.append(text('p', '尚未创建运营账号。点击“创建运营账号”分配岗位与操作权限。', 'empty')); return; }
  const table = text('table', '', 'operator-table'), head = text('thead'), labels = text('tr');
  for (const label of ['运营账号', '状态', '已授权操作', '操作']) labels.append(text('th', label)); head.append(labels); table.append(head);
  const body = text('tbody');
  for (const item of operatorItems) {
    const row = text('tr'), name = text('td'), actions = text('td'); name.append(text('strong', item.displayName || item.username), text('p', item.username));
    actions.append(operatorButton('编辑权限', () => openOperatorEditor(item)), operatorButton('重置密码', () => openOperatorEditor(item, true)), operatorButton(item.active ? '停用账号' : '启用账号', () => toggleOperatorActive(item)));
    row.append(name, text('td', item.active ? '启用中' : '已停用'), text('td', `${item.permissions.length} 项权限`), actions); body.append(row);
  }
  table.append(body); list.append(table);
}
function selectedOperatorPermissions() { return [...operatorPermissionInputs].filter(([, input]) => input.checked).map(([id]) => id); }
function updateOperatorPermissionReview() {
  const selected = new Set(selectedOperatorPermissions()), review = $('operator-permission-review');
  if (review) review.textContent = selected.size ? `将授予 ${selected.size} 项操作：${operatorCatalog.filter(item => selected.has(item.id)).map(item => item.label).join('、')}` : '未选择任何操作权限：此账号可登录，但无法访问业务模块。';
}
function applyOperatorPreset(id) {
  const preset = operatorPresets.find(item => item.id === id); if (!preset) return;
  const selected = new Set(preset.permissions);
  for (const [key, input] of operatorPermissionInputs) input.checked = selected.has(key);
  updateOperatorPermissionReview();
}
function renderOperatorPermissions(selected = []) {
  const container = $('operator-permissions'); container.replaceChildren(); operatorPermissionInputs.clear();
  const presets = $('operator-presets'); presets.replaceChildren();
  for (const preset of operatorPresets) presets.append(operatorButton(preset.label, () => applyOperatorPreset(preset.id)));
  const chosen = new Set(selected), groups = new Map();
  for (const permission of operatorCatalog) { if (!groups.has(permission.group)) groups.set(permission.group, []); groups.get(permission.group).push(permission); }
  for (const [group, permissions] of groups) {
    const fieldset = text('fieldset', '', 'operator-permission-group'); fieldset.append(text('legend', group));
    const controls = text('div', '', 'operator-group-actions');
    for (const [label, checked] of [['本组全选', true], ['本组清空', false]]) controls.append(operatorButton(label, () => { for (const permission of permissions) operatorPermissionInputs.get(permission.id).checked = checked; updateOperatorPermissionReview(); }));
    fieldset.append(controls);
    for (const permission of permissions) {
      const label = text('label', '', 'operator-check'), input = document.createElement('input'); input.type = 'checkbox'; input.value = permission.id; input.checked = chosen.has(permission.id); input.onchange = updateOperatorPermissionReview;
      operatorPermissionInputs.set(permission.id, input); label.append(input, text('span', permission.label)); fieldset.append(label);
    }
    container.append(fieldset);
  }
  updateOperatorPermissionReview();
}
function openOperatorEditor(item = null, passwordOnly = false) {
  if (!canAdmin('operators.manage') || operatorSaving) return;
  if (!operatorCatalog.length) { operatorError('权限目录尚未加载，请先刷新运营账号。'); return; }
  operatorEditing = item ? {...item, passwordOnly} : null;
  $('operator-editor-title').textContent = passwordOnly ? `重置密码 · ${item.username}` : item ? `编辑运营账号 · ${item.username}` : '创建运营账号';
  $('operator-username').value = item?.username || ''; $('operator-username').disabled = Boolean(item);
  $('operator-display-name').value = item?.displayName || ''; $('operator-active').checked = item?.active ?? true;
  $('operator-account-fields').hidden = passwordOnly; $('operator-permission-fields').hidden = passwordOnly;
  $('operator-password-fields').hidden = Boolean(item) && !passwordOnly;
  for (const id of ['operator-password', 'operator-password-confirm']) { $(id).value = ''; $(id).required = !item || passwordOnly; }
  $('operator-form-error').textContent = ''; $('operator-save').disabled = false;
  $('operator-save').textContent = passwordOnly ? '确认重置密码' : '确认并保存账号';
  renderOperatorPermissions(item?.permissions || []); $('operator-editor').showModal();
}
async function saveOperator(event) {
  event.preventDefault(); if (operatorSaving || !canAdmin('operators.manage')) return;
  const item = operatorEditing, identity = adminIdentityRequest, passwordNeeded = !item || item.passwordOnly;
  $('operator-form-error').textContent = '';
  if (passwordNeeded && ($('operator-password').value.length < 12 || $('operator-password').value.length > 128 || $('operator-password').value !== $('operator-password-confirm').value)) {
    $('operator-form-error').textContent = '密码须为 12–128 个字符，两次输入必须一致。'; return;
  }
  if (item && item.active && !item.passwordOnly && !$('operator-active').checked && !confirm(`确定停用账号“${item.username}”？该账号的现有登录会话将立即失效。`)) return;
  const body = item?.passwordOnly ? {version:item.version, password:$('operator-password').value} : {
    displayName:$('operator-display-name').value.trim(), active:$('operator-active').checked, permissions:selectedOperatorPermissions(),
    ...(item ? {version:item.version} : {username:$('operator-username').value.trim(), password:$('operator-password').value})
  };
  const path = item ? `/admin/operators/${encodeURIComponent(item.id)}${item.passwordOnly ? '/password' : ''}` : '/admin/operators';
  operatorSaving = true; $('operator-save').disabled = true;
  try {
    await api(path, body);
    if (identity !== adminIdentityRequest) return;
    closeOperatorEditor(); operatorError('账号已保存。权限、状态或密码变更后，该账号需要重新登录。'); await refreshOperators();
  } catch (error) {
    if (identity === adminIdentityRequest) $('operator-form-error').textContent = `${error.message} 如账号已被他人修改，请关闭并刷新列表后重试。`;
  } finally {
    delete body.password;
    if (identity === adminIdentityRequest) { for (const id of ['operator-password', 'operator-password-confirm']) $(id).value = ''; operatorSaving = false; $('operator-save').disabled = false; }
  }
}
async function toggleOperatorActive(item) {
  if (!canAdmin('operators.manage') || operatorSaving) return;
  if (!confirm(item.active ? `确定停用账号“${item.username}”？现有登录会话将立即失效。` : `确定启用账号“${item.username}”？`)) return;
  const identity = adminIdentityRequest; operatorSaving = true;
  try { await api(`/admin/operators/${encodeURIComponent(item.id)}`, {version:item.version, active:!item.active, displayName:item.displayName, permissions:item.permissions}); if (identity === adminIdentityRequest) await refreshOperators(); }
  catch (error) { if (identity === adminIdentityRequest) operatorError(`${error.message} 请刷新列表后重试。`); }
  finally { if (identity === adminIdentityRequest) operatorSaving = false; }
}
function initOperatorManagement() {
  if (!$('operator-form')) return;
  $('operators-new').onclick = () => openOperatorEditor(); $('operators-refresh').onclick = refreshOperators;
  $('operator-form').onsubmit = saveOperator;
  $('operator-editor-close').onclick = () => { if (!operatorSaving) closeOperatorEditor(); };
  $('operator-editor').addEventListener('cancel', event => { if (operatorSaving) event.preventDefault(); else closeOperatorEditor(); });
  $('operator-editor').addEventListener('close', () => { for (const id of ['operator-password', 'operator-password-confirm']) $(id).value = ''; });
  applyAdminPermissions();
}
