import test from 'node:test';
import assert from 'node:assert/strict';

test('USD input preserves cents exactly and rejects rounding or unsafe integers', async () => {
  let module;
  try { module = await import('../public/customization-plans.js'); } catch {}
  assert.equal(typeof module?.parseUsdCents, 'function');
  for (const [value, expected] of [['19.99',1999],['29.99',2999],['69.99',6999],['159.99',15999],['1.1',110],['1',100],['0.01',1]]) {
    assert.equal(module.parseUsdCents(value), expected);
  }
  for (const value of ['', '0', '-1', '1.001', '1e2', 'NaN', '1,99', '90071992547409.92']) {
    assert.throws(() => module.parseUsdCents(value));
  }
});
