import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_device_profile.dart';

void main() {
  test('single profile restricts the device to one silent list', () {
    final p = P20DeviceProfile.forKind(P20DeviceKind.single);
    expect(p.supportsList(0), isTrue);
    for (final id in [-1, 1, 255]) {
      expect(p.supportsList(id), isFalse);
    }
    expect(p.supportsAudio, isFalse);
    expect(
        [p.videoExtension, p.maxNameBytes, p.chunkSize], ['.bin', 32, 35700]);
  });
  test('dual permits both lists and retains existing media rules', () {
    final p = P20DeviceProfile.forKind(P20DeviceKind.dual);
    expect(p.supportsList(0) && p.supportsList(1), isTrue);
    expect(p.supportsList(2), isFalse);
    expect(p.supportsAudio, isTrue);
    expect(
        [p.videoExtension, p.maxNameBytes, p.chunkSize], ['.mp4', 61, 32768]);
  });
  test('unknown cannot address a device list', () {
    final p = P20DeviceProfile.forKind(P20DeviceKind.unknown);
    expect(p.supportsList(0), isFalse);
    expect(p.supportsAudio, isFalse);
  });
}
