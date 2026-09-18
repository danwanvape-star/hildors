# Playback performance — 0.1.42+43

## Scope

Cloud catalog video previews now use an independent mobile-sized stream. The shared content player adds loading, buffering, timeout, retry, cancellation and bounded preview caching. Catalog content and layout requests run concurrently. Existing compressed cover/order image routes remain in use. Local downloaded videos and hardware framing retain their original sources; preview files never replace downloads or hardware input.

The implementation is isolated on `codex/video-performance` from release `567ba70`. Existing playback-feedback changes were carried into this branch. Concurrent creator application work in the original workspace was preserved and is not included in this APK.

## Video delivery

- `/v1/media/:id/preview?v=1`: H.264/yuv420p, maximum edge 480, even dimensions, 24 fps, CRF 28, maximum video bitrate 600 kbps, AAC 64 kbps, faststart metadata. Original audio/visual aspect retained; originals unchanged.
- A single bounded conversion worker deduplicates requests, caps queued tasks and enforces source/duration/dimension/output limits. Uploaded content is pre-generated after successful inspection; generation errors preserve the original QC result and can retry on demand.
- Existing published/free-or-legacy public-preview rules and paid-media alias restrictions are retained. Permissions are rechecked before streaming and before conditional 304 responses.
- Range requests support progressive playback. Cache reuse requires revalidation with the current server rather than replaying withdrawn content offline.

## App cache and feedback

- First playback streams immediately on a cache miss. Only after the first completed pass is an optional cache transfer attempted; one transfer at a time, cancelled on leaving/changing the video.
- Cache is limited to 64 MB total / 12 MB per item, 24-hour TTL and LRU eviction. Only versioned preview URLs on the configured API origin qualify. Originals, private uploads and other hosts are excluded.
- Cache metadata is session-local; dedicated temporary cache files are cleared on first cache write after restarting the process. Reopening within a session validates online and reuses a complete file only on 304. Invalid/expired/truncated entries are removed. Native cached-file decoding failure falls back to streaming.
- Slow-loading feedback appears after 10 seconds and initialization times out after 30 seconds. Retry, source changes and navigation release old players and cancel obsolete work.

## Deployment and measurement

Deployed three backend files after a three-way merge preserving newer creator application routes. Exact live hashes were checked before replacement. Code rollback snapshot: `/opt/hildors/code-backups/video-performance-20260918T014958Z`.

All five currently public uploaded clips were pre-generated as the service user:

| Video | Original bytes | Preview bytes |
| --- | ---: | ---: |
| Ahri | 11,500,841 | 859,936 |
| Squidward | 1,214,818 | 313,288 |
| Nova 1 | 11,333,653 | 616,663 |
| Nova 2 | 3,200,291 | 249,732 |
| Niya | 14,993,060 | 3,390,579 |

From this computer, Nova's first 64 KB took 1.224 seconds (first byte 0.994s). A separate full-preview request received 458,423/616,663 bytes before a 25-second timeout. This proves the public network route still fluctuates: reduced size does not guarantee immediate or uninterrupted playback on every connection. CDN/service relocation was not provisioned. No physical phone was connected for acceptance testing.

## Validation

- Backend: 86/86 tests passed with media integration enabled, including real transcoding, faststart, range, ETag, aliases, revocation, original preservation and pre-generation on automatic/manual inspection.
- Deployed backend modules: 4/4 isolated conversion/access tests passed; service readiness passed.
- App: static analysis clean; 393/393 tests passed. Logs and sources are recorded in the English build snapshot `D:/HildorsBuilds/video-performance-0.1.42-43`.
