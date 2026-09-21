import test from 'node:test';
import assert from 'node:assert/strict';
import {createStore} from '../src/store.mjs';
test('plan order pagination filters before counting and preserves legacy default', t => {
 const s=createStore();t.after(()=>s.close());const user=s.createUser();
 s.updateCustomizationPlan('custom-10s',{version:1,listed:true,usdBaseCents:1999},'test');
 s.createCustomizationOrder(user,{characterName:'Legacy Fox'});
 const first=s.createCustomizationOrder(user,{planId:'custom-10s',planVersion:2,characterName:'Blue Fox'});
 s.createCustomizationOrder(user,{planId:'custom-10s',planVersion:2,characterName:'Red Fox'});
 const all=s.pageCustomizationOrders(new URLSearchParams());assert.equal(all.total,3);
 const result=s.pageCustomizationOrders(new URLSearchParams('kind=plan&pageSize=1&page=9'));
 assert.equal(result.total,2);assert.equal(result.page,2);assert.equal(result.items.length,1);
 assert.equal(result.counts.total,2);assert.equal(result.items[0].planSummary.durationSeconds,10);
 assert.equal('requirements' in result.items[0],false);assert.equal('materials' in result.items[0],false);
 const filtered=s.pageCustomizationOrders(new URLSearchParams('kind=plan&q=blue&status=free_review'));
 assert.equal(filtered.total,1);assert.equal(filtered.items[0].id,first.id);
 const legacy=s.pageCustomizationOrders(new URLSearchParams('kind=legacy'));assert.equal(legacy.total,1);assert.equal(legacy.items[0].characterName,'Legacy Fox');
});
