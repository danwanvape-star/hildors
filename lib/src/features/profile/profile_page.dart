import 'package:flutter/material.dart';

import '../../device/p20_command_session.dart';
import '../../device/p20_device_client.dart';
import '../../theme/hildors_theme.dart';
import '../customization/customization_page.dart';
import '../settings/lan_connection_guide.dart';
import '../settings/playback_mode_guide.dart';
import '../settings/settings_page.dart';
import '../video/playlist_management_page.dart';
import '../video/video_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.client, required this.session, super.key});

  final P20DeviceClient client;
  final P20CommandSession session;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('我的'),
              Text(
                'PLAYER PROFILE',
                style: TextStyle(
                  color: HildorsColors.teal,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.1,
                ),
              ),
            ],
          ),
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.9, -0.75),
              radius: 1.15,
              colors: [Color(0x36234F70), HildorsColors.background],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              const _ProfileHero(),
              const SizedBox(height: 22),
              const _SectionLabel(index: '01', title: '座舱管理'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.router_outlined,
                      label: '设备',
                      onTap: () => _open(
                        context,
                        SettingsPage(client: client, session: session),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.playlist_play_rounded,
                      label: '播放列表',
                      onTap: () => _open(
                        context,
                        PlaylistManagementPage(
                          client: client,
                          session: session,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.video_library_outlined,
                      label: '设备内容',
                      onTap: () => _open(
                        context,
                        VideoPage(client: client, session: session),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionLabel(index: '02', title: '角色资产'),
              const SizedBox(height: 10),
              _Entry(
                icon: Icons.auto_awesome_rounded,
                eyebrow: 'CORE SERVICE',
                title: 'Character Portal',
                subtitle: '创建专属角色，跟踪制作与交付进度',
                accent: HildorsColors.purpleBright,
                onTap: () => _open(context, const CustomizationPage()),
              ),
              const _Entry(
                icon: Icons.bookmark_border_rounded,
                eyebrow: 'COLLECTION',
                title: '我的收藏',
                subtitle: '管理已收藏的角色与官方内容包',
                trailingLabel: '即将开放',
              ),
              const SizedBox(height: 24),
              const _SectionLabel(index: '03', title: '系统支持'),
              const SizedBox(height: 10),
              _Entry(
                icon: Icons.play_circle_outline_rounded,
                title: '播放模式说明',
                subtitle: '了解日常展示与音乐联动的切换逻辑',
                onTap: () => _open(context, const PlaybackModeGuide()),
              ),
              _Entry(
                icon: Icons.wifi_find_rounded,
                title: '局域网连接帮助',
                subtitle: '连接 P20/P11 热点及常见问题排查',
                onTap: () => _open(context, const LanConnectionGuide()),
              ),
              _Entry(
                icon: Icons.tune_rounded,
                title: '设备与 App 设置',
                subtitle: '设备参数、播放偏好与版本信息',
                onTap: () => _open(
                  context,
                  SettingsPage(client: client, session: session),
                ),
              ),
              const _Entry(
                icon: Icons.info_outline_rounded,
                title: '关于 HILDORS',
                subtitle: 'Character Portal · P20/P11 兼容架构',
              ),
            ],
          ),
        ),
      );

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero();

  @override
  Widget build(BuildContext context) => Container(
        height: 172,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: HildorsColors.hairline),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/content_thumbnails/space_pilot.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.22),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0x2234E7D4), Color(0xF205080D)],
                  stops: [0, 0.82],
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 18,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xB30D131C),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: HildorsColors.teal),
                ),
                child: const Text(
                  'LOCAL',
                  style: TextStyle(
                    color: HildorsColors.teal,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 16,
              bottom: 18,
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0x55FFFFFF)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.asset(
                        'assets/images/hildors_logo.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'HILDORS PILOT',
                          style: TextStyle(
                            color: HildorsColors.teal,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '玩家档案',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '本地座舱账户 · 数据保存在当前设备',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: HildorsColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.index, required this.title});

  final String index;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(index,
              style: const TextStyle(
                color: HildorsColors.teal,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              )),
          const SizedBox(width: 10),
          Container(width: 20, height: 1, color: HildorsColors.teal),
          const SizedBox(width: 10),
          Text(title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  )),
        ],
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: HildorsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 88,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: HildorsColors.hairline),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: HildorsColors.blue, size: 26),
                const SizedBox(height: 9),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.accent = HildorsColors.blue,
    this.trailingLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? eyebrow;
  final Color accent;
  final String? trailingLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: HildorsColors.surface,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              constraints: const BoxConstraints(minHeight: 82),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: HildorsColors.hairline),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withValues(alpha: 0.3)),
                    ),
                    child: Icon(icon, color: accent, size: 23),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (eyebrow != null) ...[
                          Text(eyebrow!,
                              style: TextStyle(
                                color: accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.3,
                              )),
                          const SizedBox(height: 2),
                        ],
                        Text(title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: HildorsColors.textSecondary,
                              fontSize: 12,
                              height: 1.35,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (trailingLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: HildorsColors.surfaceHighlight,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(trailingLabel!,
                          style: const TextStyle(
                            color: HildorsColors.textSecondary,
                            fontSize: 10,
                          )),
                    )
                  else if (onTap != null)
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 15, color: HildorsColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      );
}
