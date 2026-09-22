# P20 upload: manufacturer clarification, 2026-09-22

The manufacturer clarified that the sender must send filename/size, wait for readiness, send one block, wait for that block's receipt acknowledgement, then send the next block. The final block contains only the remaining bytes. No unrelated commands may be sent during upload.

The previous implementation concurrently streamed the entire file and read progress. A delayed-ACK socket test reproduced premature sending. Upload now performs stop-and-wait inside the existing exclusive command queue. Existing 32768-byte block size, framing, CRC and sequence encoding remain unchanged; the clarification did not specify new values for these fields. No blind retries or fabricated progress were introduced. Completion still requires the device's final completion status, including after all bytes have been acknowledged.

Targeted transport tests: 14 passed, including delayed ACK, tail sizes, exact block boundaries, timeout, cancellation, rejection and queued commands. Physical device acceptance remains outstanding; this addresses the confirmed sender-flow mismatch, not a claim that all firmware differences are resolved.

Delivery: 0.1.62+63 ARM64 debug APK; no backend deployment or data migration. Prior UI improvements remain included. Rollback by reverting this change and building with a higher Android version code to preserve installed user data. Source-only changes; no supplied user video is committed.

Full regression: 550 passed, 2 skipped. Flutter static analysis: no issues.
