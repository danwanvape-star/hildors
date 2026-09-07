import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/protocol/p20_protocol.dart';

void main() {
  test('encodes 16-bit angle in big-endian order', () {
    expect(P20Protocol.uint16BigEndian(0x1234), [0x12, 0x34]);
  });

  test('rejects angle outside unsigned 16-bit range', () {
    expect(() => P20Protocol.uint16BigEndian(-1), throwsRangeError);
    expect(() => P20Protocol.uint16BigEndian(0x10000), throwsRangeError);
  });

  test('skips noise and malformed response before valid frame', () {
    final decoder = P20FrameDecoder();
    final frames = decoder.add([
      0x10,
      0x20,
      0x55,
      0,
      0,
      0,
      2,
      0x04,
      99,
      0x00,
      0x5A,
      0x55,
      0,
      0,
      0,
      2,
      0x04,
      60,
      0x02,
      0x5A,
    ]);
    expect(frames, hasLength(1));
    expect(frames.single.data, [60]);
  });
}
