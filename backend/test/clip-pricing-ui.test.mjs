import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { readFileSync } from 'node:fs';

function editor(pricing, allowed = true) {
  class Element {
    constructor(tag) { this.tagName = tag; this.children = []; this.value = ''; }
    append(...children) { this.children.push(...children); }
    setAttribute() {}
  }
  const calls = [];
  const context = vm.createContext({ canAdmin: () => allowed, document: { createElement: tag => new Element(tag) } });
  vm.runInContext(readFileSync(new URL('../public/clip-pricing.js', import.meta.url), 'utf8'), context);
  const root = context.createClipPricingEditor({id:'p',version:4}, {id:'c',pricing}, {
    save: async (...args) => calls.push(args), onSaved: async () => {},
  });
  const nodes = [];
  function walk(node) { nodes.push(node); node.children.forEach(walk); } walk(root);
  return {calls, select:nodes.find(n=>n.tagName==='select'), input:nodes.find(n=>n.tagName==='input'),
    button:nodes.find(n=>n.tagName==='button'), notice:nodes.find(n=>n.role==='status')};
}

test('view-only pricing is disabled and does not submit even if handler is called', async () => {
  const e = editor({mode:'paid',currency:'USD',amountMinor:199}, false);
  assert.equal(e.button.hidden, true); assert.equal(e.select.disabled, true); assert.equal(e.input.disabled, true);
  await e.button.onclick(); assert.equal(e.calls.length, 0);
});

test('pricing editor never silently makes legacy videos free', async () => {
  const e = editor();
  assert.equal(e.select.value, '');
  await e.button.onclick();
  assert.equal(e.calls.length,0);
  assert.match(e.notice.textContent,/选择/);
});

test('paid editor sends exact USD cents and optimistic version', async () => {
  const e = editor(); e.select.value='paid'; e.select.onchange(); e.input.value='1.29';
  await e.button.onclick();
  assert.equal(e.calls[0][0],'/admin/packages/p/clips/c/pricing');
  assert.deepEqual(JSON.parse(JSON.stringify(e.calls[0][1])),{version:4,pricing:{mode:'paid',currency:'USD',amountMinor:129}});
});

test('free removes stale price; invalid paid values never submit', async () => {
  const e = editor({mode:'paid',currency:'USD',amountMinor:299});
  assert.equal(e.input.value,'2.99');
  for (const value of ['0','-1','1.001','1e3','NaN','1000000']) {
    e.input.value=value; await e.button.onclick(); assert.equal(e.calls.length,0);
  }
  e.select.value='free'; e.select.onchange(); await e.button.onclick();
  assert.equal(e.calls[0][1].pricing.amountMinor,0);
});

test('each editor saves its own clip in a mixed package', async () => {
  const free = editor({mode:'free',currency:'USD',amountMinor:0});
  const paid = editor({mode:'paid',currency:'USD',amountMinor:599});
  assert.equal(free.input.disabled,true);
  assert.equal(paid.input.disabled,false);
  await free.button.onclick();
  assert.equal(free.calls[0][1].pricing.mode,'free');
  assert.equal(paid.calls.length,0);
});
