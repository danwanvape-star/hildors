enum ExperiencePillar { petCompanion, socialAndFamily }

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
    id: 'holo_pet',
    title: 'HoloPet',
    subtitle: '会回应、会成长的每日全息伙伴',
    pillar: ExperiencePillar.petCompanion,
    availability: ExperienceAvailability.planned,
  ),
  ExperienceCatalogItem(
    id: 'holo_mystery',
    title: 'Holo Mystery',
    subtitle: '朋友聚会和家庭派对的沉浸式角色互动',
    pillar: ExperiencePillar.socialAndFamily,
    availability: ExperienceAvailability.planned,
  ),
  ExperienceCatalogItem(
    id: 'holo_host',
    title: 'Holo Host',
    subtitle: '负责暖场、互动和流程提示的全息主持人',
    pillar: ExperiencePillar.socialAndFamily,
    availability: ExperienceAvailability.planned,
  ),
];

List<ExperienceCatalogItem> experiencesFor(ExperiencePillar pillar) =>
    experienceCatalog.where((item) => item.pillar == pillar).toList();
