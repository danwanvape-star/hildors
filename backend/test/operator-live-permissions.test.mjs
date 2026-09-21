import test from 'node:test';
import assert from 'node:assert/strict';
import {adminPermissions,permissionKeys,permissionPresets} from '../src/operators.mjs';
const plan={id:'custom-10s',version:1,usdBaseCents:1999,listed:false,durationSeconds:10,sortOrder:0,description:{en:'A',zh:'甲'},apple:{productId:'apple.v1'},google:{productId:'google.v1'},audio:{markupPercent:20,apple:{productId:'audio.apple.v1'},google:{productId:'audio.google.v1'}}};
const store={customizationPlans:()=>[plan]};
const permission=(method,path,body)=>adminPermissions(method,path,async()=>body,store);
test('live account deletion admin endpoints have isolated view and review scopes',async()=>{
 assert.deepEqual(await permission('GET','/admin/account-deletions'),['account_deletions.view']);
 assert.deepEqual(await permission('POST','/admin/account-deletions/id',{}),['account_deletions.review']);
 for(const [method,path]of [['DELETE','/admin/account-deletions/id'],['GET','/admin/account-deletions/id'],['POST','/admin/account-deletions'],['POST','/admin/account-deletions/id/purge']])assert.equal(await permission(method,path,{}),null);
});
test('live plan routes separate commercial settings from descriptions and listing',async()=>{
 for(const path of ['/admin/customization-plans','/admin/customization-plans/custom-10s','/admin/customization-plans/custom-10s/history'])assert.deepEqual(await permission('GET',path),['plans.view']);
 const base={version:1,usdBaseCents:1999,listed:false};
 for(const [fields,expected]of [[{description:{en:'B',zh:'乙'}},['plans.edit']],[{usdBaseCents:2999},['plans.pricing']],[{audioMarkupPercent:30},['plans.pricing']],[{listed:true},['plans.publish']],[{appleProductId:'apple.v2'},['plans.billing']],[{audioGoogleProductId:'audio.v2'},['plans.billing']]])assert.deepEqual(await permission('POST','/admin/customization-plans/custom-10s',{...base,...fields}),expected);
 assert.deepEqual(new Set(await permission('POST','/admin/customization-plans/custom-10s',{...base,usdBaseCents:2999,listed:true,googleProductId:'google.v2'})),new Set(['plans.pricing','plans.publish','plans.billing']));
 for(const [method,path]of [['POST','/admin/customization-plans'],['DELETE','/admin/customization-plans/custom-10s'],['POST','/admin/customization-plans/custom-10s/history'],['GET','/admin/customization-plans/custom-10s/unknown']])assert.equal(await permission(method,path,{}),null);
 assert.equal(await permission('POST','/admin/customization-plans/custom-10s',{...base,unknownSensitive:true}),null);
});
test('live plan order actions use existing exact order permissions and reject customer-only actions',async()=>{
 const prefix='/admin/customization-orders/id/';
 for(const [method,suffix,body,expected]of [['POST','plan-offer',{},'orders.quote'],['POST','plan-progress',{},'orders.deliver'],['PUT','deliverable',null,'orders.deliver'],['GET','deliverable',null,'orders.view'],['POST','plan-review',{action:'request_info'},'orders.review'],['POST','plan-review',{action:'reject'},'orders.review'],['POST','plan-review',{action:'approve_delivery'},'orders.deliver'],['POST','plan-review',{action:'request_rework'},'orders.deliver']])assert.deepEqual(await permission(method,prefix+suffix,body),[expected]);
 for(const [method,suffix,body]of [['POST','purchase',{}],['GET','manifest'],['GET','download'],['POST','plan-action',{}],['POST','plan-review',{action:'future_sensitive_action'}],['DELETE','deliverable'],['GET','plan-offer']])assert.equal(await permission(method,prefix+suffix,body),null);
});
test('live module permissions and readonly preset are discoverable for checkboxes',()=>{
 for(const key of ['account_deletions.view','account_deletions.review','plans.view','plans.edit','plans.pricing','plans.publish','plans.billing'])assert.ok(permissionKeys.includes(key),key);
 const observer=permissionPresets.find(p=>p.id==='observer');assert.ok(observer.permissions.includes('plans.view'));assert.ok(observer.permissions.includes('account_deletions.view'));assert.equal(observer.permissions.includes('plans.billing'),false);
});
