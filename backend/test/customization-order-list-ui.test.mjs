import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFile} from 'node:fs/promises';
class Element {
 constructor(tag){this.tag=tag;this.style={};this.children=[];this.value='';this.isConnected=true;this.disabled=false;}
 append(...nodes){this.children.push(...nodes);}
 replaceChildren(...nodes){this.children=nodes;}
 replaceWith(node){this.replacement=node;this.isConnected=false;}
}
test('order list loads only summaries, lazy detail retries, and filters reset page',async()=>{
 const ids=new Map(['orders','message','page','previous','next','refresh','order-query','order-status','order-filters','clear-filters'].map(id=>[id,new Element(id)]));
 const calls=[];let failDetail=true;
 const document={getElementById:id=>ids.get(id),createElement:tag=>new Element(tag),querySelectorAll:()=>[...ids.values()]};
 const order={id:'plan-order',version:1,characterName:'Fox',status:'delivered',planSummary:{durationSeconds:10},planSnapshot:{durationSeconds:10},requirements:'Blue eyes',userId:'test'};
 const fetch=async url=>{calls.push(String(url));if(url==='/admin/me')return{ok:true,json:async()=>({permissions:['orders.view','orders.review','orders.quote','orders.deliver']})};if(String(url).includes('?'))return {ok:true,json:async()=>({items:[order],total:1,page:1,pageSize:20})};if(failDetail)return{ok:false,status:503};return{ok:true,json:async()=>order};};
 const context=vm.createContext({document,fetch,URLSearchParams,Intl,BigInt,Date,console});
 vm.runInContext(await readFile(new URL('../public/customization-orders-v2.js',import.meta.url),'utf8'),context);
 const flush=()=>new Promise(resolve=>setImmediate(resolve));await flush();
 assert.equal(calls.length,2);assert.match(calls[1],/kind=plan/);
 const row=ids.get('orders').children[0];row.open=true;row.ontoggle();await flush();assert.equal(calls.length,3);
 const retry=row.children[1].children[1];assert.equal(retry.textContent,'重新读取详情');failDetail=false;await retry.onclick();await flush();assert.ok(row.replacement);assert.equal(row.replacement.open,true);
 ids.get('order-query').value='Blue Fox';ids.get('order-status').value='free_review';ids.get('order-filters').onsubmit({preventDefault(){}});await flush();
 const params=new URL(calls.at(-1),'http://test').searchParams;assert.equal(params.get('q'),'Blue Fox');assert.equal(params.get('status'),'free_review');assert.equal(params.get('page'),'1');
 ids.get('clear-filters').onclick();await flush();assert.equal(new URL(calls.at(-1),'http://test').searchParams.get('q'),'');
});
