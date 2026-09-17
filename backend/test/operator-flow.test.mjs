import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm, readdir } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { app } from '../src/server.mjs';
import { createStore } from '../src/store.mjs';

test('operator creation requires tags, assigns stable code and processes uploads before approval without typed paperwork', async t => {
  const directory=await mkdtemp(join(tmpdir(),'operator-flow-')),store=createStore(); let inspections=0, running=0, peak=0, failNext=false;
  const server=app(store,{adminToken:'test',mediaDirectory:directory,inspector:async()=>{
    inspections++;peak=Math.max(peak,++running);await new Promise(r=>setTimeout(r,15));running--;
    if(failNext) {failNext=false;throw new Error('processor stopped');}
    return {status:'checked',durationSeconds:1};
  }});
  await new Promise(r=>server.listen(0,'127.0.0.1',r));
  t.after(async()=>{await new Promise(r=>server.close(r));store.close();await rm(directory,{recursive:true});});
  const base=`http://127.0.0.1:${server.address().port}`,headers={Authorization:'Bearer test','Content-Type':'application/json'};
  const post=async(path,body)=>{const r=await fetch(base+path,{method:'POST',headers,body:JSON.stringify(body)});return {status:r.status,body:await r.json()};};
  const draft={title:'角色',description:'背景',format:'package',tags:[],clips:[]};
  assert.equal((await post('/admin/packages',draft)).status,400);
  let result=await post('/admin/packages',{...draft,tags:['科幻未来']}),item=result.body;
  assert.equal(result.status,201);assert.match(item.contentCode,/^HD-/);const code=item.contentCode;
  const mp4=Buffer.alloc(32);mp4.write('ftyp',4);
  const upload=async p=>{const r=await fetch(base+`/admin/packages/${p.id}/clips?filename=test.mp4&process=auto`,{method:'PUT',headers:{Authorization:'Bearer test','Content-Type':'video/mp4','If-Match':String(p.version)},body:mp4});assert.equal(r.status,201);return r.json();};
  const another=(await post('/admin/packages',{...draft,tags:['科幻未来']})).body;
  [item]=await Promise.all([upload(item),upload(another)]);
  assert.equal(peak,1);assert.equal(inspections,2);assert.equal(item.clips[0].media.inspection.status,'checked');assert.equal(item.contentCode,code);
  const path=`/admin/packages/${item.id}`;
  assert.equal((await post(path+'/review',{version:item.version,decision:'rejected'})).status,400);
  result=await post(path+'/review',{version:item.version,decision:'approved'});
  assert.equal(result.status,200);item=result.body;assert.equal(item.review.decision,'approved');assert.ok(item.review.id);assert.equal(item.review.rightsReference,null);
  item=store.attachCover(item.id,item.version,{id:'cover'});
  item=(await post(path+'/review',{version:item.version,decision:'approved'})).body;
  item=(await post(path+'/publish',{version:item.version})).body;
  item=await upload(item);assert.equal(item.clips[1].visibility,'draft');
  result=await post(path+`/clips/${item.clips[1].id}/publish`,{version:item.version});
  assert.equal(result.status,200);assert.ok(result.body.clips[1].review.id);
  assert.equal((await readdir(directory)).filter(x=>x.endsWith('.mp4')).length,3);
  failNext=true;item=await upload(result.body);
  const failed=item.clips.at(-1);
  assert.equal(failed.media.inspection.status,'failed');
  assert.equal((await post(path+`/clips/${failed.id}/publish`,{version:item.version})).status,409);
  assert.equal((await readdir(directory)).filter(x=>x.endsWith('.mp4')).length,4);
  item=(await post(path+`/clips/${failed.id}/inspect`,{})).body;
  assert.equal(item.clips.at(-1).media.inspection.status,'checked');
  const legacy=store.create({...draft,clips:Array.from({length:100},(_,i)=>({id:`old-${i}`,title:'旧占位'}))});
  const migrated=await upload(legacy);assert.equal(migrated.clips.length,1);assert.equal(migrated.clips[0].title,'test');
});

test('inspection finishing after individual withdrawal cannot undo the withdrawal', () => {
  const store=createStore();
  try {
    let item=store.create({title:'Package',format:'package',tags:['科幻未来'],cover:{id:'cover'},clips:[{id:'one',title:'one',media:{id:'first',inspection:{status:'checked'}}}]});
    item=store.review(item.id,item.version,'approved','ok',null);item=store.transition(item.id,item.version,'published');
    item=store.appendClip(item.id,item.version,'two',{id:'second'});const second=item.clips[1].id;
    item=store.setInspection(item.id,second,'second',{status:'processing'});
    item=store.transitionClip(item.id,second,item.version,'withdrawn');
    item=store.setInspection(item.id,second,'second',{status:'checked'});
    assert.equal(item.clips[1].visibility,'withdrawn');assert.equal(item.review.decision,'approved');
  } finally {store.close();}
});
