import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/experience/experience_pack_manifest.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tarot light package contains 22 results and 8 common videos', () async {
    final manifest = await ExperiencePackRepository().loadTarotMajor();
    expect(manifest.id, 'tarot_major_v1');
    expect(manifest.files, hasLength(30));
    expect(
        manifest.files.where((file) => file.role == 'result'), hasLength(22));
    expect(manifest.files.where((file) => file.role != 'result'), hasLength(8));
    expect(manifest.supportedModels, containsAll(['P20', 'P11']));
    expect(manifest.minimumSizeMb, 300);
    expect(manifest.maximumSizeMb, 500);
  });

  test('manifest reports only files missing from the device', () async {
    final manifest = await ExperiencePackRepository().loadTarotMajor();
    final first = manifest.files.first.path;
    final second = manifest.files[1].path;
    final missing = manifest.missingFiles([first.toUpperCase(), second]);
    expect(missing, hasLength(28));
    expect(missing, isNot(contains(first)));
    expect(missing, isNot(contains(second)));
  });

  test('chaos party package contains every roulette stage', () async {
    final manifest = await ExperiencePackRepository().loadChaosParty();
    expect(manifest.id, 'chaos_party_v1');
    expect(manifest.files, hasLength(8));
    expect(
      manifest.files.map((file) => file.role),
      containsAll([
        'idle',
        'roulette',
        'thinking',
        'point',
        'laugh',
        'success',
        'fail',
        'next',
      ]),
    );
  });
}
