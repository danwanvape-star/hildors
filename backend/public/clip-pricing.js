function createClipPricingEditor(item, clip, { save, onSaved }) {
  const element = (tag, content) => {
    const node = document.createElement(tag);
    if (content !== undefined) node.textContent = content;
    return node;
  };
  const root = element('fieldset');
  root.append(element('legend', '单条视频下载定价'));
  const modeLabel = element('label', '下载方式');
  const mode = element('select');
  for (const [value, label] of [['', '待设置'], ['free', '免费'], ['paid', '收费（美元 USD）']]) {
    const option = element('option', label); option.value = value; mode.append(option);
  }
  mode.value = clip.pricing?.mode || '';
  modeLabel.append(mode);
  const amountLabel = element('label', '单价（USD）');
  const amount = element('input');
  amount.type = 'text'; amount.inputMode = 'decimal'; amount.placeholder = '例如 1.99';
  amount.maxLength = 9;
  amount.value = clip.pricing?.mode === 'paid' ? (clip.pricing.amountMinor / 100).toFixed(2) : '';
  amountLabel.append(amount);
  const notice = element('p'); notice.role = 'status'; notice.setAttribute('role', 'status');
  const button = element('button', '保存单条价格'); button.type = 'button';
  const canPrice = () => typeof canAdmin === 'function' && canAdmin('content.pricing');
  mode.disabled = !canPrice(); button.hidden = !canPrice();
  mode.onchange = () => { amountLabel.hidden = mode.value !== 'paid'; amount.disabled = mode.value !== 'paid' || !canPrice(); };
  mode.onchange();
  button.onclick = async () => {
    if (!canPrice()) return;
    notice.textContent = '';
    if (!['free', 'paid'].includes(mode.value)) { notice.textContent = '请选择免费或收费。'; return; }
    let amountMinor = 0;
    if (mode.value === 'paid') {
      const value = amount.value.trim();
      if (!/^\d{1,6}(?:\.\d{1,2})?$/.test(value)) { notice.textContent = '请输入美元金额，最多两位小数。'; return; }
      const [whole, fraction = ''] = value.split('.');
      amountMinor = Number(whole) * 100 + Number(fraction.padEnd(2, '0'));
      if (amountMinor < 1 || amountMinor > 99999999) { notice.textContent = '收费金额须为 US$ 0.01 至 999999.99。'; return; }
    }
    button.disabled = true;
    try {
      await save(`/admin/packages/${encodeURIComponent(item.id)}/clips/${encodeURIComponent(clip.id)}/pricing`, {
        version: item.version, pricing: { mode: mode.value, currency: 'USD', amountMinor },
      });
      await onSaved();
      notice.textContent = '单条视频价格已保存。';
    } catch (error) { notice.textContent = error.message || '保存失败，请刷新后重试。'; }
    finally { button.disabled = false; }
  };
  root.append(modeLabel, amountLabel, element('p', '按单条视频计价。支付尚未接入，收费视频暂不开放购买。'), button, notice);
  return root;
}
