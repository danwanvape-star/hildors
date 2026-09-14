import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import 'character_entitlement_repository.dart';
import 'character_gate_ui.dart';
import 'character_gate_prototype_pages.dart';
import 'customization_order_repository.dart';
import 'creator_profile_repository.dart';

class CustomizationPage extends StatelessWidget {
  const CustomizationPage({
    this.repository,
    this.orderRepository,
    this.creatorProfileRepository,
    super.key,
  });

  final CharacterEntitlementRepository? repository;
  final CustomizationOrderRepository? orderRepository;
  final CreatorProfileRepository? creatorProfileRepository;

  @override
  Widget build(BuildContext context) {
    final colors = GateDesign.theme().colorScheme;
    return GateScaffold(
      appBar: AppBar(title: const Text('角色之门')),
      body: ListView(
        scrollCacheExtent: const ScrollCacheExtent.pixels(600),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _GateHero(),
          const SizedBox(height: 12),
          GateColumns(children: [
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.person_pin_circle_outlined),
                title: const Text('我的角色'),
                subtitle: const Text('查看已领取和已交付角色，并将内容发送到设备。'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(
                  context,
                  MyCharactersPage(
                    repository: repository,
                    orderRepository: orderRepository,
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.handyman_outlined),
                title: const Text('创作者工作台'),
                subtitle: const Text('认证创作者可查看平台审核后的任务并申请接单。'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(
                  context,
                  CreatorHubPage(
                    orderRepository: orderRepository,
                    profileRepository: creatorProfileRepository,
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          Text('选择进入方式', style: GateDesign.theme().textTheme.titleLarge),
          const SizedBox(height: 12),
          _GatePathCard(
            icon: Icons.collections_bookmark_outlined,
            title: '免费原创角色',
            description: '浏览创作者原创角色，免费领取并安装到绑定的 Hildors 设备。',
            action: '浏览免费角色',
            onTap: () => _open(
              context,
              FreeOriginalCharactersPage(repository: repository),
            ),
          ),
          const SizedBox(height: 12),
          _GatePathCard(
            icon: Icons.design_services_outlined,
            emphasized: true,
            title: '定制你的专属角色',
            description: '提交你的 OC、原创手办或品牌角色，先免费预审，再决定是否付款制作。',
            action: '免费预审并获取报价',
            onTap: () => _open(
              context,
              CharacterSourcePage(orderRepository: orderRepository),
            ),
          ),
          const SizedBox(height: 12),
          _GatePathCard(
            icon: Icons.star_outline,
            title: '许愿一个角色',
            description: '喜欢的游戏或动漫角色还未开放？提交愿望并关注未来授权进度。',
            action: '提交角色愿望',
            onTap: () => _open(context, const IpWishPage()),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: colors.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child:
                        Text('免费或付费内容都会加入你的角色收藏，并通过受控流程安装到设备；不提供原视频或工程文件导出。'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _GatePathCard extends StatelessWidget {
  const _GatePathCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String action;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = GateDesign.theme().colorScheme;
    return Card(
      color: emphasized ? colors.primaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: colors.primary.withValues(alpha: 0.14),
                foregroundColor: colors.primary,
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(description),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Flexible(
                            child: Text(action,
                                style: TextStyle(color: colors.primary))),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward,
                            size: 18, color: colors.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GateHero extends StatelessWidget {
  const _GateHero();

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF3C5663)),
          gradient: const LinearGradient(
              colors: [Color(0xFF163B40), Color(0xFF211F42)]),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final art = ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
                'assets/images/content_thumbnails/celestial_mage.jpg',
                height: 210,
                width: 180,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                excludeFromSemantics: true),
          );
          final copy =
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('CHARACTER PORTAL / 01',
                style: TextStyle(
                    color: GateDesign.accent,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Text('打开角色之门，\n让 TA 来到你的桌面',
                style: GateDesign.theme().textTheme.headlineMedium),
            const SizedBox(height: 12),
            const Text('免费收藏原创角色。只有为你单独制作的专属定制需要付费。',
                style: TextStyle(color: GateDesign.ink, height: 1.6)),
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.verified_user_outlined,
                  size: 16, color: GateDesign.accent),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(GateCopy.text(context, 'secure'),
                      style: const TextStyle(
                          color: GateDesign.muted, fontSize: 12)))
            ]),
          ]);
          return Padding(
              padding: const EdgeInsets.all(24),
              child: constraints.maxWidth >= 640
                  ? Row(children: [
                      Expanded(child: copy),
                      const SizedBox(width: 28),
                      art
                    ])
                  : copy);
        }),
      );
}
