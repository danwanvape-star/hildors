import test from 'node:test';
import assert from 'node:assert/strict';
import { createStore } from '../src/store.mjs';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

test('first setup supplies designed genres and reopening preserves operator choices', () => {
  const directory = mkdtempSync(join(tmpdir(), 'hildors-genres-'));
  let store;
  try {
    const path = join(directory, 'catalog.sqlite');
    store = createStore(path);
    assert.deepEqual(store.contentTags().map(x => x.name), ['神话传说','东方仙侠','奇幻魔法','科幻未来','赛博朋克','历史古风','现代都市','二次元','游戏世界','童话萌宠']);
    store.saveContentTags(store.contentTags().map(x => ({...x,active:false})));
    store.close(); store = createStore(path);
    assert.equal(store.contentTags().length, 10);
    assert.ok(store.contentTags().every(x => !x.active));
  } finally { store?.close(); rmSync(directory, {recursive:true}); }
});
