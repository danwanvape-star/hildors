const invalid=()=>{throw new Error('PLAN_INVALID_INPUT');};
const defaults=[[10,1999],[15,2999],[30,6999],[60,15999]];
export function customizationPlanOperations(db) {
 db.exec(`CREATE TABLE IF NOT EXISTS customization_plans(id TEXT PRIMARY KEY,version INTEGER NOT NULL,document TEXT NOT NULL);
 CREATE TABLE IF NOT EXISTS customization_plan_history(plan_id TEXT NOT NULL,version INTEGER NOT NULL,actor TEXT NOT NULL,at TEXT NOT NULL,snapshot TEXT NOT NULL,PRIMARY KEY(plan_id,version));`);
 const read=id=>{const r=db.prepare('SELECT * FROM customization_plans WHERE id=?').get(id);if(!r)return null;
  const p=JSON.parse(r.document),audio=p.audio??{markupPercent:20,apple:{productId:'',status:'not_connected'},google:{productId:'',status:'not_connected'}};
  const surchargeCents=Math.floor((p.usdBaseCents*audio.markupPercent+50)/100);
  return {...p,audio:{...audio,surchargeCents,totalUsdCents:p.usdBaseCents+surchargeCents},id:r.id,version:r.version,purchaseEnabled:false};};
 const audit=(p,actor)=>db.prepare('INSERT INTO customization_plan_history VALUES (?,?,?,?,?)').run(p.id,p.version,actor,new Date().toISOString(),JSON.stringify(p));
 for(const [i,[duration,price]] of defaults.entries()) {
  const id=`custom-${duration}s`;if(read(id))continue;
  db.prepare('INSERT INTO customization_plans VALUES (?,1,?)').run(id,JSON.stringify({durationSeconds:duration,usdBaseCents:price,description:{en:'',zh:''},sortOrder:i,listed:false,apple:{productId:'',status:'not_connected'},google:{productId:'',status:'not_connected'}}));audit(read(id),'system');
 }
 return {
  customizationPlans(){return db.prepare('SELECT id FROM customization_plans').all().map(r=>read(r.id)).sort((a,b)=>a.sortOrder-b.sortOrder||a.id.localeCompare(b.id));},
  customizationPlanSnapshot(id,audioMode='none'){const p=read(id);if(!p)throw new Error('PLAN_NOT_FOUND');if(!['none','matched'].includes(audioMode))invalid();
   const audio=audioMode==='matched';return {id:p.id,version:p.version,durationSeconds:p.durationSeconds,usdBaseCents:p.usdBaseCents,baseCurrency:'USD',description:p.description,audioMode,audioMarkupPercent:audio?p.audio.markupPercent:0,audioSurchargeCents:audio?p.audio.surchargeCents:0,totalUsdCents:audio?p.audio.totalUsdCents:p.usdBaseCents,appleProductId:(audio?p.audio:p).apple.productId,googleProductId:(audio?p.audio:p).google.productId};},
  customizationPlanHistory(id){return db.prepare('SELECT * FROM customization_plan_history WHERE plan_id=? ORDER BY version DESC').all(id).map(r=>({version:r.version,actor:r.actor,at:r.at,snapshot:JSON.parse(r.snapshot)}));},
  updateCustomizationPlan(id,value,actor='admin'){
   const p=read(id);if(!p||p.version!==value?.version)throw new Error('PLAN_CONFLICT');
   const permitted=['version','usdBaseCents','listed','durationSeconds','description','sortOrder','appleProductId','googleProductId','audioMarkupPercent','audioAppleProductId','audioGoogleProductId'];
   if(Object.keys(value).some(k=>!permitted.includes(k))||!Number.isSafeInteger(value.usdBaseCents)||value.usdBaseCents<1||value.usdBaseCents>1000000||typeof value.listed!=='boolean')invalid();
   const duration=value.durationSeconds??p.durationSeconds, sort=value.sortOrder??p.sortOrder, desc=value.description??p.description;
   if(!Number.isInteger(duration)||duration<1||duration>600||!Number.isInteger(sort)||sort<0||sort>10000||!desc||typeof desc.en!=='string'||typeof desc.zh!=='string'||desc.en.length>4000||desc.zh.length>4000)invalid();
   const apple=value.appleProductId??p.apple.productId, google=value.googleProductId??p.google.productId;
   const percent=value.audioMarkupPercent??p.audio.markupPercent, audioApple=value.audioAppleProductId??p.audio.apple.productId, audioGoogle=value.audioGoogleProductId??p.audio.google.productId;
   if(!Number.isInteger(percent)||percent<0||percent>100)invalid();
   if([apple,google,audioApple,audioGoogle].some(x=>typeof x!=='string'||(x!==''&&!/^[A-Za-z0-9_.-]{1,200}$/.test(x))))invalid();
   // Immutable price-version product IDs preserve quotes already issued to users.
   const history=db.prepare('SELECT snapshot FROM customization_plan_history').all().map(r=>JSON.parse(r.snapshot));
   const total=value.usdBaseCents+Math.floor((value.usdBaseCents*percent+50)/100);
   for(const [platform,silent,audioId] of [['apple',apple,audioApple],['google',google,audioGoogle]]) {
    if(silent&&silent===audioId)throw new Error('PLAN_PRODUCT_VERSION_REQUIRED');
    for(const [productId,mode,price] of [[silent,'none',value.usdBaseCents],[audioId,'matched',total]]) {
     if(!productId)continue;
     for(const old of history)for(const oldMode of ['none','matched']) {
      const binding=oldMode==='none'?old[platform]:old.audio?.[platform];
      const oldPrice=oldMode==='none'?old.usdBaseCents:old.usdBaseCents+Math.floor((old.usdBaseCents*(old.audio?.markupPercent??20)+50)/100);
      if(binding?.productId===productId&&(old.id!==id||oldMode!==mode||old.durationSeconds!==duration||oldPrice!==price))throw new Error('PLAN_PRODUCT_VERSION_REQUIRED');
     }
    }
   }
   const next={durationSeconds:duration,usdBaseCents:value.usdBaseCents,listed:value.listed,description:desc,sortOrder:sort,apple:{productId:apple,status:'not_connected'},google:{productId:google,status:'not_connected'},audio:{markupPercent:percent,apple:{productId:audioApple,status:'not_connected'},google:{productId:audioGoogle,status:'not_connected'}}};
   db.exec('SAVEPOINT plan_update');try {
    const changed=db.prepare('UPDATE customization_plans SET version=version+1,document=? WHERE id=? AND version=?').run(JSON.stringify(next),id,p.version);
    if(!changed.changes)throw new Error('PLAN_CONFLICT');
    audit(read(id),actor);db.exec('RELEASE plan_update');return read(id);
   }catch(e){db.exec('ROLLBACK TO plan_update; RELEASE plan_update');throw e;}
  },
 };
}

export async function customizationPlanRoute({req,url,store,send,fail,readJson,authorized=()=>false,actor='admin'}) {
 const path=url.pathname;
 if(path==='/v1/customization-plans'&&req.method==='GET'){send(200,{paymentMode:'disabled',items:store.customizationPlans().filter(p=>p.listed)});return true;}
 const m=/^\/admin\/customization-plans(?:\/([^/]+)(?:\/(history))?)?$/.exec(path);if(!m)return false;
 if(!authorized()){fail(401,'UNAUTHORIZED');return true;}
 try {
  if(req.method==='GET')send(200,{items:m[2]?store.customizationPlanHistory(m[1]):store.customizationPlans()});
  else if(req.method==='POST'&&m[1]&&!m[2]){const value=await readJson();if(!authorized()){fail(401,'UNAUTHORIZED');return true;}send(200,store.updateCustomizationPlan(m[1],value,actor));}
  else fail(405,'METHOD_NOT_ALLOWED');
 }catch(e){const status={PLAN_PRODUCT_VERSION_REQUIRED:409,PLAN_INVALID_INPUT:400,PLAN_CONFLICT:409,PLAN_NOT_FOUND:404}[e.message];if(!status)throw e;fail(status,e.message);}return true;
}
