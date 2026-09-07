import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/experience/experience_catalog.dart';

void main() {
  test('catalog has the two focused experience directions', () {
    for (final pillar in ExperiencePillar.values) {
      expect(experiencesFor(pillar), isNotEmpty);
    }
  });

  test('MVP catalog focuses on pet and social families', () {
    expect(
      experienceCatalog.map((item) => item.id),
      containsAll(['holo_pet', 'holo_mystery']),
    );
    expect(experienceCatalog, hasLength(2));
  });

  test('HoloPet is available while social experiences remain planned', () {
    final holoPet =
        experienceCatalog.singleWhere((item) => item.id == 'holo_pet');
    expect(holoPet.availability, ExperienceAvailability.available);
    expect(
      experienceCatalog
          .where((item) => item.id != 'holo_pet')
          .every((item) => item.availability == ExperienceAvailability.planned),
      isTrue,
    );
  });
}
