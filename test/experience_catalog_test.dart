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
      containsAll(['holo_pet', 'holo_mystery', 'holo_host']),
    );
    expect(experienceCatalog, hasLength(3));
  });

  test('focused exploration experiences are currently planned', () {
    expect(
      experienceCatalog.every(
        (item) => item.availability == ExperienceAvailability.planned,
      ),
      isTrue,
    );
  });
}
