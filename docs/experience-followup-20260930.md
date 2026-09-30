# Experience follow-up — 2026-09-30

Target: 0.1.78+79, five-language arm64 test APK.

## Reproduced and fixed
1. Manual Disconnect was undone by the Dashboard 10-second discovery timer. Dashboard now respects explicit disconnect. Explicit Connect resumes discovery; transport-loss reconnection remains supported. Canceling an upload also pauses automatic connection until Connect is selected.
2. Unknown/offline single P20 was presented as a Bluetooth model. Home now distinguishes single, dual, and unknown. Music/Bluetooth appears only for verified or explicitly selected P20 PORTAL. Connectivity remains independently reported.
3. Settings had a legacy P11 label. It now identifies P20 / P20 PORTAL, or the verified model.
4. Playlist -> framing -> failed upload -> Back to playlist returned to framing. Explicit return now closes upload and framing, keeps the pending item on failure, and preserves the successful filename for pending-item cleanup. Normal back retains its existing behavior.
5. Framing upload became clickable while awaiting player pause. A synchronous submission guard now covers save, pause and the upload route, releasing on return/error. A delayed-pause test reproduced two submissions before the fix and one afterward.

## Verification
- Full suite: 646 passed, 2 existing conditional tests skipped.
- Focused tests reproduce failed-upload return, pending retention, delayed-pause double submission, explicit disconnect, reconnect over a local TCP loopback server, model-specific home UI, and corrected model labels.
- Small-screen checks: 320x640, 2x text, all five locales; long-name selection, upload entry, playlist and support.
- No manufacturer protocol/transcoding changes. No attached physical phone or P20 was used. The local TCP test verifies software recovery, not Wi-Fi association or actual hardware upload.

## Suggested phone smoke check
Install over the previous APK. Verify P20 and PORTAL show their own entries; manually disconnect and wait 15 seconds; explicitly reconnect. Try a short upload, then cancel another and use Back to playlist. Confirm pending content remains after failure/cancel and successful content appears after refresh.

APK verified: versionName 0.1.78 / versionCode 79, arm64-v8a, previous debug signer retained. Size 159,760,360 bytes. SHA-256 877A22D357EDE595EADB4068AC9DDB8F74ADDDF9713A6C34FE9C506762ACF9A8. Final upload-result callback tests: 5 passed; static analysis clean.
