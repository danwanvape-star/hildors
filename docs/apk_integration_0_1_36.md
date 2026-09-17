# App integration 0.1.36 (37)

This release integrates the existing content-management App work with the missing framing fixes from `6cc9376`. The 0.1.35 APK version alone did not establish inclusion of that commit.

## Included behavior

- Per-item official/named/anonymous attribution, character image and introduction, two-column video cards, and creator works navigation.
- Preserve the content-management work: expandable stories, creator submissions and pagination, customization orders and session renewal.
- Pending playlist rows expose circular framing. HTTP(S) sources are not checked as local files. Adding a cloud clip or a single selected role clip opens framing after saving the pending reference.
- Device filename-only entries request the original source video. Framing settings persist by source and asset identity; startup and Bluetooth pending lists remain distinct.
- Preview playback pauses when covered by another route or sheet, including initialization that completes while covered.

Framing is not manufacturer transcoding, device upload, or proof of hardware playback. No server deployment is performed by this integration. Existing backend work in this workspace is preserved.

## Verification

The pre-fix regression run reproduced five failures covering missing framing entry/navigation and obscured playback. After integration, the English-path D-drive snapshot passes static analysis with no issues and all 345 Flutter tests with `HILDORS_APP_E2E=1` (no skips). The real backend download fixture needed its required description field added to match the content-management API; production validation was not weakened.

The snapshot is `D:/HildorsBuilds/content-admin-0.1.36-37`. App source and test hashes were compared to this workspace. Build uses `https://api.hildors.com` and the existing internal-test debug signing configuration. Android phone and P20 validation remain outstanding.

Build result and APK hash are recorded in the ignored release manifest next to the APK. Release binaries, local build snapshots, credentials, databases, and user media are not included in Git.
