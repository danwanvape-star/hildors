enum HoloPetOrigin { official, custom }

class HoloPetProfile {
  const HoloPetProfile({
    required this.id,
    required this.name,
    required this.characterName,
    required this.origin,
    this.assetPath,
  });

  const HoloPetProfile.neonShiba({String name = '小光'})
      : this(
          id: 'neon_shiba_v1',
          name: name,
          characterName: '霓虹柴犬',
          origin: HoloPetOrigin.official,
          assetPath: 'assets/holopet/holopet_master.png',
        );

  final String id;
  final String name;
  final String characterName;
  final HoloPetOrigin origin;
  final String? assetPath;

  String get originLabel => origin == HoloPetOrigin.official ? '官方领养' : '专属定制';
}
