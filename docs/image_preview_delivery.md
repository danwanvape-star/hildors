# Image preview delivery — 0.1.41+42

Content lists and custom-order galleries request 384px JPEG thumbnails. Cover details and authenticated App order material dialogs request 1024px JPEG previews. Originals remain unchanged and order viewers can explicitly request them. Dimensions preserve aspect ratio and never upscale.

## Routes and clients

- Public published covers: `/v1/covers/:id/thumbnail` and `/v1/covers/:id/preview`; catalog exposes `coverThumbnailPath` and `coverPreviewPath` alongside the original `coverPath`.
- Admin covers: `/admin/covers/:id?variant=thumbnail|preview`.
- Order materials: existing admin/customer/assigned-creator material routes with `?variant=thumbnail|preview`. Requests without a variant retain original-file behavior.
- Private variants recheck session, current permissions, and material existence after conversion/read, and respond with `Cache-Control: no-store`. No public order-material endpoint is introduced.
- App material dialogs open immediately with a loading indicator, retry on failure, and offer an explicit original-image action. They use the existing authenticated request and renewal mechanism.
- Admin order galleries load small images lazily; clicking opens a compressed preview, with a separate original link.

Derivatives are generated on demand in the media directory, deduplicated, and reused. Conversion concurrency is limited to two, with bounded input dimensions, timeouts and output size. No original media or databases are committed to Git.

## Verification and deployment

- App: static analysis clean; 375 tests passed in `D:/HildorsBuilds/content-admin-0.1.41-42`, including authenticated preview selection, retry/original actions, close-during-fetch, narrow screen and enlarged text.
- Backend: 82 tests passed, no skipped tests, including real ffmpeg conversion, dimensions, original-byte preservation, private authorization and session revocation.
- Server: five code files updated with exact pre-deployment hash checks; three isolated conversion/access tests passed against deployed modules. Readiness succeeded.
- Code rollback snapshot: `/opt/hildors/code-backups/image-previews-20260917T162956Z`.
- Nova cover measured from this computer after deployment: original previously 1,257,889 bytes; thumbnail 23,069 bytes / 0.997 seconds; preview 111,705 bytes / 1.712 seconds. Timing varies with network conditions.
- Existing content/order admin source was first preserved as a separate baseline commit (`a512fff`) after 79 baseline tests passed. Unrelated ongoing App video buffering edits remain outside this release.
- Android physical-device verification remains pending; no phone was connected.
