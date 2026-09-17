# Owned content downloads

User decision: only server-confirmed claimed/purchased content may be downloaded. Successful downloads enter My Characters, grouped by package. Individual and whole-package download, progress/cancel/retry, persistent local metadata, offline use and local deletion are included. No payment simulation or local favorites granting cloud entitlement. User subsequently explicitly authorized enabling entitlement-gated downloads and a brief service restart.

Implementation:
1. Reuse the authenticated manifest/download primitive. Bind cache to API origin and stable account ID; renew the existing session without replacing an account. Resolve identity online for new downloads and retain account binding for offline reads.
2. Add a verified-download library storing package metadata and local video references, with local covers/thumbnails where available. Integrate with My Characters and both playlist paths; preserve asset versus file identity.
3. Add single/all download actions to cloud package details. Gate each download on server authorization, cancel work on route disposal, publish library entries only after verified download. Replace the cloud-preview-to-playlist shortcut with downloaded-file actions.
4. Test unowned denial, successful persistent download, cancellation/failure, account isolation, partial package merge, local playback/playlist and deletion. Run full tests/analyze; build in a D-drive English-path snapshot; commit code without existing unrelated backend edits or media/credentials.

Ruling: existing claim/payment entry points are not complete. This feature consumes authoritative entitlements; it does not invent purchase or grant free access. Backend enablement was performed only after explicit user approval.

## 0.1.37 (38) verification

- English-path snapshot: `D:/HildorsBuilds/content-admin-0.1.37-38`.
- Static analysis: no issues. Full Flutter run with `HILDORS_APP_E2E=1`: 363 passed, zero skips/failures.
- Includes actual isolated-backend publication, identity renewal, entitlement-gated download, persisted My Characters metadata, and withdrawal blocking a new transfer.
- Unit/widget cases cover unowned rejection, partial packages, retry without redownloading verified bytes, account changes, offline binding, corruption, local file playlist identity, cancellation and deletion confirmation. The orphan-cache/index regression was observed failing before the fix.
- Existing details, story, creator-space and playback tests remain passing. Independent read-only review found no remaining blocker after the cache/index fix.
- The shared E2E fixture was adapted to the concurrently updated backend requirement for a content tag. Production backend validation was not changed by this task.
- The public bootstrap endpoint initially returned HTTP 502, then recovered with downloads disabled. After explicit user approval, added strict `HILDORS_ENABLE_DOWNLOADS=0|1` configuration (default disabled) and connected it to server startup. Five runtime/delivery tests passed, including an authenticated but unowned download denial.
- Deployed only the startup option and runtime configuration to the live code, preserving concurrent backend work; hash-checked existing files before writing. Backup: `/opt/hildors/code-backups/owned-downloads-20260917T102025Z`. Enabled the flag and restarted `hildors-team-staging.service`; readiness passed and unauthenticated download returned 401. No database, user media or entitlement changes. Real-device acceptance is outstanding.
- App uses existing internal-test signing. Offline files live in App-private storage scoped to API origin and stable account ID. Deleting a role removes its managed video files and metadata; small shared cached artwork is retained.
- Downloading to the phone does not implement manufacturer conversion or device upload. Private custom-order original files are not exposed by this feature.
- APK: `hildors-content-admin-0.1.37-38.apk`, SHA-256 `ae78f064136989f0daf57cd6ef2ba16361f5a0136d7cb3596880b53109c50e6f`. Version/signature checks passed; same signer as 0.1.36. Concurrent uncommitted preview-buffering changes were left untouched and are not in this frozen release.
