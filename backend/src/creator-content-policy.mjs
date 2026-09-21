import {validPricing, publicPricing} from './clip-pricing.mjs';
export const freeCreatorPricing = Object.freeze({mode:'free',currency:'USD',amountMinor:0});
export function creatorContentCapabilities(profile) {
  const tier = ['standard','verified','partner'].includes(profile?.management?.tier) ? profile.management.tier : 'standard';
  const canUpload = profile?.status === 'approved';
  return {canUpload,canSetPaid:canUpload && tier === 'partner',tier};
}
export function creatorPricing(profile, pricing = freeCreatorPricing) {
  if (!validPricing(pricing)) throw new Error('INVALID_PRICING');
  if (pricing.mode === 'paid' && !creatorContentCapabilities(profile).canSetPaid) throw new Error('CREATOR_PAID_NOT_ALLOWED');
  return publicPricing(pricing);
}
export function assertCreatorContentPricing(store, item) {
  if (!item.ownerId) return;
  const profile = store.getCreatorProfile(item.ownerId);
  if (!creatorContentCapabilities(profile).canUpload) throw new Error('CREATOR_APPROVAL_REQUIRED');
  for (const clip of item.clips) creatorPricing(profile, clip.pricing);
}
