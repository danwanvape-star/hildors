# Single-list upload — 2026-09-29

Version: 0.1.72+73 (ARM64 debug test build, us_free profile).

User confirmed 32768-byte blocks, .mp4 device names and an unpadded final block. Single-list upload omits the list byte and skips audio extraction/upload. Video transcoding remains the existing 298x298/20fps vendor container; changing the device filename does not make it a standard MP4 container.

The upload header uses the additive checksum and matches the supplied manufacturer fixture `aa0000000d3101324f9c30314e5a2e6d7034a4a5` for 01NZ.mp4. Existing fixed-02 single-list query encoding is unchanged. Responses accept the previously verified fixed-02 or additive checksum.

Transfer waits for ready 00, sends one block, then waits for progress 01 before the next block. Progress SEQ is not used as a byte counter (manufacturer confirmed constant 2). Completion 02 is required after all bytes are sent; optional four bytes following 02 are ignored. Early completion, malformed responses, queued extra acknowledgements, timeout and disconnect fail closed. Other commands are blocked during upload. Communication logs omit media contents.

Validation: 156 device tests passed (p20 tests excluding external integration suites); dart analyze lib test reports no issues. Includes short final block, constant SEQ=2, raw manufacturer request fixture, coalesced completion, cancellation, error responses and enabled single-list upload UI. Dual-list tests included.

Hardware upload/playback is not yet verified. Test a short video on CS_P20_999999, confirm completion, refreshed device list and actual playback. Copy the communication log if it fails. No iOS build or device test performed here.

Rollback: revert the commit containing this change and rebuild with a higher Android version code. Existing package/data/backend behavior is unchanged; no migration is needed. Do not delete or overwrite device media to roll back.
