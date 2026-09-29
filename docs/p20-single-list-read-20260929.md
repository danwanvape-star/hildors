# Single-list follow-up, build 0.1.70+71

User confirms connection now succeeds, but list reads fail. Upload screenshot shows the intentional single-upload validation gate; no transfer has been attempted. Existing single implementation uses 35700-byte blocks and .bin, while prior dual manufacturer guidance is 32768-byte/.mp4. Asked user to confirm the single-device rule; do not silently transplant dual upload semantics.

Added raw TX/RX logging only during single-list read commands 0x36 and 0x08, before decoding. No Wi-Fi-setting or arbitrary command logging. Playlist page offers copy-log action, uses read-failed instead of generic network error for list parsing failures, and removes A/B wording for a connected single device. Does not change list parser or remove upload gate without evidence.

Validation: 43 focused tests passed, including failed-before/fixed-after coverage for rejected raw list reply logging. Static analysis passed. Physical list contents and upload remain unverified. User should refresh device list once then copy logs from that page; no upload needed.
