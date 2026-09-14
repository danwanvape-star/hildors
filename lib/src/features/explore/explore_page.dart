import 'package:flutter/material.dart';

import '../../experience/projection_service.dart';
import '../customization/character_gate_prototype_pages.dart';
import '../customization/character_gate_ui.dart';
import '../customization/customization_discovery_card.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({required this.projection, super.key});
  final ProjectionService projection;

  @override
  Widget build(BuildContext context) => GateScaffold(
        wide: true,
        appBar: AppBar(title: const Text('发现')),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Text('角色之门', style: GateDesign.theme().textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text('定制专属角色，提交心愿，参与创作。'),
              const SizedBox(height: 12),
              const CustomizationDiscoveryCard(),
              const SizedBox(height: 10),
              _DiscoveryEntry(
                title: '角色许愿',
                description: '提交心愿，关注授权进展',
                icon: Icons.star_outline,
                page: IpWishPage(),
              ),
              const _DiscoveryEntry(
                title: '创作者中心',
                description: '入驻、任务与收益',
                icon: Icons.handyman_outlined,
                page: CreatorHubPage(),
              ),
            ]),
      );
}

class _DiscoveryEntry extends StatelessWidget {
  const _DiscoveryEntry(
      {required this.title,
      required this.description,
      required this.icon,
      required this.page});
  final String title;
  final String description;
  final IconData icon;
  final Widget page;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => page)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Icon(icon, color: GateDesign.accent, size: 24),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: GateDesign.theme().textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(description,
                        style: GateDesign.theme().textTheme.bodySmall),
                  ])),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 20, semanticLabel: '进入'),
            ]),
          ),
        ),
      );
}
