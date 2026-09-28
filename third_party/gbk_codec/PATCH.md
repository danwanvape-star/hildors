# gbk_codec 0.4.0 compatibility patch

Copied from the locked pub.dev gbk_codec 0.4.0 package, with its license. Only the two large map literals in lib/src/gbk_maps.dart are made const. The mapping entries, encode/decode algorithms and public API are unchanged. Unused package examples and map-generation tooling are omitted.

On this Mac, lazy runtime initialization of these large maps intermittently raised a Map._fromLiteral type error or crashed flutter_tester under Flutter 3.47.4 / Dart 3.13.3. Precompiling the exact maps avoids that initialization path. Synchronous prewarming and disabling widget-creation tracking did not reliably fix it. This is a local compatibility mitigation, not a claim about a diagnosed upstream VM defect.

Original gbk_maps.dart SHA256: b6679bcec0796ccd41c8b58803c76418f8c1629bb9d02e44d71f06cbd7b4a77e

The source-byte comparison verified that removing only the two inserted ` const` tokens reproduces the original file byte-for-byte. Existing GBK filename and manufacturer wire fixtures remain required. Remove this override only after the unpatched package passes those tests on the target toolchain.
