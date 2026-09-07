import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_upload_policy.dart';

void main() {
  test('splits uploads into 32768-byte packets and keeps final length', () {
    final bytes = Uint8List(P20UploadPolicy.chunkSize * 2 + 123);

    final chunks = P20UploadPolicy.chunks(bytes).toList();

    expect(chunks.map((chunk) => chunk.length), [32768, 32768, 123]);
  });

  test('does not create an empty packet for an exact multiple', () {
    final bytes = Uint8List(P20UploadPolicy.chunkSize * 2);

    final chunks = P20UploadPolicy.chunks(bytes).toList();

    expect(chunks.map((chunk) => chunk.length), [32768, 32768]);
  });

  test('treats storage-full status as terminal instead of retrying', () {
    expect(
      P20UploadPolicy.classifyStatus(0x85, retryableStatusCodes: {0x85}),
      P20UploadDisposition.storageFull,
    );
    expect(
      P20UploadPolicy.statusMessage(0x85),
      '设备存储空间不足，请清理内容后重试',
    );
  });

  test('only retries status codes explicitly supplied by the vendor', () {
    expect(
      P20UploadPolicy.classifyStatus(0x82),
      P20UploadDisposition.failed,
    );
    expect(
      P20UploadPolicy.classifyStatus(0x82, retryableStatusCodes: {0x82}),
      P20UploadDisposition.retry,
    );
  });
}
