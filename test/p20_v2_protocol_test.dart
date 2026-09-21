import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_v2_protocol.dart';

void main() {
  test('length bytes and checksum overflow use the full big endian body', () {
    final request = P20V2Protocol.request(0xff, List.filled(256, 0xff));
    expect(request.sublist(0, 6), [0xaa, 0, 0, 1, 1, 0xff]);
    expect(request.length, 264);
    // 1 + 1 + 255 + 256 * 255 = 65537, whose low byte is 1.
    expect(request.sublist(request.length - 2), [1, 0xa5]);
    final frames = P20V2Decoder().add([
      0x55,
      0,
      0,
      1,
      1,
      0xff,
      ...List.filled(256, 0xff),
      1,
      0x5a,
    ]);
    expect(frames.single.command, 0xff);
    expect(frames.single.data, List.filled(256, 0xff));
  });
  for (final corruptTail in [false, true]) {
    test('discards whole frame with bad ${corruptTail ? "tail" : "checksum"}',
        () {
      // A valid completion-looking sequence inside damaged metadata is data,
      // never a standalone response. All checksum values are independent.
      final corrupt = [
        0x55,
        0,
        0,
        0,
        10,
        0xe8,
        0x55,
        0,
        0,
        0,
        2,
        0x31,
        2,
        0x35,
        0x5a,
        corruptTail ? 0x0b : 0x0a,
        corruptTail ? 0 : 0x5a,
      ];
      const valid = [0x55, 0, 0, 0, 2, 4, 50, 0x38, 0x5a];
      for (final split in [0, 8, corrupt.length - 1]) {
        final decoder = P20V2Decoder();
        expect(decoder.add(corrupt.sublist(0, split)), isEmpty);
        final frames = decoder.add([...corrupt.sublist(split), ...valid]);
        expect(frames.map((frame) => frame.command), [4]);
        expect(frames.single.data, [50]);
      }
    });
  }
  test('rejects corrupted header and impossible lengths then recovers', () {
    const valid = [0x55, 0, 0, 0, 2, 4, 50, 0x38, 0x5a];
    for (final invalid in [
      [0x54, ...valid.sublist(1)],
      [0x55, 0, 0, 0, 0, 4, 4, 0x5a],
      [0x55, 0, 0, 0x10, 1, 4, 0x15, 0x5a],
    ]) {
      final frames = P20V2Decoder().add([...invalid, ...valid]);
      expect(frames.map((frame) => frame.command), [4]);
      expect(frames.single.data, [50]);
    }
  });
  test('vendor checksum example', () {
    expect(
        P20V2Protocol.request(4, [50]), [0xaa, 0, 0, 0, 2, 4, 50, 0x38, 0xa5]);
    expect(P20V2Protocol.request(0x0f), [0xaa, 0, 0, 0, 1, 0x0f, 0x10, 0xa5]);
  });
  test('fragmented, sticky and corrupt replies', () {
    final decoder = P20V2Decoder();
    expect(decoder.add([0x55, 0, 0]), isEmpty);
    final frames = decoder.add([
      0,
      2,
      4,
      50,
      0x38,
      0x5a,
      0x55,
      0,
      0,
      0,
      2,
      4,
      50,
      0x02,
      0x5a,
      0x55,
      0,
      0,
      0,
      2,
      4,
      50,
      0x38,
      0x5a,
    ]);
    expect(frames, hasLength(2));
    expect(frames.first.data, [50]);
  });
  test('upload header uses list, big endian size, GBK bytes', () {
    // CP936 bytes for 哪吒.mp4, supplied independently of the codec.
    final name = [0xc4, 0xc4, 0xdf, 0xb8, 46, 109, 112, 52];
    expect(P20V2Protocol.uploadHeader(1, 0x01020304, name),
        [1, 1, 2, 3, 4, ...name]);
    expect(() => P20V2Protocol.uploadHeader(2, 1, name), throwsArgumentError);
    expect(() => P20V2Protocol.uploadHeader(0, 0, name), throwsArgumentError);
    expect(() => P20V2Protocol.uploadHeader(0, 1, List.filled(62, 65)),
        throwsArgumentError);
  });
  test('invalid byte values are rejected instead of truncated', () {
    expect(() => P20V2Protocol.request(256), throwsArgumentError);
    expect(() => P20V2Protocol.request(1, [-1]), throwsArgumentError);
  });
  test('rejects paths, reserved prefixes and malformed GBK names', () {
    for (final name in [
      '../x.mp4'.codeUnits,
      'a_x.mp4'.codeUnits,
      'b_x.mp3'.codeUnits,
      'x.bin'.codeUnits,
      'x\\y.mp4'.codeUnits,
      [0x81, 0x20, 46, 109, 112, 52],
    ]) {
      expect(() => P20V2Protocol.uploadHeader(0, 1, name), throwsArgumentError);
    }
    // 0x5c can be a GBK trail byte, not an ASCII path separator.
    expect(P20V2Protocol.uploadHeader(0, 1, [0x81, 0x5c, 46, 109, 112, 52]),
        hasLength(11));
  });
}
