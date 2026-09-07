import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/holopet/holopet_profile.dart';

void main() {
  test('official adoption keeps the user chosen pet name', () {
    const profile = HoloPetProfile.neonShiba(name: '团子');
    expect(profile.name, '团子');
    expect(profile.characterName, '霓虹柴犬');
    expect(profile.origin, HoloPetOrigin.official);
    expect(profile.originLabel, '官方领养');
  });

  test('custom profile is labelled as exclusive customization', () {
    const profile = HoloPetProfile(
      id: 'custom_001',
      name: '可乐',
      characterName: '定制柴犬',
      origin: HoloPetOrigin.custom,
    );
    expect(profile.originLabel, '专属定制');
  });
}
