# Connection / return navigation — 2026-09-30

0.1.75+76 (ARM64 debug / us_free)

Auto detection previously always tried the dual device first with its 15-second command timeout. The brightness identification probe now has a separate 3-second deadline; normal commands and uploads retain their existing timeouts. TCP connection timeout is still 5 seconds, so this is not a promise that every connection finishes within 3 seconds. Verified single-device connections are tried first on subsequent automatic connections to the same endpoint in the current app process. A failed cached choice falls back to the other protocol, always on a fresh socket, and still requires a valid brightness reply. Nothing assumes Wi-Fi connection alone proves device availability. The remembered hint is not persisted across app restarts.

From My Characters, the upload result page's Back to playlist button now opens the real device playlist for the chosen list, removing the intermediate framing/upload routes. Toolbar/system back retain their normal back behavior. Upload failures also offer the actual device playlist destination; they are not presented as successful uploads.

Customer support email is pending the user's confirmation (user explicitly deferred it). No invented mailbox/contact entry added. Once confirmed, wire up the support entry separately.

No backend changes or migration. Rollback: revert this change and rebuild with a higher version code; do not erase local downloads/device media. Hardware latency and iOS build remain unverified locally.

Validation: 167 relevant tests passed, including silent dual-probe fallback, remembered single reconnection and the return-button callback. dart analyze lib test: no issues.
