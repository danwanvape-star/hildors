import 'package:flutter/material.dart';

import '../../experience/experience_catalog.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({required Object projection, super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('探索')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('两种核心体验', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            const Text('让设备既能长期陪伴，也能在家庭和朋友聚会中自然参与。'),
            const SizedBox(height: 24),
            _ExperienceSection(
              title: '养成系宠物',
              subtitle: '喂养、互动、成长和每日陪伴',
              icon: Icons.pets_outlined,
              items: experiencesFor(ExperiencePillar.petCompanion),
            ),
            _ExperienceSection(
              title: '社交与家庭派对',
              subtitle: '暖场、主持、剧情和多人互动角色',
              icon: Icons.groups_outlined,
              items: experiencesFor(ExperiencePillar.socialAndFamily),
            ),
          ],
        ),
      );
}

class _ExperienceSection extends StatelessWidget {
  const _ExperienceSection(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.items});

  final String title;
  final String subtitle;
  final IconData icon;
  final List<ExperienceCatalogItem> items;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleLarge)
            ]),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            for (final item in items) _ExperienceCard(item: item),
          ],
        ),
      );
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.item});

  final ExperienceCatalogItem item;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
              child: Icon(item.id == 'holo_pet'
                  ? Icons.pets
                  : item.id == 'holo_host'
                      ? Icons.mic_external_on_outlined
                      : Icons.celebration_outlined)),
          title: Text(item.title),
          subtitle: Text(item.subtitle),
          trailing: const _PlannedLabel(),
          onTap: () => ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('该体验正在规划中，敬请期待'))),
        ),
      );
}

class _PlannedLabel extends StatelessWidget {
  const _PlannedLabel();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999)),
        child: Text('规划中', style: Theme.of(context).textTheme.labelSmall),
      );
}
