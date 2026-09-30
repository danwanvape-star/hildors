# Five-language release and experience check — 2026-09-30

Version: 0.1.77+78, arm64 debug, us_free, production API URL.

## Changes
- Added German (Deutsch), Spanish (Español), Japanese (日本語) alongside English and Simplified Chinese.
- Each locale supplies all 726 Flutter messages. Added 167 German/Spanish custom-character messages; Japanese already has all 167 and selected wording was refined.
- System language resolves regional variants to their supported base language; unsupported primary languages use English. Existing saved choices remain compatible. Manual choices persist across restart.
- Added Android resource folders and iOS display-name/local-network permission translations and project references.
- Backend catalog currently supports English/Chinese: new languages use the existing English content request and original-text fallback. Published titles/stories were not rewritten.
- Resource merge now supports five languages; restored three pre-existing device-log messages to source fragments so regeneration cannot drop them.

## Verification
- Full Flutter suite: 633 passed, 2 existing conditional tests skipped. Includes device protocol, upload, downloads, navigation, framing and pricing regression coverage.
- Static analysis of lib and test: no issues.
- New language tests cover regional resolution, persistence, actual dropdown selection, system-language changes, complete catalog keys and placeholders.
- Five-language core pages checked at 2× text scale. New-language playlist/upload/custom entry checked at 1.5× on a 390×844 viewport.
- Rendered and visually inspected German/Japanese playlists and Spanish support; six reproducible screenshots in build/locale-review. Japanese capture uses a local system font for the test renderer only, not bundled into the APK.
- Updated two stale selection tests to the already implemented direct-upload UX; offline file identity and disconnected-device behavior remain checked.
- APK identity: com.hildors.hildors_cockpit, versionName 0.1.77, versionCode 78, arm64-v8a. Signature matches previous test APK.

## Same-spec APK comparison
- 0.1.76+77: 159,562,448 bytes.
- 0.1.77+78: 159,759,464 bytes.
- Increase: 197,016 bytes (about 192.4 KiB / 0.1235%).
- SHA-256: B37C903F6E14B23A8655233144CE58C493BBAA978CBF20C787AB2BACFF6C99D8.

## Remaining device checks
This run used automated widgets and simulated hardware, not an attached phone/P20. Confirm real-device Wi-Fi reconnect, a short upload, and OS mail-client launching on the installed APK. iOS localized resources are added, but an iOS build was not performed on Windows. The no-API development catalog still contains Chinese demo content/UI; the delivered APK uses the production API catalog.
