export function validPricing(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
    && value.currency === 'USD' && Number.isSafeInteger(value.amountMinor)
    && (value.mode === 'free' ? value.amountMinor === 0
      : value.mode === 'paid' && value.amountMinor >= 1 && value.amountMinor <= 99999999);
}

export function publicPricing(value) {
  return validPricing(value) ? { mode: value.mode, currency: 'USD', amountMinor: value.amountMinor } : undefined;
}

// Only an absent field is legacy. Invalid configured prices fail closed.
export function publicFullPreview(clip) {
  return clip.pricing === undefined || (validPricing(clip.pricing) && clip.pricing.mode === 'free');
}
