const $ = id => document.getElementById(id);
const tokenKey = 'hildors-admin-token';
const savedToken = () => { try { return localStorage.getItem(tokenKey) || ''; } catch { return ''; } };
const rememberToken = value => { try { value ? localStorage.setItem(tokenKey, value) : localStorage.removeItem(tokenKey); } catch {} };
let token = savedToken(), items = [], epoch = 0;
let reviewing = null;
const previews = new Set();
function showConnection(connected) {
  $('login').hidden = connected;
  $('connected').hidden = !connected;
}
function clearPreviews() { for (const url of previews) URL.revokeObjectURL(url); previews.clear(); }
const messages = { UNAUTHORIZED: '令牌无效或服务未配置管理令牌。', VERSION_OR_STATE_CONFLICT: '内容已被更新，请刷新后重试。', MEDIA_REVIEW_REQUIRED: '需要先完成素材处理和审核。', INVALID_PACKAGE: '请检查名称、视频数量和标签。' };
async function api(path, body) {
  const response = await fetch(path, { method: body === undefined ? 'GET' : 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body) });
  const result = await response.json();
  if (!response.ok) throw new Error(messages[result.code] || '操作失败，请稍后重试。');
  return result;
}
function text(tag, value, className) { const el = document.createElement(tag); el.textContent = value; if (className) el.className = className; return el; }
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
          fetch(`/admin/media/${clip.media.id}/thumbnail`, { headers: { Authorization: `Bearer ${token}` } })
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
            const response = await fetch(`/admin/media/${clip.media.id}`, { headers: { Authorization: `Bearer ${token}` } });
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
              method: 'PUT', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'video/mp4', 'If-Match': String(item.version) }, body: file });
            const result = await response.json();
            if (!response.ok) throw new Error(messages[result.code] || '上传失败，请确认是有效的MP4文件后重试。');
            await refresh(); $('notice').textContent = '素材已保存，等待编码检查、审核和设备适配。';
          } catch (error) { $('notice').textContent = error.message; input.disabled = false; }
        };
        label.append(input); row.append(label);
      }
      list.append(row);
    }
    card.append(list, text('p', item.demo ? '内置演示素材 · 厂家转码待接入' : item.status === 'published' ? '目录已发布 · 云端下载与设备适配待接入' : item.review?.decision === 'approved' ? '审核已通过，可发布目录' : '完成素材检查后提交人工审核'));
    if (item.review) card.append(text('p', `审核：${item.review.decision === 'approved' ? '已通过' : '退回修改'} · ${item.review.note}`));
    if (item.status === 'draft' && item.clips.every(c => c.media?.inspection?.status === 'checked')) {
      const reviewButton = text('button', '审核内容', 'secondary');
      reviewButton.onclick = () => {
        reviewing = item; $('review-form').reset(); $('review-error').textContent = '';
        $('review-title').textContent = item.title; $('review-dialog').showModal();
      };
      card.append(reviewButton);
    }
    if (item.status === 'draft' && item.review?.decision === 'approved') {
      const publish = text('button', '发布到目录');
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
  items = result.items; $('workspace').hidden = false; render();
}
$('login').onsubmit = async event => {
  event.preventDefault(); epoch++; token = $('token').value.trim();
  $('workspace').hidden = true;
  try { await refresh(); rememberToken(token); showConnection(true); $('token').value = ''; $('notice').textContent = '后台已连接，当前电脑已记住登录。'; }
  catch (error) { token = ''; rememberToken(''); showConnection(false); $('notice').textContent = error.message; }
};
$('logout').onclick = () => { epoch++; clearPreviews(); token = ''; rememberToken(''); items = []; reviewing = null; $('token').value = ''; showConnection(false); $('workspace').hidden = true; $('cards').replaceChildren(); $('editor').close(); $('review-dialog').close(); $('notice').textContent = '已退出，本机保存的令牌已清除。'; };
$('refresh').onclick = async () => { try { await refresh(); $('notice').textContent = '内容已刷新。'; } catch (error) { $('notice').textContent = error.message; } };
$('search').oninput = render; $('status').onchange = render;
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
    await api(`/admin/packages/${reviewing.id}/review`, { version: reviewing.version,
      decision: data.get('decision'), note: data.get('note'), rightsReference: data.get('rightsReference'), rightsConfirmed: data.has('rightsConfirmed') });
    $('review-dialog').close(); await refresh(); $('notice').textContent = '审核结果已保存。';
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

if (token) {
  showConnection(true);
  $('notice').textContent = '正在自动连接后台…';
  refresh().then(() => { $('notice').textContent = '后台已连接，当前电脑已记住登录。'; })
    .catch(error => { token = ''; rememberToken(''); showConnection(false); $('workspace').hidden = true; $('notice').textContent = error.message; });
}
