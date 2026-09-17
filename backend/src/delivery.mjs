// All delivery decisions are server-side and re-evaluated on each request.
import { validPricing, publicFullPreview } from './clip-pricing.mjs';
export function authorizedClip(store, userId, packageId, clipId) {
  const item = store.get(packageId);
  if (!item || item.status !== 'published' || item.demo || item.review?.decision !== 'approved') return null;
  const clip = item.clips.find(c => c.id === clipId);
  if (!clip) return null;
  if (clip.pricing !== undefined) {
    if (!validPricing(clip.pricing) || clip.pricing.mode !== 'free') return null;
  } else if (!store.entitlements(userId).some(e => e.package_id === packageId && e.status === 'active')) return null;
  const media = clip.media;

  if (!media || media.inspection?.status !== 'checked'
    || !/^[a-f0-9-]{36}$/.test(media.id) || !/^[a-f0-9]{64}$/.test(media.sha256)
    || !Number.isSafeInteger(media.bytes) || media.bytes <= 0) return null;
  // Aliases of the same bytes cannot bypass configured paid or invalid pricing.
  if ((store.list?.() ?? [item]).some(p => p.clips.some(c =>
    c.media?.id === media.id && !publicFullPreview(c)))) return null;
  return { item, clip, media };
}
