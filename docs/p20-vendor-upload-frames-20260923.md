# Manufacturer upload request fixtures, 2026-09-23

Four supplied literal frames verify the existing double-list layout: CMD 31, one-byte list (00 A, 01 B), uint32 big-endian file size, filename, CRC. All four frames match the production encoder byte-for-byte.

- A 001.mp3: 20529 bytes; aa0000000d3100000050313030312e6d70338ea5
- A 001.mp4: 6060176 bytes; aa0000000d3100005c78903030312e6d703472a5
- B 001.mp3: 20529 bytes; aa0000000d3101000050313030312e6d70338fa5
- B 001.mp4: 7628628 bytes; aa0000000d3101007467543030312e6d70343ea5

These explicit fixtures supersede the earlier inference that the double-list request omitted a list byte. The earlier 01NZ request alone does not establish double-list encoding. Do not change list routing to filename guessing.

Audio/video use the same baseName in P20MediaUploadFlow; B remains video-only per product requirement even though its protocol allows MP3. No runtime change or new APK is needed. Version 0.1.64+65 retains bounded RX diagnostics for the outstanding actual-device first-block failure. No claim of physical upload success.

Validation: 36 tests passed across p20_v2_protocol_test, p20_v2_connection_test and p20_media_upload_flow_test. This change adds fixtures and documentation only. No server deployment or data migration. Rollback: revert this test/document commit.
