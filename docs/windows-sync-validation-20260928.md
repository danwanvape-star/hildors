# Windows sync validation — 2026-09-28

Fast-forwarded codex/unified-us-p20-20260921 from 98af6be to 4bf76f6 (11 commits). Existing untracked local files retained. flutter pub get succeeded without tracked dependency changes. Read docs/p20-single-device-validation.md before building.

Windows full Flutter test run: 601 passed, 2 skipped. These are fresh Windows results, not the prior Mac validation. Version incremented to 0.1.67+68 for Android testing.

Build profile: us_free, API https://api.hildors.com, ARM64 debug signature. HILDORS_SINGLE_UPLOAD_VALIDATION is not enabled: single-list normal uploads remain blocked pending hardware/file/tail validation. Dual-list upload and raw log workflow retained. No production deploy, store submission or hardware success claim.

Device checks: verify auto-detection and correct UI on each model; regress A/B upload on double-list hardware; do not claim single-list video playback based on widget or socket tests. Mac/iOS was not rebuilt on this Windows host. Rollback by reverting the version/documentation commit or building the previous source with a higher Android version code; no data migration.
