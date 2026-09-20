import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_v2_protocol.dart';

void main() {
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
