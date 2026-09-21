# Unified backend integration — 2026-09-21

This source combines the current content/admin/operator/creator/order implementation with the US bilingual catalog, custom plans and account-deletion request workflow. It retains `operators.mjs` as the single operator authority; the older US operator-auth/policy/store implementation is not included.

- Custom plans default to 10/15/30/60 seconds at USD 19.99/29.99/69.99/159.99. Optional matched audio adds 20%, rounded in integer cents. Fresh database plans are unlisted until configured by an authorized operator.
- Order plan and paid snapshots remain immutable. Private deliverables require the customer identity, a verified entitlement and completed workflow. Production progress retains the current operator identity.
- Store payments remain disabled by default. No native Apple/Google purchasing integration or live verification provider is supplied by this merge. Editing product IDs or listing a plan does not activate payments.
- Catalog localization is additive and falls back to original text; missing English fields are exposed explicitly. Operators can supply package, clip and tag translations in the current console.
- Standalone plan/order/deletion pages use the current `/admin/me` identity and granular permissions. Current content lifecycle, audited operator mutations, creator permissions, media revocation checks, email identity and legacy order flows remain in place.
- Account deletion is a request/review workflow, not an automatic erasure job.

Validation: Node v24.19.0 with FFmpeg/FFprobe from `D:/HildorsTools/Activate-Hildors.ps1`, `HILDORS_MEDIA_INTEGRATION=1`, `node --test backend/test/*.test.mjs`: **225 passed, 0 failed, 0 skipped**. Includes real demo decoding, synthetic custom video/audio delivery lifecycle, current operator permission/revocation tests, and unified HTTP permission/snapshot regression.

Read-only remote checks on 2026-09-21: `https://api.hildors.com/v1/customization-plans` returned HTTP 200 with the expected four prices and 20% audio markup, `paymentMode: disabled`, and `purchaseEnabled: false`. `/v1/catalog?limit=1&lang=en` returned HTTP 200 with the additive localization contract; the sampled record lacked English translations and therefore returned original Chinese text as documented. No authenticated remote write, deployment or database migration was performed. These public checks do not establish that the remote server runs every change in this unified source.
