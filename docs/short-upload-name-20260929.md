# P20 upload filename limit — 2026-09-29

Manufacturer/user confirmed upload filenames must fit 12 bytes. Build 0.1.74+75 replaces timestamp-based names with eight secure-random ASCII hexadecimal characters, e.g. 7a3f91c2.mp4. Paired audio uses the identical basename plus .mp3; both are exactly 12 bytes including extension.

The media flow and shared upload client enforce the upload-only limit for P20 and P20 PORTAL. Single-list transport also rejects oversized names before sending. Existing device filename read/control limits stay unchanged, so previously stored long/GBK names remain readable. Duplicate-file responses still abort; no overwrite or blind retry.

Validation: 161 device tests passed, including generated MP3/MP4 names, 13-byte rejection, manufacturer raw frame fixtures, stop-and-wait, completion, single/dual and raw 0x87 replay. Static analysis clean. Android ARM64 debug test package retains US profile and API URL. Device acceptance and playback still require physical testing. No iOS build/test.

Rollback: revert this change and rebuild with a higher version code. No migration or backend deployment; local original videos and device media are not renamed/deleted.
