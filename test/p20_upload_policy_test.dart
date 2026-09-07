import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_upload_policy.dart';

void main() {
  test('encodes file size as four big-endian bytes before filename', () {
    final data = P20UploadPolicy.encodeRequestData(
      fileSize: 0x01020304,
      fileName: 'demo.bin',
    );
    expect(data.sublist(0, 4), [0x01, 0x02, 0x03, 0x04]);
    expect(String.fromCharCodes(data.sublist(4)), 'demo.bin');
  });

  test('validates filename by UTF-8 byte count', () {
    expect(
      () => P20UploadPolicy.encodeRequestData(
        fileSize: 1,
        fileName: '${'角' * 11}.bin',
      ),
      throwsArgumentError,
    );
  });

  test('splits P20 uploads into 32768-byte packets', () {
    final bytes = Uint8List(P20UploadPolicy.p20ChunkSize * 2 + 123);
    final chunks = P20UploadPolicy.chunks(bytes).toList();
    expect(chunks.map((chunk) => chunk.length), [32768, 32768, 123]);
  });

  test('supports the documented P11 legacy packet size separately', () {
    final bytes = Uint8List(P20UploadPolicy.p11LegacyChunkSize + 9);
    final chunks = P20UploadPolicy.chunks(
      bytes,
      device: P20UploadDevice.p11,
    ).toList();
    expect(chunks.map((chunk) => chunk.length), [35700, 9]);
  });

  test('decodes acknowledged packet sequence as big-endian', () {
    expect(
      P20UploadPolicy.decodeAcknowledgedSequence(
        [0x01, 0x01, 0x02, 0x03, 0x04],
      ),
      0x01020304,
    );
  });

  test('maps every documented completion and error status', () {
    expect(P20UploadPolicy.classifyStatus(0x00), P20UploadDisposition.ready);
    expect(
      P20UploadPolicy.classifyStatus(0x01),
      P20UploadDisposition.chunkAccepted,
    );
    expect(
      P20UploadPolicy.classifyStatus(0x02),
      P20UploadDisposition.complete,
    );
    expect(
      P20UploadPolicy.classifyStatus(0x80),
      P20UploadDisposition.restartUpload,
    );
    expect(
      P20UploadPolicy.classifyStatus(0x81),
      P20UploadDisposition.writeFailed,
    );
    expect(
      P20UploadPolicy.classifyStatus(0x82),
      P20UploadDisposition.duplicateFile,
    );
    expect(
      P20UploadPolicy.classifyStatus(0x83),
      P20UploadDisposition.invalidLength,
    );
    expect(
      P20UploadPolicy.classifyStatus(0x84),
      P20UploadDisposition.videoLimitReached,
    );
    expect(
      P20UploadPolicy.classifyStatus(0x85),
      P20UploadDisposition.storageFull,
    );
    expect(
      P20UploadPolicy.classifyStatus(0x86),
      P20UploadDisposition.cancelled,
    );
  });
}
