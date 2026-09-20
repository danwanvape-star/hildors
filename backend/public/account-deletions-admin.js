const list = document.querySelector('#requests'), message = document.querySelector('#message');
const el = (tag, text) => { const node = document.createElement(tag); node.textContent = text; return node; };
let generation = 0, actor = null, permissions = new Set();
const can = key => Boolean(actor) && (actor.isRoot === true || permissions.has(key));
async function request(path, body) {
  const response = await fetch(path, {method:body ? 'POST' : 'GET',credentials:'same-origin',headers:body ? {'Content-Type':'application/json'} : {},body:body ? JSON.stringify(body) : undefined});
  if (!response.ok) throw new Error(response.status === 401 ? '请先返回后台登录。' : response.status === 403 ? '当前账号没有此操作权限。' : response.status === 409 ? '记录已更新或已取消，请刷新。' : '操作失败，请检查填写内容或稍后重试。');
  return response.json();
}
async function load() {
  const current = ++generation; actor = null; permissions.clear(); list.replaceChildren(); message.textContent = '正在读取申请…';
  try {
    const identity = await request('/admin/me'); if (current !== generation) return;
    actor = identity.actor || null; permissions = new Set(Array.isArray(identity.permissions) ? identity.permissions : []);
    if (!can('account_deletions.view')) { message.textContent = '当前账号没有查看注销申请的权限。'; return; }
    const data = await request('/admin/account-deletions'); if (current !== generation) return;
    for (const item of data.items) {
      const section = el('section', '');
      section.append(el('h2', item.status), el('p', `申请编号：${item.id}`), el('p', `用户：${item.userId}`), el('p', `更新：${item.updatedAt}`));
      if (item.status !== 'cancelled' && can('account_deletions.review')) {
        const select = el('select', ''); select.setAttribute('aria-label', '审核状态');
        for (const [value,label] of [['in_review','审核中'],['needs_information','待补充信息']]) { const option=el('option',label); option.value=value; select.append(option); }
        select.value = item.status === 'needs_information' ? 'needs_information' : 'in_review';
        const note=el('textarea','');note.value=item.message || '';note.maxLength=2000;note.placeholder='用户可见说明；待补充信息时必填';note.setAttribute('aria-label','用户可见说明');
        const save=el('button','保存审核进度');
        save.onclick=async()=>{
          if (current !== generation || !can('account_deletions.review') || !can('account_deletions.view') || save.disabled) return;
          if(select.value==='needs_information'&&!note.value.trim()){message.textContent='请填写需要补充的信息。';return;}
          save.disabled=true;
          try { await request(`/admin/account-deletions/${encodeURIComponent(item.id)}`,{version:item.version,status:select.value,message:note.value}); if(current===generation)await load(); }
          catch(error){if(current===generation)message.textContent=error.message;}
          finally{if(current===generation)save.disabled=false;}
        };
        section.append(select,note,save);
      } else section.append(el('p', `处理说明：${item.message || '尚未填写'}`));
      list.append(section);
    }
    message.textContent=data.items.length?`已读取最近 ${data.items.length} 条申请`:'暂无申请';
  } catch(error){if(current===generation){actor=null;permissions.clear();list.replaceChildren();message.textContent=error.message;}}
}
document.querySelector('#refresh').onclick=load;load();
