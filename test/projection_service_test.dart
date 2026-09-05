import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/experience/projection_service.dart';

void main() {
  test('device video matching ignores case and surrounding spaces', () {
    expect(
      hasDeviceVideo(['  TAROT_00_UPRIGHT.MP4  '], 'tarot_00_upright.mp4'),
      isTrue,
    );
  });

  test('device video matching requires the complete file name', () {
    expect(
      hasDeviceVideo(['tarot_00_upright_preview.mp4'], 'tarot_00_upright.mp4'),
      isFalse,
    );
  });
  test('pack status reports available count and progress', () {
    const status = ExperiencePackStatus(
      deviceConnected: true,
      totalFiles: 30,
      missingFiles: ['a.mp4', 'b.mp4'],
    );
    expect(status.availableFiles, 28);
    expect(status.progress, closeTo(28 / 30, 0.0001));
    expect(status.installed, isFalse);
  });

  test('complete connected pack is installed', () {
    const status = ExperiencePackStatus(
      deviceConnected: true,
      totalFiles: 30,
      missingFiles: [],
    );
    expect(status.installed, isTrue);
    expect(status.progress, 1);
  });
}
