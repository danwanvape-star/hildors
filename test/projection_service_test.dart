import 'p20_live_playlist_test.dart' show LiveClient, LiveSession;
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/experience/projection_service.dart';

class SwitchingClient extends LiveClient {
  @override
  int get generation => epoch;
}

class ProjectionSession extends LiveSession {
  ProjectionSession(super.client);
  @override
  Future<void> playVideo(String name, {int listId = 0}) async {}
}

void main() {
  test('projection catalog is scoped to the current device generation',
      () async {
    final client = SwitchingClient()..online = true;
    final session = ProjectionSession(client);
    final service = P20ProjectionService(client, session);
    const item = ExperienceResult(id: 'a', title: 'a', deviceVideo: 'a.mp4');
    await service.present(item);
    client.epoch++;
    session.files[0] = ['other.bin'];
    expect(await service.present(item), ProjectionOutcome.missingMaterial);
    await session.dispose();
    await client.dispose();
  });
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
