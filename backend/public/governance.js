const list = document.querySelector('#reports'), message = document.querySelector('#message');
let governanceRequest = 0, governanceCanManage = false;
async function request(path, body) {
  const response = await fetch(path, {method:body ? 'POST' : 'GET', headers:body ? {'Content-Type':'application/json'} : {}, body:body ? JSON.stringify(body) : undefined, credentials:'same-origin'});
  if (!response.ok) throw new Error(response.status === 401 ? '请先返回管理后台登录。' : response.status === 403 ? '当前账号没有此操作权限。' : response.status === 409 ? '记录已更新，请刷新后重试。' : '操作失败，请稍后重试。');
  return response.json();
}
const el = (tag, text) => { const node = document.createElement(tag); node.textContent = text; return node; };
async function load() {
  const generation = ++governanceRequest;
  governanceCanManage = false; list.replaceChildren(); message.textContent = '读取中…';
  try {
    const identity = await request('/admin/me');
    if (generation !== governanceRequest) return;
    if (identity.actor?.mustChangePassword) { message.textContent = '请返回管理后台，先修改本人密码，再进入此页面。'; return; }
    const permissions = new Set(Array.isArray(identity.permissions) ? identity.permissions : []);
    const allowed = key => Boolean(identity.actor) && (identity.actor.isRoot === true || permissions.has(key));
    if (!allowed('governance.view')) { message.textContent = '当前账号没有查看举报的权限。'; return; }
    governanceCanManage = allowed('governance.manage');
    const data = await request('/admin/reports');
    if (generation !== governanceRequest) return;
    for (const report of data.items) {
      const section = el('section', ''); section.style.cssText = 'border:1px solid #aaa;padding:1rem;margin:1rem 0';
      section.append(el('h2', `${report.reason} · ${report.status}`), el('p', `编号：${report.id} / 内容：${report.packageId}`), el('p', `用户：${report.userId} / ${report.createdAt}`), el('p', report.details));
      if (!governanceCanManage) {
        section.append(el('p', `处理说明：${report.resolution || '尚未填写'}`), el('p', '当前账号仅可查看，未获授权处理举报。'));
      } else {
        const status = el('select', ''); status.setAttribute('aria-label', '处理状态');
        for (const [value, label] of [['in_review','审核中'], ['action_taken','已采取措施'], ['no_violation','未发现违规']]) { const option = el('option', label); option.value = value; status.append(option); }
        if (report.status !== 'received') status.value = report.status;
        const note = el('textarea', ''); note.value = report.resolution || ''; note.maxLength = 2000; note.placeholder = '必填：给用户的处理说明'; note.setAttribute('aria-label', '给用户的处理说明'); note.style.cssText = 'display:block;width:100%;min-height:80px;margin:1rem 0';
        const save = el('button', '保存处理结果');
        save.onclick = async () => {
          if (!governanceCanManage || generation !== governanceRequest || save.disabled) return;
          if (!note.value.trim()) { message.textContent = '请填写处理说明。'; return; }
          save.disabled = true;
          try { await request(`/admin/reports/${encodeURIComponent(report.id)}`, {status:status.value, resolution:note.value, version:report.version}); if (generation === governanceRequest) await load(); }
          catch (error) { if (generation === governanceRequest) message.textContent = error.message; }
          finally { if (generation === governanceRequest) save.disabled = false; }
        };
        section.append(status, note, save);
      }
      list.append(section);
    }
    message.textContent = data.items.length ? `显示最近 ${data.items.length} 条举报` : '暂无举报';
  } catch (error) { if (generation === governanceRequest) { governanceCanManage = false; list.replaceChildren(); message.textContent = error.message; } }
}
document.querySelector('#refresh').onclick = load;
load();
