import test from 'node:test';
import assert from 'node:assert/strict';
import { request } from 'node:http';
import { createStore } from '../src/store.mjs';
import { app } from '../src/server.mjs';

for (const actor of ['creator', 'customer']) test(`revoked ${actor} session cannot finish a delayed order mutation`, async t => {
  const store = createStore(), server = app(store);
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(async () => { await new Promise(resolve => server.close(resolve)); store.close(); });
  const customer = store.createUser(), maker = store.createUser();
  let creator = store.upsertCreatorProfile(maker, {displayName:'Maker',email:'maker@example.test'});
  creator = store.manageCreatorProfile(creator.id, creator.version, {status:'approved',canReceiveOrders:true});
  let order = store.createCustomizationOrder(customer, {characterName:'Test',materialCount:0,requestedFeatures:[]});
  order = store.updateCustomizationOrderWorkflow(order.id, order.version, 'approved_for_quote');
  order = store.dispatchOrder(order.id, {version:order.version,mode:'direct',creatorId:creator.id});
  if (actor === 'customer') {
    order = store.creatorOrderAction(order.id, maker, {version:order.version,action:'quote',fields:{quoteAmount:100,currency:'USD',deliveryDays:7}});
    order = store.updateCustomizationOrderWorkflow(order.id, order.version, 'quoted', '', {quoteAmount:100,currency:'USD',deliveryDays:7});
  }
  const token = store.createSession(actor === 'creator' ? maker : customer);
  const body = JSON.stringify({version:order.version, action:actor === 'creator'?'quote':'accept_quote', fields:{quoteAmount:100,currency:'USD',deliveryDays:7}});
  let reached; const started = new Promise(resolve => { reached=resolve; });
  const original = store.getCustomizationOrder.bind(store);
  store.getCustomizationOrder = id => { const value=original(id); reached(); return value; };
  let pending;
  const result = new Promise((resolve,reject) => {
    const path = actor === 'creator' ? `/v1/me/creator-tasks/${order.id}` : `/v1/me/customization-orders/${order.id}/action`;
    pending = request(`http://127.0.0.1:${server.address().port}${path}`, {method:'POST',headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'}}, response => {
      response.resume(); response.on('end',()=>resolve(response.statusCode));
    });
    pending.on('error',reject); pending.write(body.slice(0,1));
  });
  await started; store.revokeSession(token); pending.end(body.slice(1));
  assert.equal(await result, 401);
  assert.equal(store.getCustomizationOrder(order.id).version, order.version);
});
