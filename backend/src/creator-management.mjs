const statuses = ['pending', 'approved', 'rejected', 'suspended'];
const tiers = ['standard', 'verified', 'partner'];
const flags = ['canPublish', 'canReceiveOrders', 'identityVerified', 'agreementSigned', 'payoutReady'];

export function creatorManagementUpdate(current, value, actor = 'system') {
  if (!statuses.includes(value.status)) throw new Error('INVALID_CREATOR_STATUS');
  const previous = current.management ?? {};
  const management = { tier: 'standard', commissionRate: 0, manager: '',
    canPublish: false, canReceiveOrders: false, identityVerified: false, agreementSigned: false, payoutReady: false,
    ...previous };
  for (const key of ['tier', 'commissionRate', 'manager', ...flags]) {
    if (Object.hasOwn(value, key)) management[key] = value[key];
  }
  if (!tiers.includes(management.tier) || typeof management.manager !== 'string' || management.manager.length > 120
    || flags.some(key => typeof management[key] !== 'boolean')
    || !['number', 'string'].includes(typeof management.commissionRate)
    || String(management.commissionRate).trim() === ''
    || !Number.isFinite(Number(management.commissionRate)) || Number(management.commissionRate) < 0 || Number(management.commissionRate) > 100
    || (value.note !== undefined && (typeof value.note !== 'string' || value.note.length > 1000))) throw new Error('INVALID_CREATOR_PROFILE');
  management.commissionRate = Number(management.commissionRate);
  management.manager = management.manager.trim();
  management.note = (value.note ?? '').trim();
  const changes = {};
  for (const key of ['tier', 'commissionRate', 'manager', ...flags]) {
    if (previous[key] !== management[key]) changes[key] = { from: previous[key] ?? null, to: management[key] };
  }
  return { management, reviewNote: current.status !== value.status ? management.note : current.reviewNote,
    managementHistory: [...(current.managementHistory ?? []), { at: new Date().toISOString(), actor,
      previousStatus: current.status, status: value.status, manager: management.manager, note: management.note, changes }] };
}

export async function creatorRoute({ req, url, store, send, fail, readJson, actor }) {
  if (url.pathname === '/admin/creators' && req.method === 'GET') {
    const all = store.listCreatorProfiles();
    // Preserve the existing full list contract used by order assignment.
    if (!url.search) { send(200, { items: all }); return true; }
    const params = url.searchParams, pageSize = Number(params.get('pageSize') ?? 20), requestedPage = Number(params.get('page') ?? 1);
    const status = params.get('status') || '', tier = params.get('tier') || '', q = (params.get('q') || '').trim().toLowerCase();
    if (!Number.isInteger(pageSize) || pageSize < 1 || pageSize > 100 || !Number.isInteger(requestedPage) || requestedPage < 1
      || (status && !statuses.includes(status)) || (tier && !tiers.includes(tier)) || q.length > 254) {
      fail(400, 'INVALID_CREATOR_QUERY'); return true;
    }
    const summary = { total: all.length, pending: 0, approved: 0, rejected: 0, suspended: 0 };
    for (const item of all) if (statuses.includes(item.status)) summary[item.status]++;
    const filtered = all.filter(item => (!status || item.status === status)
      && (!tier || (item.management?.tier ?? 'standard') === tier)
      && `${item.displayName ?? ''} ${item.email ?? ''} ${item.id}`.toLowerCase().includes(q));
    const total = filtered.length, page = Math.min(requestedPage, Math.max(1, Math.ceil(total / pageSize)));
    const items = filtered.slice((page - 1) * pageSize, page * pageSize).map(item => ({
      id: item.id, displayName: item.displayName, email: item.email, status: item.status, version: item.version,
      marketRegion: item.marketRegion, skillTags: item.skillTags ?? [], createdAt: item.createdAt, updatedAt: item.updatedAt,
      management: { tier: item.management?.tier ?? 'standard', manager: item.management?.manager ?? '' },
    }));
    send(200, { items, total, page, pageSize, summary }); return true;
  }
  const route = /^\/admin\/creators\/([^/]+)$/.exec(url.pathname);
  if (!route || !['GET', 'POST'].includes(req.method)) return false;
  const id = decodeURIComponent(route[1]), creator = store.getCreatorProfile(id);
  if (!creator) { fail(404, 'NOT_FOUND'); return true; }
  if (req.method === 'GET') {
    const works = store.list().filter(item => item.ownerId === creator.userId || item.creator?.id === creator.id)
      .map(item => ({ id: item.id, title: item.title, format: item.format, status: item.status,
        submissionStatus: item.submissionStatus, reviewStatus: item.review?.decision, clipCount: item.clips?.length ?? 0 }));
    send(200, { creator, works }); return true;
  }
  const value = await readJson();
  if (!value || !Number.isInteger(value.version) || typeof value.status !== 'string') { fail(400, 'INVALID_CREATOR_UPDATE'); return true; }
  if (typeof value.note !== 'string' || !value.note.trim()) { fail(400, 'CREATOR_REASON_REQUIRED'); return true; }
  send(200, store.manageCreatorProfile(creator.id, value.version, value, actor)); return true;
}
