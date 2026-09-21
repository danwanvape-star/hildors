import test from 'node:test';
import assert from 'node:assert/strict';
import {createStore} from '../src/store.mjs';
test('four server-owned plans, revision audit, no pretend store activation, immutable order snapshot',t=>{
 const s=createStore();t.after(()=>s.close());
 const plans=s.customizationPlans();assert.deepEqual(plans.map(p=>[p.durationSeconds,p.usdBaseCents]),[[10,1999],[15,2999],[30,6999],[60,15999]]);
 const p=plans[0];const uid=s.createUser();
 const order=s.createCustomizationOrder(uid,{characterName:'Example',planSnapshot:s.customizationPlanSnapshot(p.id),payment:{status:'pending'}});
 const next=s.updateCustomizationPlan(p.id,{version:1,usdBaseCents:2499,listed:true},'test-operator');
 assert.equal(next.version,2);assert.equal(next.purchaseEnabled,false);assert.equal(next.apple.status,'not_connected');
 assert.equal(s.getCustomizationOrder(order.id).planSnapshot.usdBaseCents,1999);
 assert.equal(s.customizationPlanHistory(p.id).length,2);
 assert.throws(()=>s.updateCustomizationPlan(p.id,{version:1,usdBaseCents:1,listed:false},'test'),/CONFLICT/);
 assert.throws(()=>s.updateCustomizationPlan(p.id,{version:2,usdBaseCents:19.99,listed:true},'test'),/INVALID/);
 assert.throws(()=>s.updateCustomizationPlan(p.id,{version:2,usdBaseCents:2499,listed:true,purchaseEnabled:true},'test'),/INVALID/);
 assert.equal(s.updateCustomizationPlan(p.id,{version:2,usdBaseCents:2499,listed:false},'test').listed,false);
 assert.equal(s.getCustomizationOrder(order.id).planSnapshot.version,1);
});

test('audio variant defaults to 20 percent, uses distinct products and freezes total in order',t=>{
 const s=createStore();t.after(()=>s.close());const uid=s.createUser();
 assert.deepEqual(s.customizationPlans().map(p=>p.audio.totalUsdCents),[2399,3599,8399,19199]);
 s.updateCustomizationPlan('custom-10s',{version:1,usdBaseCents:1999,listed:true,appleProductId:'silent.v1',audioAppleProductId:'audio.v1'},'test');
 const o=s.createCustomizationOrder(uid,{planId:'custom-10s',planVersion:2,audioMode:'matched'});
 assert.equal(o.planSnapshot.usdBaseCents,1999);assert.equal(o.planSnapshot.totalUsdCents,2399);assert.equal(o.planSnapshot.audioSurchargeCents,400);assert.equal(o.planSnapshot.appleProductId,'audio.v1');
 assert.equal(s.customizationPlanSnapshot('custom-10s').audioMode,'none');
 assert.throws(()=>s.customizationPlanSnapshot('custom-10s','uploaded'),/INVALID/);
 assert.throws(()=>s.updateCustomizationPlan('custom-10s',{version:2,usdBaseCents:1999,listed:true,audioMarkupPercent:25},'test'),/PRODUCT_VERSION/);
 s.updateCustomizationPlan('custom-10s',{version:2,usdBaseCents:1999,listed:true,audioMarkupPercent:25,audioAppleProductId:'audio.v2'},'test');
 assert.equal(s.getCustomizationOrder(o.id).planSnapshot.totalUsdCents,2399);
 assert.equal(s.customizationPlanSnapshot('custom-10s','matched').totalUsdCents,2499);
 assert.throws(()=>s.updateCustomizationPlan('custom-10s',{version:3,usdBaseCents:1999,listed:true,audioAppleProductId:'silent.v1'},'test'),/PRODUCT_VERSION/);
});
