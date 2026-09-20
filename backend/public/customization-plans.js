export function parseUsdCents(value) {
  const text = String(value).trim();
  if (!/^\d+(?:\.\d{1,2})?$/.test(text)) throw new Error('美元价格必须是正数，最多两位小数。');
  const [dollars, fraction = ''] = text.split('.');
  const cents = BigInt(dollars) * 100n + BigInt(fraction.padEnd(2, '0'));
  if (cents < 1n || cents > BigInt(Number.MAX_SAFE_INTEGER)) throw new Error('美元价格超出有效范围。');
  return Number(cents);
}

function formatUsd(cents) {
  return `${Math.floor(cents / 100)}.${String(cents % 100).padStart(2, '0')}`;
}

if (typeof document !== 'undefined') {
  const list = document.getElementById('plans');
  const message = document.getElementById('message');
  const refresh = document.getElementById('refresh');
  let busy = false;
  let actor = null, permissions = new Set();
  const controlPermissions = new WeakMap();
  const can = key => Boolean(actor) && (actor.isRoot === true || permissions.has(key));
  const fieldPermissions = {durationSeconds:'plans.edit',description:'plans.edit',sortOrder:'plans.edit',usdBaseCents:'plans.pricing',audioMarkupPercent:'plans.pricing',listed:'plans.publish',appleProductId:'plans.billing',googleProductId:'plans.billing',audioAppleProductId:'plans.billing',audioGoogleProductId:'plans.billing'};
  const canSave = () => ['plans.edit','plans.pricing','plans.publish','plans.billing'].some(can);
  function updateControls() {
    document.querySelectorAll('button, input').forEach(control => {
      const permission = controlPermissions.get(control);
      control.disabled = busy || Boolean(permission && !can(permission));
    });
  }
  const el = (tag, text = '') => {
    const node = document.createElement(tag);
    node.textContent = text;
    return node;
  };
  async function request(path, body) {
    const response = await fetch(path, {
      method: body ? 'POST' : 'GET', credentials: 'same-origin', cache: 'no-store',
      headers: body ? { 'Content-Type': 'application/json' } : {},
      body: body ? JSON.stringify(body) : undefined
    });
    if (!response.ok) throw new Error(response.status === 401 || response.status === 403
      ? '无管理权限或登录已过期，请返回后台登录。'
      : response.status === 409 ? '套餐版本冲突或商品 ID 已绑定旧价格／音频类型。调价需使用新版本商品 ID。你的输入仍保留；请先复制需要保留的内容，再重新读取套餐后修改。'
      : response.status === 400 ? '保存失败：请检查字段内容、商品 ID 与数值范围。'
      : '请求失败，请稍后重试。');
    return response.json();
  }
  async function run(work, status) {
    if (busy) return;
    busy = true;
    document.querySelectorAll('button, input').forEach(control => { control.disabled = true; });
    message.textContent = status;
    try { await work(); } catch (error) { message.textContent = error.message; }
    finally {
      busy = false;
      updateControls();
    }
  }
  function field(form, title, value, options = {}) {
    const label = el('label', title);
    const input = el('input');
    Object.assign(input, { type: 'text', required: true, value: value ?? '', ...options });
    label.append(input);
    form.append(label);
    return input;
  }
  function storeStatus(store) {
    const status = store?.status ?? 'not_connected';
    const labels = { not_connected: '未接通', pending: '待处理', synced: '已同步', active: '有效', error: '异常' };
    return `${labels[status] ?? '商店返回状态'} (${status})；商品 ID：${store?.productId || '未配置'}`;
  }
  function render(plan) {
    const section = el('details');
    section.append(el('summary', `${plan.durationSeconds} 秒 · $${formatUsd(plan.usdBaseCents)} · ${plan.listed ? '已上架' : '未上架'} · 点击编辑`));
    section.append(el('h2', `${plan.durationSeconds} 秒套餐`), el('p', `套餐 ID：${plan.id} · 版本 ${plan.version}`));
    section.append(el('p', `后台上架意愿：${plan.listed ? '希望上架' : '暂不上架'}`));
    section.append(el('p', `Apple 实际状态：${storeStatus(plan.apple)}`), el('p', `Google 实际状态：${storeStatus(plan.google)}`));
    section.append(el('p', '购买状态：未开放购买；后台保存不代表商店已上架。'));
    const form = el('form');
    const duration = field(form, '视频时长（秒，正整数）', plan.durationSeconds, { type: 'number', min: '1', step: '1' });
    const price = field(form, '美元基准价格（USD，最多两位小数）', formatUsd(plan.usdBaseCents), { inputMode: 'decimal', maxLength: 18 });
    const markup = field(form, '平台搭配音频加价百分比（0–100）', plan.audio?.markupPercent ?? 20, {type:'number',min:'0',max:'100',step:'1'});
    form.append(el('p', `含音频美元基准总价：$${formatUsd(plan.audio.totalUsdCents)}。购买页以商店返回价格为准。`));
    const storeFields = el('details'); storeFields.append(el('summary','商店商品配置（高级）')); form.append(storeFields);
    const audioApple = field(storeFields,'含音频 Apple 商品 ID（与无音频商品分开）',plan.audio?.apple?.productId,{required:false,maxLength:200});
    const audioGoogle = field(storeFields,'含音频 Google 商品 ID（与无音频商品分开）',plan.audio?.google?.productId,{required:false,maxLength:200});
    storeFields.append(el('p', '音频商店状态：尚未连接。调价需新价格版本商品 ID，旧订单保留旧绑定。'));
    const en = field(form, '英文说明（必填）', plan.description.en, { maxLength: 2000 });
    const zh = field(form, '中文说明（必填）', plan.description.zh, { maxLength: 2000 });
    const order = field(form, '排序值（非负整数，越小越靠前）', plan.sortOrder, { type: 'number', min: '0', step: '1' });
    const apple = field(storeFields, 'Apple 商品 ID（可留空；不会自动创建商品）', plan.apple?.productId, { required: false, maxLength: 200 });
    const google = field(storeFields, 'Google 商品 ID（可留空；不会自动创建商品）', plan.google?.productId, { required: false, maxLength: 200 });
    const listed = field(form, '希望上架（仅后台意愿）', '', { type: 'checkbox', required: false, checked: plan.listed });
    for (const [input, permission] of [[duration,'plans.edit'],[en,'plans.edit'],[zh,'plans.edit'],[order,'plans.edit'],[price,'plans.pricing'],[markup,'plans.pricing'],[listed,'plans.publish'],[apple,'plans.billing'],[google,'plans.billing'],[audioApple,'plans.billing'],[audioGoogle,'plans.billing']]) { controlPermissions.set(input, permission); input.disabled = !can(permission); }
    const save = el('button', '保存此套餐');
    save.type = 'submit';
    save.hidden = !canSave();
    form.append(save);
    form.onsubmit = event => {
      event.preventDefault();
      if (busy || !can('plans.view') || !canSave() || !form.reportValidity()) return;
      let body;
      try {
        const seconds = Number(duration.value), sortOrder = Number(order.value);
        if (!Number.isSafeInteger(seconds) || seconds < 1 || !Number.isSafeInteger(sortOrder) || sortOrder < 0) throw new Error('时长和排序值必须是有效整数。');

        body = { audioMarkupPercent:Number(markup.value),audioAppleProductId:audioApple.value.trim(),audioGoogleProductId:audioGoogle.value.trim(),version: plan.version, durationSeconds: seconds, usdBaseCents: parseUsdCents(price.value), description: { en: en.value.trim(), zh: zh.value.trim() }, sortOrder, listed: listed.checked, appleProductId: apple.value.trim(), googleProductId: google.value.trim() };
        const previous = {audioMarkupPercent:plan.audio?.markupPercent ?? 20,audioAppleProductId:plan.audio?.apple?.productId || '',audioGoogleProductId:plan.audio?.google?.productId || '',durationSeconds:plan.durationSeconds,usdBaseCents:plan.usdBaseCents,description:plan.description,sortOrder:plan.sortOrder,listed:plan.listed,appleProductId:plan.apple?.productId || '',googleProductId:plan.google?.productId || ''};
        body = Object.fromEntries(Object.entries(body).filter(([key,value]) => key === 'version' || can(fieldPermissions[key]) && JSON.stringify(value) !== JSON.stringify(previous[key])));
        if (Object.keys(body).length === 1) { message.textContent = '没有可保存的授权字段变更。'; return; }
        body = {usdBaseCents:plan.usdBaseCents,listed:plan.listed,...body};
      } catch (error) { message.textContent = error.message; return; }
      run(async () => {
        await request(`/admin/customization-plans/${encodeURIComponent(plan.id)}`, body);
        // Refresh only this card so edits on other plans remain intact.
        try {
          const result = await request('/admin/customization-plans');
          const saved = result.items.find(item => item.id === plan.id);
          if (!saved) throw new Error('套餐未返回');
          section.replaceWith(render(saved));
          message.textContent = '套餐已保存。商店状态以实际连接结果为准，支付仍未开放。';
        } catch { message.textContent = '套餐已保存，但读取新版本失败。请重新读取全部套餐后再保存此套餐。'; }
      }, '正在保存…');
    };
    const historyButton = el('button', '查看版本历史');
    historyButton.type = 'button';
    const history = el('div');
    historyButton.onclick = () => run(async () => {
      const data = await request(`/admin/customization-plans/${encodeURIComponent(plan.id)}/history`);
      history.replaceChildren(el('h3', '版本历史'));
      if (!data.items.length) history.append(el('p', '暂无历史记录。'));
      for (const item of data.items) {
        const details = el('details');
        details.append(el('summary', `版本 ${item.version} · ${item.actor} · ${item.at}`));
        const snapshot = el('pre', JSON.stringify(item.snapshot, null, 2));
        snapshot.style.whiteSpace = 'pre-wrap';
        snapshot.style.overflowWrap = 'anywhere';
        details.append(snapshot);
        history.append(details);
      }
      message.textContent = '版本历史已读取。';
    }, '正在读取历史…');
    section.append(form, historyButton, history, el('hr'));
    return section;
  }
  async function load() {
    actor = null; permissions.clear(); list.replaceChildren();
    const identity = await request('/admin/me');
    actor = identity.actor || null; permissions = new Set(Array.isArray(identity.permissions) ? identity.permissions : []);
    if (!can('plans.view')) { message.textContent = '当前账号没有查看套餐的权限。'; return; }
    const data = await request('/admin/customization-plans');
    list.replaceChildren(...data.items.map(render));
    message.textContent = data.items.length ? `已读取 ${data.items.length} 个套餐。` : '暂无套餐配置。';
  }
  refresh.onclick = () => run(load, '正在读取套餐…');
  run(load, '正在读取套餐…');
}
