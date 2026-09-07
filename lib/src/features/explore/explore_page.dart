import 'package:flutter/material.dart';

import '../../experience/experience_catalog.dart';
import '../../experience/projection_service.dart';
import '../customization/customization_discovery_card.dart';
import '../holopet/holopet_hub_page.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({required this.projection, super.key});
  final ProjectionService projection;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('发现')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const CustomizationDiscoveryCard(),
          const SizedBox(height: 24),
          _ExperienceSection(
              title: '养成系宠物',
              subtitle: '喂养、互动、成长和每日陪伴',
              icon: Icons.pets_outlined,
              items: experiencesFor(ExperiencePillar.petCompanion),
              projection: projection),
          _ExperienceSection(
              title: '社交与家庭派对',
              subtitle: '暖场、主持、剧情和多人互动角色',
              icon: Icons.groups_outlined,
              items: experiencesFor(ExperiencePillar.socialAndFamily),
              projection: projection),
        ]),
      );
}

class _ExperienceSection extends StatelessWidget {
  const _ExperienceSection(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.items,
      required this.projection});
  final String title;
  final String subtitle;
  final IconData icon;
  final List<ExperienceCatalogItem> items;
  final ProjectionService projection;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleLarge)
        ]),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
        for (final item in items)
          _ExperienceCard(item: item, projection: projection),
      ]));
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.item, required this.projection});
  final ExperienceCatalogItem item;
  final ProjectionService projection;
  @override
  Widget build(BuildContext context) => Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
            child: Icon(item.id == 'holo_pet'
                ? Icons.pets
                : Icons.celebration_outlined)),
        title: Text(item.title),
        subtitle: Text(item.subtitle),
        trailing: item.id == 'holo_pet'
            ? const Icon(Icons.chevron_right)
            : const _PlannedLabel(),
        onTap: () {
          if (item.id == 'holo_pet') {
            Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => HoloPetHubPage(projection: projection)));
          } else {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('该体验正在规划中，敬请期待')));
          }
        },
      ));
}

class _PlannedLabel extends StatelessWidget {
  const _PlannedLabel();
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999)),
      child: Text('规划中', style: Theme.of(context).textTheme.labelSmall));
}
