// All delivery decisions are server-side and re-evaluated on each request.
export function authorizedClip(store, userId, packageId, clipId) {
  if (!store.entitlements(userId).some(e => e.package_id === packageId && e.status === 'active')) return null;
  const item = store.get(packageId);
  if (!item || item.status !== 'published' || item.demo || item.review?.decision !== 'approved') return null;
  const clip = item.clips.find(c => c.id === clipId);
  const media = clip?.media;
  if (!media || media.inspection?.status !== 'checked'
    || !/^[a-f0-9-]{36}$/.test(media.id) || !/^[a-f0-9]{64}$/.test(media.sha256)
    || !Number.isSafeInteger(media.bytes) || media.bytes <= 0) return null;
  return { item, clip, media };
}
