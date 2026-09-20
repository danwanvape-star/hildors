// Order operations share the existing SQLite connection and optimistic version.
export function orderOperations(db) {
  const parse = row => row ? ({...JSON.parse(row.document),id:row.id,userId:row.user_id,version:row.version,status:row.status,createdAt:row.created_at,updatedAt:row.updated_at}) : null;
  const summary = o => Object.fromEntries(['id','userId','version','status','characterName','sourceType','materialCount','materialsUploaded','dispatchMode','dispatchState','assignedCreatorId','assignedCreatorName','createdAt','updatedAt','marketRegion'].map(k=>[k,o[k]]).concat([['dueAt',o.workflow?.dueAt],['applicantCount',(o.applicantCreatorIds??[]).length]]));
  function save(current, patch, action, note = '', actor = 'admin') {
    if (typeof note !== 'string' || note.length > 1000) throw new Error('ORDER_INVALID_NOTE');
    const now = new Date().toISOString(), status = patch.status ?? current.status;
    const document = {...current,...patch,workflowHistory:[...(current.workflowHistory??[]),{from:current.status,to:status,action,note:note.trim(),actor,at:now}]};
    for(const k of ['id','userId','version','status','createdAt','updatedAt']) delete document[k];
    const changed = db.prepare('UPDATE customization_orders SET document=?,status=?,version=version+1,updated_at=? WHERE id=? AND version=?').run(JSON.stringify(document),status,now,current.id,current.version);
    if (!changed.changes) throw new Error('CONFLICT');
    return parse(db.prepare('SELECT * FROM customization_orders WHERE id=?').get(current.id));
  }
  function requireVersion(order, version) { if(!order || !Number.isInteger(version) || order.version!==version) throw new Error('CONFLICT'); }
  function eligible(creator) { return creator?.status==='approved' && creator.management?.canReceiveOrders===true; }
  function taskView(order, creatorId) {
    if(order.assignedCreatorId===creatorId) {const view={...order};delete view.verifiedContactEmail;return view;}
    return Object.fromEntries(['id','version','status','characterName','sourceType','requestedFeatures','requirements','dispatchMode','dispatchState','applicantCreatorIds','createdAt'].map(k=>[k,order[k]]));
  }
  return {
    orderTaskView: taskView,
    customerOrderView(order) {
      const view={...order,workflow:{...(order.workflow??{})},workflowHistory:(order.workflowHistory??[]).map(h=>h.action==='creator_submitted'?{...h,note:'创作者已提交成果，等待平台质检'}:h)};
      delete view.workflow.deliverableReference; delete view.workflow.deliveryReference;
      if(order.productionUpdates)view.productionUpdates=order.productionUpdates.map(({text,at})=>({text,at}));
      delete view.creatorQuote; delete view.applicantCreatorIds;
      return view;
    },
    eligibleOrderCreator: eligible,
    orderCreatorPool() {
      const counts=new Map(db.prepare("SELECT json_extract(document,'$.assignedCreatorId') AS creator_id,count(*) AS n FROM customization_orders WHERE status NOT IN ('delivered','rejected','withdrawn') GROUP BY creator_id").all().map(r=>[r.creator_id,r.n]));
      return this.listCreatorProfiles().filter(eligible).map(c=>({id:c.id,userId:c.userId,displayName:c.displayName,status:c.status,skillTags:c.skillTags??[],management:{canReceiveOrders:true},activeOrderCount:counts.get(c.id)??0}));
    },
    findOrderRequest(userId, key) { return parse(db.prepare("SELECT * FROM customization_orders WHERE user_id=? AND json_extract(document,'$.clientRequestId')=?").get(userId,key)); },
    pageCustomizationOrders(params) {
      const pageSize = Math.min(100,Math.max(1,Number.parseInt(params.get('pageSize')||'20')||20));
      let page = Math.max(1,Number.parseInt(params.get('page')||'1')||1);
      const clauses=[], args=[];
      const kind=params.get('kind');
      const kindClause=kind==='plan'?"json_extract(document,'$.planSnapshot') IS NOT NULL":kind==='legacy'?"json_extract(document,'$.planSnapshot') IS NULL":'';
      if(kindClause) clauses.push(kindClause);
      const status=params.get('status'), mode=params.get('dispatchMode'), q=(params.get('q')||'').trim().slice(0,120);
      if(status) { clauses.push('status=?');args.push(status); }
      if(mode) { clauses.push("json_extract(document,'$.dispatchMode')=?");args.push(mode); }
      if(q) { clauses.push("(instr(lower(id),lower(?))>0 OR instr(lower(user_id),lower(?))>0 OR instr(lower(json_extract(document,'$.characterName')),lower(?))>0 OR instr(lower(coalesce(json_extract(document,'$.assignedCreatorName'),'')),lower(?))>0)");args.push(q,q,q,q); }
      const where=clauses.length?' WHERE '+clauses.join(' AND '):'';
      const total=db.prepare('SELECT count(*) AS n FROM customization_orders'+where).get(...args).n;
      page=Math.min(page,Math.max(1,Math.ceil(total/pageSize)));
      const items=db.prepare('SELECT * FROM customization_orders'+where+' ORDER BY created_at DESC,id DESC LIMIT ? OFFSET ?').all(...args,pageSize,(page-1)*pageSize).map(parse).map(o => ({...summary(o), ...(o.planSnapshot ? {planSummary:{durationSeconds:o.planSnapshot.durationSeconds,audioMode:o.planSnapshot.audioMode,paymentStatus:o.payment?.status ?? 'unpaid'}} : {})}));
      const counts={total:0,free_review:0,in_production:0};
      for(const row of db.prepare('SELECT status,count(*) AS n FROM customization_orders'+(kindClause?' WHERE '+kindClause:'')+' GROUP BY status').all()) {counts[row.status]=row.n;counts.total+=row.n;}
      return {items,total,page,pageSize,counts};
    },
    attachOrderMaterial(id, userId, material, slot) {
      const order=this.getCustomizationOrder(id);
      if(!order || order.userId!==userId) throw new Error('CONFLICT');
      if(!['free_review','needs_info','approved_for_quote'].includes(order.status)) throw new Error('ORDER_MATERIAL_LOCKED');
      const materials=order.materials??[];
      if(materials.some(m=>m.slot===slot)) return order;
      if(materials.length>=8) throw new Error('ORDER_MATERIAL_LIMIT');
      const next=[...materials,{...material,slot}];
      return save(order,{materials:next,materialsUploaded:next.length>=Math.max(1,order.materialCount??1)},'material_uploaded',material.name,userId);
    },
    removeOrderMaterial(id,userId,materialId,version) {
      const order=this.getCustomizationOrder(id); requireVersion(order,version);
      if(order.userId!==userId) throw new Error('ORDER_NOT_OWNER');
      if(!['free_review','needs_info','approved_for_quote'].includes(order.status)) throw new Error('ORDER_MATERIAL_LOCKED');
      const materials=(order.materials??[]).filter(m=>m.id!==materialId);
      if(materials.length===(order.materials??[]).length) throw new Error('CONFLICT');
      return save(order,{materials,materialsUploaded:materials.length>=Math.max(1,order.materialCount??1)},'material_removed','移除参考图',userId);
    },
    recoverLegacyOrder(id, value) {
      const order=this.getCustomizationOrder(id);requireVersion(order,value?.version);
      if(order.planSnapshot || order.dispatchMode || order.assignedCreatorId || !['quoted','in_production','quality_review','user_acceptance'].includes(order.status)) throw new Error('ORDER_RECOVERY_STAGE');
      if(typeof value.note!=='string'||!value.note.trim()) throw new Error('ORDER_NOTE_REQUIRED');
      return save(order,{status:'needs_info',workflow:{},creatorQuote:null,quoteAcceptedAt:null,acceptedAt:null,
        dispatchMode:null,dispatchState:'unassigned',assignedCreatorId:null,assignedCreatorName:null,applicantCreatorIds:[],
        legacyRecoveryAt:new Date().toISOString(),materialsUploaded:(order.materials??[]).length>=Math.max(1,order.materialCount??1)},'legacy_recovered',value.note);
    },
    dispatchOrder(id, value) {
      const order=this.getCustomizationOrder(id);requireVersion(order,value?.version);
      if(order.planSnapshot) throw new Error('ORDER_DISPATCH_STAGE');
      if(order.status!=='approved_for_quote') throw new Error('ORDER_DISPATCH_STAGE');
      if(!['direct','applications'].includes(value.mode)) throw new Error('ORDER_DISPATCH_MODE');
      if(value.dueAt && (!/^\d{4}-\d{2}-\d{2}$/.test(value.dueAt)||!Number.isFinite(Date.parse(value.dueAt)))) throw new Error('ORDER_INVALID_DATE');
      let creator=null;
      if(value.creatorId) {
        creator=this.getCreatorProfile(value.creatorId);
        if(!eligible(creator)) throw new Error('ORDER_CREATOR_INELIGIBLE');
        if(creator.userId===order.userId) throw new Error('ORDER_SELF_ASSIGNMENT');
        if(value.mode==='applications' && !(order.applicantCreatorIds??[]).includes(creator.id)) throw new Error('ORDER_APPLICATION_REQUIRED');
      } else if(value.mode==='direct') throw new Error('ORDER_CREATOR_REQUIRED');
      return save(order,{dispatchMode:value.mode,dispatchState:creator?'assigned':'open',assignedCreatorId:creator?.id??null,assignedCreatorName:creator?.displayName??null,
        creatorQuote:null,applicantCreatorIds:order.applicantCreatorIds??[],workflow:{...(order.workflow??{}),assignee:creator?.displayName??'',...(value.dueAt?{dueAt:value.dueAt}:{})}},creator?'assigned':'applications_opened',value.note??'');
    },
    listCreatorTasks(userId) {
      const creator=this.getCreatorProfile(userId);
      if(!eligible(creator)) throw new Error('ORDER_CREATOR_INELIGIBLE');
      return db.prepare("SELECT * FROM customization_orders WHERE json_extract(document,'$.assignedCreatorId')=? OR (status='approved_for_quote' AND json_extract(document,'$.dispatchMode')='applications' AND json_extract(document,'$.dispatchState')='open' AND user_id<>?) ORDER BY created_at DESC").all(creator.id,userId).map(parse).filter(o=>!o.planSnapshot).map(o=>taskView(o,creator.id));
    },
    creatorOrderAction(id,userId,value) {
      const creator=this.getCreatorProfile(userId);
      if(!eligible(creator)) throw new Error('ORDER_CREATOR_INELIGIBLE');
      const order=this.getCustomizationOrder(id);requireVersion(order,value?.version);
      const note=value.note??'', fields=value.fields??{};
      if(value.action==='apply') {
        if(order.status!=='approved_for_quote'||order.dispatchMode!=='applications'||order.dispatchState!=='open'||order.userId===userId) throw new Error('ORDER_APPLICATION_CLOSED');
        if((order.applicantCreatorIds??[]).includes(creator.id)) return taskView(order,creator.id);
        return taskView(save(order,{applicantCreatorIds:[...(order.applicantCreatorIds??[]),creator.id]},'creator_applied',note,creator.id),creator.id);
      }
      if(order.assignedCreatorId!==creator.id) throw new Error('ORDER_NOT_ASSIGNED');
      if(value.action==='decline' && order.status==='approved_for_quote') {
        if(!note.trim()) throw new Error('ORDER_NOTE_REQUIRED');
        return taskView(save(order,{assignedCreatorId:null,assignedCreatorName:null,dispatchState:order.dispatchMode==='applications'?'open':'unassigned',creatorQuote:null,
          applicantCreatorIds:(order.applicantCreatorIds??[]).filter(x=>x!==creator.id)},'creator_declined',note,creator.id),creator.id);
      }
      if(value.action==='quote' && order.status==='approved_for_quote') {
        const amount=Number(fields.quoteAmount),days=Number(fields.deliveryDays);
        if(!Number.isFinite(amount)||amount<=0||amount>1000000||!Number.isInteger(days)||days<1||days>365||!['USD','CNY','EUR','GBP','JPY','HKD'].includes(fields.currency)) throw new Error('ORDER_QUOTE_REQUIRED');
        return save(order,{creatorQuote:{quoteAmount:amount,currency:fields.currency,deliveryDays:days,at:new Date().toISOString()}},'creator_quoted',note,creator.id);
      }
      if(value.action==='submit' && order.status==='in_production') {
        if(typeof fields.deliverableReference!=='string'||!fields.deliverableReference.trim()||fields.deliverableReference.length>1000) throw new Error('ORDER_DELIVERABLE_REQUIRED');
        return save(order,{status:'quality_review',workflow:{...order.workflow,deliverableReference:fields.deliverableReference.trim(),qcPassed:false,deliveryReference:null}},'creator_submitted',note,creator.id);
      }
      throw new Error('INVALID_ORDER_TRANSITION');
    },
    customerOrderAction(id,userId,value) {
      const order=this.getCustomizationOrder(id);requireVersion(order,value?.version);
      if(order.planSnapshot) return this.planOrderAction(id,userId,value);
      if(order.userId!==userId) throw new Error('ORDER_NOT_OWNER');
      if(value.action==='accept_quote' && order.status==='quoted' && order.assignedCreatorId) {
        if(!eligible(this.getCreatorProfile(order.assignedCreatorId))) throw new Error('ORDER_CREATOR_INELIGIBLE');
        const days=Number(order.workflow?.deliveryDays);
        if(!Number.isFinite(days)||days<=0) throw new Error('ORDER_QUOTE_REQUIRED');
        return save(order,{status:'in_production',quoteAcceptedAt:new Date().toISOString(),workflow:{...order.workflow,dueAt:new Date(Date.now()+days*86400000).toISOString().slice(0,10)}},'quote_accepted',value.note??'',userId);
      }
      if(value.action==='accept_delivery' && order.status==='user_acceptance') {
        if(!order.workflow?.deliveryReference) throw new Error('ORDER_DELIVERY_REQUIRED');
        return save(order,{status:'delivered',acceptedAt:new Date().toISOString()},'delivery_accepted',value.note??'',userId);
      }
      if(value.action==='request_revision' && order.status==='user_acceptance') {
        if(typeof value.note!=='string'||!value.note.trim()) throw new Error('ORDER_NOTE_REQUIRED');
        return save(order,{status:'in_production',workflow:{...order.workflow,qcPassed:false,deliveryReference:null}},'revision_requested',value.note,userId);
      }
      throw new Error('INVALID_ORDER_TRANSITION');
    },
  };
}
