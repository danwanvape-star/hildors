import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/protocol/p20_protocol.dart';

void main() {
  test('encodes power-on request', () {
    expect(
      P20Protocol.encode(P20Command.power, [0x01]),
      [0xAA, 0, 0, 0, 2, 0x01, 0x01, 0x02, 0xA5],
    );
  });

  test('supports P11 legacy CRC when explicitly requested', () {
    expect(
      P20Protocol.encode(
        P20Command.queryBluetoothSpeakerName,
        const [0x00],
        P20Protocol.legacyCrc,
      ),
      [0xAA, 0, 0, 0, 2, 0x73, 0x00, 0x20, 0xA5],
    );
  });
  test('decodes fragmented response', () {
    final decoder = P20FrameDecoder();
    expect(decoder.add([0x55, 0, 0]), isEmpty);
    final frames = decoder.add([0, 2, 0x04, 60, 0x20, 0x5A]);
    expect(frames, hasLength(1));
    expect(frames.single.command, 0x04);
    expect(frames.single.data, [60]);
  });

  test('decodes sticky responses', () {
    final decoder = P20FrameDecoder();
    final frames = decoder.add([
      0x55,
      0,
      0,
      0,
      2,
      0x04,
      50,
      0x20,
      0x5A,
      0x55,
      0,
      0,
      0,
      2,
      0x08,
      2,
      0x20,
      0x5A,
    ]);
    expect(frames.map((frame) => frame.command), [0x04, 0x08]);
  });
}
