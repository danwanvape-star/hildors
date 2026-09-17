import test from 'node:test';
import assert from 'node:assert/strict';
import {createStore} from '../src/store.mjs';
import {app} from '../src/server.mjs';

test('creator pages stay bounded and owned while retaining complete editable stories', async t => {
  const store=createStore(), server=app(store);
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  t.after(async()=>{await new Promise(resolve=>server.close(resolve));store.close();});
  const user=store.createUser(), profile=store.upsertCreatorProfile(user,{displayName:'Page',email:'page@example.test'});
  store.reviewCreatorProfile(profile.id,profile.version,'approved');
  const token=store.createSession(user);
  for(let i=1;i<=5;i++) store.create({title:'角色',description:'故'.repeat(10000),format:'single',source:'creator',ownerId:user,submissionStatus:'draft',tags:[],clips:[{id:'c',title:'待机'}]},`owned-${i}`);
  store.create({ownerId:'another',clips:[]},'owned-0');
  const get=async suffix=>fetch(`http://127.0.0.1:${server.address().port}/v1/me/content${suffix}`,{headers:{Authorization:`Bearer ${token}`}});
  const first=await (await get('?limit=2')).json();
  assert.deepEqual(first.items.map(x=>x.id),['owned-1','owned-2']);
  assert.equal(first.items[0].description.length,10000);
  assert.equal(first.nextCursor,'owned-2');
  const second=await (await get('?limit=2&cursor='+first.nextCursor)).json();
  assert.deepEqual(second.items.map(x=>x.id),['owned-3','owned-4']);
  const last=await (await get('?limit=2&cursor='+second.nextCursor)).json();
  assert.deepEqual(last.items.map(x=>x.id),['owned-5']);
  assert.equal(last.nextCursor,null);
  assert.equal((await get('?limit=999')).status,400);
});
