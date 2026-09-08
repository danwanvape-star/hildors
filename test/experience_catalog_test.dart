import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/experience/experience_catalog.dart';

void main() {
  test('catalog has the two focused experience directions', () {
    for (final pillar in ExperiencePillar.values) {
      expect(experiencesFor(pillar), isNotEmpty);
    }
  });

  test('MVP catalog focuses on character companion and social play', () {
    expect(
      experienceCatalog.map((item) => item.id),
      containsAll(['character_companion', 'holo_roulette']),
    );
    expect(experienceCatalog, hasLength(2));
  });

  test('pet product is removed while its companion direction is retained', () {
    expect(
        experienceCatalog.map((item) => item.id), isNot(contains('holo_pet')));
    final companion = experienceCatalog
        .singleWhere((item) => item.id == 'character_companion');
    expect(companion.availability, ExperienceAvailability.planned);
  });
}
