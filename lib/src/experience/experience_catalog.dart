enum ExperiencePillar { characterCompanion, socialAndFamily }

enum ExperienceAvailability { available, protocolPending, planned }

class ExperienceCatalogItem {
  const ExperienceCatalogItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.pillar,
    required this.availability,
  });

  final String id;
  final String title;
  final String subtitle;
  final ExperiencePillar pillar;
  final ExperienceAvailability availability;
}

const experienceCatalog = <ExperienceCatalogItem>[
  ExperienceCatalogItem(
    id: 'character_companion',
    title: '角色陪伴',
    subtitle: '让收藏角色拥有每日问候、互动动作与陪伴记忆',
    pillar: ExperiencePillar.characterCompanion,
    availability: ExperienceAvailability.planned,
  ),
  ExperienceCatalogItem(
    id: 'holo_roulette',
    title: 'Holo Roulette',
    subtitle: '随机抽取一位玩家，接受轻松有趣的派对挑战',
    pillar: ExperiencePillar.socialAndFamily,
    availability: ExperienceAvailability.available,
  ),
];

List<ExperienceCatalogItem> experiencesFor(ExperiencePillar pillar) =>
    experienceCatalog.where((item) => item.pillar == pillar).toList();
