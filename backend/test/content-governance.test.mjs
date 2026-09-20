import test from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { migrateGovernance,governanceOperations,governanceRoute } from '../src/content-governance.mjs';
function fixture(){
 const db=new DatabaseSync(':memory:');
 db.exec(`CREATE TABLE users(id TEXT PRIMARY KEY); CREATE TABLE packages(id TEXT PRIMARY KEY,status TEXT,document TEXT);
 CREATE TABLE creator_profiles(id TEXT PRIMARY KEY,user_id TEXT);CREATE TABLE entitlements(user_id TEXT,package_id TEXT,status TEXT);
 INSERT INTO users VALUES ('a'),('b'),('creator'); INSERT INTO creator_profiles VALUES ('profile','creator');
 INSERT INTO packages VALUES ('public','published','{"ownerId":"creator"}'),('hidden','draft','{"ownerId":"creator"}');`);
 migrateGovernance(db);return {db,store:governanceOperations(db)};
}
test('reports persist, reject hidden subjects and isolate accounts',()=>{
 const {db,store}=fixture();
 assert.throws(()=>store.createContentReport(null,{packageId:'public',reason:'abuse'}),/USER_AUTH_REQUIRED/);
 assert.throws(()=>store.createContentReport('a',{packageId:'hidden',reason:'copyright'}),/GOVERNANCE_NOT_FOUND/);
 assert.throws(()=>store.createContentReport('a',{packageId:'public',reason:'other',details:'x'.repeat(2001)}),/INVALID_INPUT/);
 const report=store.createContentReport('a',{packageId:'public',reason:'copyright',details:'My work'});
 assert.equal(report.status,'received');assert.throws(()=>store.getContentReport('b',report.id),/NOT_FOUND/);
 assert.deepEqual(store.listContentReports('b'),[]);
 const resolved=store.resolveContentReport(report.id,{version:1,status:'in_review',resolution:'Checking ownership'});
 assert.equal(resolved.version,2);assert.equal(store.getContentReport('a',report.id).status,'in_review');
 assert.throws(()=>store.resolveContentReport(report.id,{version:1,status:'no_violation',resolution:'Stale'}),/CONFLICT/);
 db.close();
});
test('blocks are scoped, idempotent and never change public content',()=>{
 const {db,store}=fixture();store.blockContentCreator('a',{packageId:'public'});store.blockContentCreator('a',{packageId:'public'});
 assert.equal(store.listBlockedCreators('a').length,1);assert.equal(store.listBlockedCreators('b').length,0);
 store.unblockContentCreator('b','profile');assert.equal(store.listBlockedCreators('a').length,1);
 assert.equal(db.prepare("SELECT status FROM packages WHERE id='public'").get().status,'published');
 store.unblockContentCreator('a','profile');assert.equal(store.listBlockedCreators('a').length,0);db.close();
});
test('route denies anonymous/admin access and rechecks auth after reading body',async()=>{
 const {db,store}=fixture();let result;const call=async(path,extra={})=>governanceRoute({req:{method:'POST'},url:new URL(path,'http://local'),store,send:(s,b)=>result=[s,b],fail:(s,c)=>result=[s,c],readJson:async()=>({packageId:'public',reason:'abuse'}),...extra});
 await call('/v1/me/reports');assert.equal(result[0],401);
 await call('/admin/reports/x',{userId:'a',authorized:()=>true});assert.equal(result[0],401);
 let valid=true;await call('/v1/me/reports',{userId:'a',authorized:()=>valid,readJson:async()=>{valid=false;return {};}});assert.equal(result[0],401);
 assert.equal(store.listContentReports('a').length,0);db.close();
});
