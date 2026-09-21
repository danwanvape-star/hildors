import test from 'node:test';
import assert from 'node:assert/strict';
import {createStore} from '../src/store.mjs';
import {createCustomizationBilling} from '../src/customization-billing.mjs';
const terms={deliveryContent:'Agreed MP4 file',deliveryPeriod:'Operator-defined period',revisionScope:'Operator-defined scope',usageRights:'Operator-defined rights',maxRevisions:1};
test('plan orders require terms and verified payments; private delivery checks actual video duration and revisions',async t=>{
 const s=createStore();t.after(()=>s.close());const uid=s.createUser();
 s.updateCustomizationPlan('custom-10s',{version:1,usdBaseCents:1999,listed:true,appleProductId:'custom10.v1'},'test');
 const o=s.createCustomizationOrder(uid,{planId:'custom-10s',planVersion:2,characterName:'Private'});
 assert.equal(o.privacy,'private');assert.throws(()=>s.updateCustomizationOrder(o.id,1,'in_production'),/PAYMENT_REQUIRED/);
 assert.throws(()=>s.preparePlanOffer(o.id,{version:1,terms:{}}),/TERMS_REQUIRED/);
 let current=s.preparePlanOffer(o.id,{version:1,terms});
 await assert.rejects(createCustomizationBilling().verify('apple','proof',{}),/PAYMENT_NOT_READY/);
 const expected={userId:uid,orderId:o.id,productId:'custom10.v1'};
 const receipt={...expected,verified:true,platform:'apple',environment:'sandbox',transactionId:'tx-1',status:'purchased',currency:'EUR',amountMicros:'21990000'};
 const adapter={verify:async()=>receipt};
 await assert.rejects(createCustomizationBilling({mode:'live',apple:adapter}).verify('apple','proof',expected),/VERIFICATION/);
 const verified=await createCustomizationBilling({mode:'test',apple:adapter}).verify('apple','proof',expected);
 current=s.applyVerifiedCustomizationTransaction(verified);assert.equal(current.status,'in_production');
 const version=current.version;assert.equal(s.applyVerifiedCustomizationTransaction(verified).version,version);
 assert.equal(current.paidSnapshot.currency,'EUR');assert.equal(current.paidSnapshot.amountMicros,'21990000');
 assert.throws(()=>s.attachPlanDeliverable(o.id,version,{id:'short',inspection:{status:'checked',videoDurationSeconds:9.9,durationSeconds:60}}),/DURATION/);
 current=s.attachPlanDeliverable(o.id,version,{id:'final',inspection:{status:'checked',videoDurationSeconds:10.1}});
 current=s.updateCustomizationOrder(o.id,current.version,'user_acceptance');
 current=s.planOrderAction(o.id,uid,{version:current.version,action:'request_revision',note:'Adjust lighting'});assert.equal(current.revisionCount,1);
 current=s.attachPlanDeliverable(o.id,current.version,{id:'revision',inspection:{status:'checked',videoDurationSeconds:10.2}});
 current=s.updateCustomizationOrder(o.id,current.version,'user_acceptance');
 assert.throws(()=>s.planOrderAction(o.id,uid,{version:current.version,action:'request_revision',note:'Again'}),/REVISION_LIMIT/);
 current=s.planOrderAction(o.id,uid,{version:current.version,action:'accept_delivery'});assert.equal(current.status,'delivered');
 current=s.applyVerifiedCustomizationTransaction({...verified,status:'refunded'});assert.equal(current.status,'withdrawn');
 assert.equal(current.paidSnapshot.amountMicros,'21990000');assert.throws(()=>s.applyVerifiedCustomizationTransaction(verified),/REFUNDED/);
});

test('audio selection is enforced on inspected delivery, never on a client declaration',t=>{
 const s=createStore();t.after(()=>s.close());const uid=s.createUser();
 s.updateCustomizationPlan('custom-10s',{version:1,usdBaseCents:1999,listed:true,appleProductId:'silent',audioAppleProductId:'matched'},'test');
 for(const audioMode of ['none','matched']){
  let o=s.createCustomizationOrder(uid,{planId:'custom-10s',planVersion:2,audioMode});o=s.preparePlanOffer(o.id,{version:o.version,terms});
  o=s.applyVerifiedCustomizationTransaction({orderId:o.id,userId:uid,platform:'apple',productId:audioMode==='none'?'silent':'matched',transactionId:audioMode,status:'purchased',environment:'sandbox',currency:'USD',amountMicros:audioMode==='none'?'19990000':'23990000'});
  assert.throws(()=>s.attachPlanDeliverable(o.id,o.version,{id:'wrong',inspection:{status:'checked',videoDurationSeconds:10,audioCodec:audioMode==='none'?'aac':null}}),/AUDIO_MISMATCH/);
  assert.equal(s.attachPlanDeliverable(o.id,o.version,{id:'right',inspection:{status:'checked',videoDurationSeconds:10,audioCodec:audioMode==='none'?null:'aac'}}).status,'quality_review');
 }
});

test('supplemental requirements return to review without repricing; paid orders cannot change scope',t=>{
 const s=createStore();t.after(()=>s.close());const uid=s.createUser(),other=s.createUser();
 s.updateCustomizationPlan('custom-10s',{version:1,usdBaseCents:1999,listed:true},'test');
 let o=s.createCustomizationOrder(uid,{planId:'custom-10s',planVersion:2,requirements:'old',materialCount:0});
 o=s.reviewPlanOrder(o.id,{version:o.version,action:'request_info',note:'Clarify movement'});
 assert.throws(()=>s.planOrderAction(o.id,other,{version:o.version,action:'resubmit',requirements:'Turn left'}),/CONFLICT/);
 assert.throws(()=>s.planOrderAction(o.id,uid,{version:o.version,action:'resubmit',requirements:' '}),/REQUIREMENTS/);
 const original=o.planSnapshot;
 o=s.planOrderAction(o.id,uid,{version:o.version,action:'resubmit',requirements:'Turn left'});
 assert.equal(o.status,'free_review');assert.equal(o.requirements,'Turn left');assert.deepEqual(o.planSnapshot,original);assert.equal(o.requirementHistory[0].requirements,'old');
 assert.throws(()=>s.planOrderAction(o.id,uid,{version:o.version,action:'resubmit',requirements:'Again'}),/CONFLICT/);
});

test('production updates are append-only, versioned, scoped and preserve commercial snapshots',t=>{
 const s=createStore();t.after(()=>s.close());const uid=s.createUser();
 s.updateCustomizationPlan('custom-10s',{version:1,usdBaseCents:1999,listed:true},'test');
 let o=s.createCustomizationOrder(uid,{planId:'custom-10s',planVersion:2});
 const value={version:1,requestId:'progress-1',text:{en:'Animation is in progress.',zh:'正在制作动画。'}};
 assert.throws(()=>s.recordPlanProgress(o.id,value,'operator'),/CONFLICT/);
 o=s.preparePlanOffer(o.id,{version:1,terms});o=s.applyVerifiedCustomizationTransaction({orderId:o.id,userId:uid,platform:'apple',transactionId:o.id,status:'purchased',currency:'USD',amountMicros:'19990000'});
 const snapshot=o.paidSnapshot;value.version=o.version;
 assert.throws(()=>s.recordPlanProgress(o.id,{...value,text:{en:'',zh:'中文'}},'operator'),/PROGRESS_INVALID/);
 o=s.recordPlanProgress(o.id,value,'operator');assert.equal(o.productionUpdates.length,1);assert.equal(o.status,'in_production');assert.deepEqual(o.paidSnapshot,snapshot);
 assert.equal(s.recordPlanProgress(o.id,value,'operator').version,o.version);
 assert.throws(()=>s.recordPlanProgress(o.id,{...value,requestId:'new-id'},'operator'),/CONFLICT/);
 assert.equal(s.customerOrderView(o).productionUpdates[0].actor,undefined);
 o=s.recordPlanProgress(o.id,{version:o.version,requestId:'progress-2',text:{en:'Lighting is ready.'}},'operator');assert.equal(o.productionUpdates.length,2);assert.equal(o.productionUpdates[0].text.en,value.text.en);
});
