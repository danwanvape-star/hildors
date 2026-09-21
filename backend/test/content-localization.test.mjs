import test from 'node:test';
import assert from 'node:assert/strict';
import { createStore } from '../src/store.mjs';
import { app } from '../src/server.mjs';
async function fixture(t) {
 const store=createStore(); const server=app(store,{adminToken:'admin',enableDownloads:true});
 await new Promise(r=>server.listen(0,'127.0.0.1',r));
 t.after(async()=>{await new Promise(r=>server.close(r));store.close();});
 const call=async(path,value,headers={Authorization:'Bearer admin'})=>{const r=await fetch(`http://127.0.0.1:${server.address().port}${path}`,{method:value===undefined?'GET':'POST',headers:{'Content-Type':'application/json',...headers},body:value===undefined?undefined:JSON.stringify(value)});return {status:r.status,data:await r.json()};};
 return {store,call};
}
const document={title:'角色',description:'中文背景',tags:['科幻未来'],format:'single',clips:[{id:'main',title:'视频',description:'中文视频介绍'}]};
test('translation round trip leaves Chinese legacy, publication and concurrency unchanged',async t=>{
 const {call}=await fixture(t);
 let r=await call('/admin/packages',{...document,translations:{en:{title:'Hero',description:'Story'}},clips:[{...document.clips[0],translations:{en:{title:'Video',description:'Video story'}}}]});
 assert.equal(r.status,201);let item=r.data;
 assert.equal(item.translations.en.title,'Hero');assert.equal(item.title,'角色');assert.equal(item.clips[0].translations.en.description,'Video story');assert.deepEqual(item.tagIds,['genre-4']);assert.equal(item.status,'draft');
 const update={...document,version:item.version,translations:{en:{title:'Hero 2',description:''}},clipTranslations:[{id:'main',translations:{en:{title:'Video 2',description:'Detail'}}}]};
 r=await call(`/admin/packages/${item.id}/metadata`,update);assert.equal(r.status,200);assert.equal(r.data.clips[0].translations.en.title,'Video 2');assert.equal(r.data.status,'draft');
 assert.equal((await call(`/admin/packages/${item.id}/metadata`,update)).status,409);
 assert.equal((await call(`/admin/packages/${item.id}/metadata`,{...update,version:r.data.version},{})).status,401);
 assert.equal((await call(`/admin/packages/${item.id}/metadata`,{...update,version:r.data.version,translations:{fr:{title:'x'}}})).status,400);
 assert.equal((await call(`/admin/packages/${item.id}/metadata`,{...update,version:r.data.version,clipTranslations:[{id:'missing',translations:{en:{title:'x'}}}]})).status,400);
 const old=await call(`/admin/packages/${item.id}/metadata`,{...document,version:r.data.version});assert.equal(old.status,200);assert.equal(old.data.translations.en.title,'Hero 2');
});
test('explicit locales resolve selected then English then legacy without modifying legacy public keys',async t=>{
 const {call,store}=await fixture(t);
 const draft=store.create({...document,demo:true,translations:{en:{title:'Hero'},zh:{description:'新版背景'}},clips:[{...document.clips[0],bundledAsset:'demo.mp4',translations:{en:{description:'English clip'}}}]});store.transition(draft.id,draft.version,'published');
 const path=`/v1/packages/${draft.id}`;
 const en=(await call('/v1/catalog?lang=en')).data.items[0];assert.equal(en.title,'角色');assert.equal(en.localized.title,'Hero');assert.equal(en.localized.description,'中文背景');assert.deepEqual(en.localized.missingFields,['description']);assert.equal(en.clips[0].localized.description,'English clip');
 const zh=(await call('/v1/catalog?lang=zh-Hant')).data.items[0];assert.equal(zh.localized.language,'zh');assert.equal(zh.localized.title,'Hero');assert.equal(zh.localized.description,'新版背景');
 const unknown=(await call('/v1/catalog?lang=ja')).data.items[0];assert.equal(unknown.localized.language,'en');
 const header=(await call('/v1/catalog',undefined,{'Accept-Language':'zh-TW, en;q=0.8'})).data.items[0];assert.equal(header.localized.language,'zh');
 const legacy=(await call('/v1/catalog',undefined,{})).data.items[0];assert.equal(legacy.title,'角色');assert.equal(legacy.localized.language,'en');
 assert.equal((await call(path+'?lang=en')).data.localized.title,'Hero');
});
test('tag translations remain keyed by stable IDs and omitted translations survive old saves',async t=>{
 const {call,store}=await fixture(t);const tags=store.contentTags();const tag=tags.find(t=>t.id==='genre-4');
 let r=await call('/admin/content-tags',{items:tags.map(t=>t.id===tag.id?{...t,translations:{en:{name:'Science fiction'}}}:t)});assert.equal(r.status,200);assert.equal(r.data.items.find(t=>t.id===tag.id).translations.en.name,'Science fiction');
 r=await call('/admin/content-tags',{items:tags});assert.equal(r.data.items.find(t=>t.id===tag.id).translations.en.name,'Science fiction');
 const publicTags=(await call('/v1/content-tags?lang=en')).data.items;assert.equal(publicTags.find(t=>t.id===tag.id).localized.name,'Science fiction');
});

test('stable tag selection survives rename and localized catalog filtering uses the ID',async t=>{
 const {call,store}=await fixture(t);
 const draft=store.create({...document,demo:true,clips:[{...document.clips[0],bundledAsset:'demo.mp4'}]});store.transition(draft.id,draft.version,'published');
 const tags=store.contentTags();await call('/admin/content-tags',{items:tags.map(tag=>tag.id==='genre-4'?{...tag,name:'未来幻想',translations:{en:{name:'Future fantasy'}}}:tag)});
 const response=await call('/v1/catalog?lang=en&tag=genre-4');const item=response.data.items[0];
 assert.deepEqual(item.tags,['科幻未来']);assert.deepEqual(item.tagIds,['genre-4']);assert.equal(item.tagDetails[0].id,'genre-4');assert.equal(item.tagDetails[0].localized.name,'Future fantasy');
});
test('creator translation updates require ownership and editable moderation state',async t=>{
 const {call,store}=await fixture(t);
 function creator(name){const id=store.createUser();const p=store.upsertCreatorProfile(id,{displayName:name,email:name+'@example.test'});store.reviewCreatorProfile(p.id,p.version,'approved');return {id,headers:{Authorization:'Bearer '+store.createSession(id)}};}
 const alice=creator('alice'),bob=creator('bob');
 const created=await call('/v1/me/content',{...document,translations:{en:{title:'Creator hero'}}},alice.headers);assert.equal(created.status,201);const item=created.data;
 const path=`/v1/me/content/${item.id}/metadata`;const value={...document,version:item.version,translations:{en:{title:'Revised'}}};
 assert.equal((await call(path,value,bob.headers)).status,404);assert.equal((await call(path,value,alice.headers)).status,200);
 const pending=store.create({...document,ownerId:alice.id,source:'creator',submissionStatus:'pending'});
 assert.equal((await call(`/v1/me/content/${pending.id}/metadata`,{...value,version:pending.version},alice.headers)).status,409);
});
test('locale cannot expose a paid original or grant clip download permission',async t=>{
 const {call,store}=await fixture(t);const id=store.createUser(),token=store.createSession(id);
 const item=store.create({...document,demo:true,translations:{en:{title:'Paid hero'}},clips:[{id:'paid',title:'付费',bundledAsset:'demo.mp4',pricing:{mode:'paid',currency:'USD',amountMinor:100},media:{id:'11111111-1111-4111-8111-111111111111',inspection:{status:'checked'}}}]});store.transition(item.id,item.version,'published');store.setEntitlement(id,item.id,'active','test');
 const catalog=(await call('/v1/catalog?lang=en')).data.items[0];assert.equal(catalog.localized.title,'Paid hero');assert.equal(catalog.clips[0].previewPath,undefined);
 const access=await call(`/v1/me/packages/${item.id}/clips/paid/access?lang=en`,undefined,{Authorization:'Bearer '+token});assert.equal(access.data.canDownload,false);
 assert.equal((await call(`/v1/me/packages/${item.id}/clips/paid/download?lang=zh-Hant`,undefined,{Authorization:'Bearer '+token})).status,404);
 assert.equal((await call('/v1/media/11111111-1111-4111-8111-111111111111?lang=en')).status,404);
});
test('language quality and explicit query precedence, malformed translation validation',async t=>{
 const {call,store}=await fixture(t);const item=store.create({...document,demo:true,clips:[{...document.clips[0],bundledAsset:'demo.mp4'}]});store.transition(item.id,item.version,'published');
 const value=(await call('/v1/catalog?lang=zh-HK',undefined,{'Accept-Language':'en'})).data.items[0];assert.equal(value.localized.language,'zh');
 const quality=(await call('/v1/catalog',undefined,{'Accept-Language':'zh;q=0, en;q=0.8'})).data.items[0];assert.equal(quality.localized.language,'en');
 for(const translations of [null,[],{en:{title:42}},{en:{title:'x'.repeat(121)}},{en:{pricing:{mode:'free'}}}]) assert.equal((await call('/admin/packages',{...document,translations})).status,400);
 assert.equal((await call('/admin/content-tags',{items:[{id:'genre-4',name:'科幻未来',active:true,translations:{en:{name:4}}}]})).status,400);
});
