# Device playlist usability — 0.1.61+62

- Dashboard attempts one shared P20 connection on startup/resume and every ten seconds while foregrounded and disconnected. Existing connected/connecting/reconnecting transports are not replaced. Connection requires a valid read-only brightness response before displaying connected.
- Device playlist includes an explicit permanent deletion action with confirmation, paired-audio warning, current-list isolation, and authoritative refresh after the command. Failed deletion does not optimistically remove files. Local pending uploads remain separate.
- Add video is pinned below the app bar; existing source selection and framing flows remain available.
- English and Chinese delete confirmation updated. Existing payment and localization features retained.

## Validation
Full suite: 549 passed, two skipped, one old tooltip locator failed after the button redesign. Updated that locator and reran its complete file: four passed. Static analysis: no issues. Simulated socket verifies handshake and no duplicate connection. Model/widget tests verify confirmed deletion, rejected deletion preservation and pinned add action.

## Device acceptance still required
Connect phone to hardware Wi-Fi and open/resume app. Confirm connected state and actual A/B contents. Delete a disposable device file, confirm refresh and paired audio behavior. Scroll a long list and confirm Add stays visible. No physical hardware test was available. Previous upload acknowledgement mismatch remains under manufacturer investigation.

## Delivery / rollback
ARM64 debug APK, build 62. No server deployment or data migration. Install over the prior matching debug-signature build; preserve phone data. Source rollback is a targeted revert of this commit; Android downgrade requires a separately numbered build rather than uninstalling user data.
