import '../customization/custom_plans_page.dart';
import 'package:flutter/material.dart';
import '../../config/launch_config.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';

import '../../experience/projection_service.dart';
import '../customization/character_gate_prototype_pages.dart';
import '../customization/character_gate_ui.dart';
import '../customization/customization_discovery_card.dart';
import '../community/remote_layout_repository.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({required this.projection, super.key});
  final ProjectionService projection;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late final Future<List<RemoteLayoutBlock>> layout = _loadLayout();

  Future<List<RemoteLayoutBlock>> _loadLayout() async {
    const backendUrl = String.fromEnvironment('HILDORS_API_BASE_URL');
    if (backendUrl.isEmpty) return _fallbackLayout;
    try {
      final blocks =
          await RemoteLayoutRepository(backendUrl).loadPage('discover');
      return blocks.isEmpty ? _fallbackLayout : blocks;
    } catch (_) {
      return _fallbackLayout;
    }
  }

  @override
  Widget build(BuildContext context) => GateScaffold(
        wide: true,
        appBar: AppBar(title: Text(context.l10n.coreExplore)),
        body: FutureBuilder<List<RemoteLayoutBlock>>(
          future: layout,
          builder: (context, snapshot) =>
              ListView(padding: EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
            Text(context.l10n.coreCharacterPortal,
                style: GateDesign.theme().textTheme.titleLarge),
            SizedBox(height: 4),
            Text(LaunchConfig.usFree
                ? context.l10n.coreExploreFreeSubtitle
                : context.l10n.coreExploreSubtitle),
            SizedBox(height: 12),
            for (final block in snapshot.data ?? _fallbackLayout)
              if (block.visible &&
                  (!LaunchConfig.usFree ||
                      block.type == 'creator_join' ||
                      block.type == 'customization')) ...[
                _layoutBlock(block),
                SizedBox(height: 10),
              ],
          ]),
        ),
      );

  Widget _layoutBlock(RemoteLayoutBlock block) => switch (block.type) {
        'customization' => LaunchConfig.usFree
            ? _DiscoveryEntry(
                title: context.l10n.customPlansTitle,
                description: context.l10n.customUnavailable,
                icon: Icons.movie_creation_outlined,
                page: const CustomPlansPage(),
              )
            : const CustomizationDiscoveryCard(),
        'character_portal' => _DiscoveryEntry(
            title: context.l10n.coreWish,
            description: context.l10n.coreWishSubtitle,
            icon: Icons.star_outline,
            page: IpWishPage(),
          ),
        'creator_join' => _DiscoveryEntry(
            title: context.l10n.coreCreatorCenter,
            description: LaunchConfig.usFree
                ? context.l10n.coreCreatorFreeSubtitle
                : context.l10n.coreCreatorExploreSubtitle,
            icon: Icons.handyman_outlined,
            page: CreatorHubPage(),
          ),
        _ => SizedBox.shrink(),
      };
}

const _fallbackLayout = [
  RemoteLayoutBlock(
      id: 'discover-customization',
      type: 'customization',
      title: '',
      visible: true,
      columns: 1),
  RemoteLayoutBlock(
      id: 'discover-portal',
      type: 'character_portal',
      title: '',
      visible: true,
      columns: 2),
  RemoteLayoutBlock(
      id: 'discover-creator',
      type: 'creator_join',
      title: '',
      visible: true,
      columns: 1),
];

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
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Icon(icon, color: GateDesign.accent, size: 24),
              SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: GateDesign.theme().textTheme.titleMedium),
                    SizedBox(height: 2),
                    Text(description,
                        style: GateDesign.theme().textTheme.bodySmall),
                  ])),
              SizedBox(width: 8),
              Icon(Icons.chevron_right,
                  size: 20, semanticLabel: context.l10n.coreEnter),
            ]),
          ),
        ),
      );
}
