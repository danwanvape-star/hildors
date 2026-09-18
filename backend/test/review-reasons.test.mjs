import test from 'node:test';
import assert from 'node:assert/strict';
import {createStore} from '../src/store.mjs';
test('order approval and QC need no prose; returning work requires a reason',t=>{
  const store=createStore();t.after(()=>store.close());
  let o=store.createCustomizationOrder(store.createUser(),{characterName:'Test',requestedFeatures:['idle']});
  for(const status of ['needs_info','rejected']) assert.throws(()=>store.updateCustomizationOrderWorkflow(o.id,o.version,status),/ORDER_NOTE_REQUIRED/);
  o=store.updateCustomizationOrderWorkflow(o.id,o.version,'approved_for_quote');
  o=store.updateCustomizationOrderWorkflow(o.id,o.version,'quoted','',{quoteAmount:10,currency:'USD',deliveryDays:3});
  o=store.updateCustomizationOrderWorkflow(o.id,o.version,'in_production','',{assignee:'Maker',dueAt:'2026-10-01'});
  o=store.updateCustomizationOrderWorkflow(o.id,o.version,'quality_review','',{deliverableReference:'test-result'});
  assert.throws(()=>store.updateCustomizationOrderWorkflow(o.id,o.version,'in_production','',{assignee:'Maker',dueAt:'2026-10-01'}),/ORDER_NOTE_REQUIRED/);
  assert.throws(()=>store.updateCustomizationOrderWorkflow(o.id,o.version,'user_acceptance'),/ORDER_QC_REQUIRED/);
  o=store.updateCustomizationOrderWorkflow(o.id,o.version,'user_acceptance','',{qcPassed:true});
  assert.throws(()=>store.updateCustomizationOrderWorkflow(o.id,o.version,'quality_review','',{deliverableReference:'test-result'}),/ORDER_NOTE_REQUIRED/);
});
