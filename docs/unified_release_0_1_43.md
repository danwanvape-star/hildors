# Unified release 0.1.43 (44)

This release combines the creator certification/management work and video-performance commit `e2324a1`, including all previously released content pricing, image preview, download and framing changes. It supersedes both separate 0.1.42 (43) APKs.

## Included

- Creator video application drafts, private work uploads, submit/reject/resubmit workflow, existing creator workbench routing.
- Admin creator management, role/direction tags, five ability levels, independent submission/order permissions.
- Compressed catalog/order images and explicit original viewing.
- Lightweight cloud video previews, upload-time pre-generation, Range/ETag support, bounded session cache, buffering/retry/cancellation feedback and concurrent catalog/layout requests.
- Per-video free/USD pricing, downloads to My Characters, creator attribution and playlist framing behavior remain intact. Payment processing and final hardware transcoding are not implemented by this merge.

## Integration

The current creator-workspace changes were snapshotted before merging. Overlapping playback files were compared: the released performance version includes all prior buffering work plus cache and fallback logic, so it was retained. Original untracked deployment helpers and design notes were not discarded.

Both source lines were combined in an isolated worktree, then returned to the current development branch after validation. Use the unified source and version 44 for subsequent releases; do not build a new APK from either old 0.1.42 snapshot.

## Verification

- Combined backend: 103 tests passed with media integration enabled; zero skips.
- App: static analysis clean and 403 tests passed with download end-to-end tests enabled.
- Frozen build source: `D:/HildorsBuilds/hildors-unified-0.1.43-44`.
- All 27 deployed backend source/static files were compared with the unified source. Content matched after line-ending/trailing-newline normalization. The combined features are already live; no redundant server overwrite/restart is needed.
- No database, credentials, private keys or user media are included in Git. No phone was connected for physical-device acceptance.

Network route variability remains: compressed previews reduce traffic but do not replace future regional CDN delivery. See `video_performance_delivery.md` for measurements and cache limits.
