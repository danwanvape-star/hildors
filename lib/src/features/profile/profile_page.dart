import 'package:flutter/material.dart';

import '../../device/p20_command_session.dart';
import '../../device/p20_device_client.dart';
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
        appBar: AppBar(title: const Text('我的')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/hildors_logo.jpg',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HILDORS',
                            style: Theme.of(context).textTheme.titleLarge),
                        const Text('全息座舱控制账户'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _Entry(
              icon: Icons.router_outlined,
              title: '设备管理',
              subtitle: '设备参数、播放模式与版本',
              onTap: () => _open(
                  context, SettingsPage(client: client, session: session)),
            ),
            _Entry(
              icon: Icons.playlist_play,
              title: '设备播放列表',
              subtitle: '开机播放与蓝牙播放的内容和顺序',
              onTap: () => _open(
                context,
                PlaylistManagementPage(client: client, session: session),
              ),
            ),
            _Entry(
              icon: Icons.video_library_outlined,
              title: '设备内容库',
              subtitle: '查看、播放和管理设备内的视频',
              onTap: () => _open(
                context,
                VideoPage(client: client, session: session),
              ),
            ),
            _Entry(
              icon: Icons.play_circle_outline,
              title: '播放模式说明',
              subtitle: '本机播放与蓝牙音响的切换逻辑',
              onTap: () => _open(context, const PlaybackModeGuide()),
            ),
            _Entry(
              icon: Icons.wifi_find,
              title: '局域网连接帮助',
              subtitle: '连接 P20 热点及故障排查',
              onTap: () => _open(context, const LanConnectionGuide()),
            ),
            _Entry(
              icon: Icons.auto_awesome_outlined,
              title: '定制服务',
              subtitle: '上传照片并填写全息内容制作需求',
              onTap: () => _open(context, const CustomizationPage()),
            ),
            const _Entry(
                icon: Icons.favorite_border,
                title: '收藏夹',
                subtitle: '收藏功能将在素材体验阶段开放'),
            const _Entry(
                icon: Icons.info_outline,
                title: '关于 App',
                subtitle: '版本 0.1.0 · P20/P11 兼容架构'),
          ],
        ),
      );

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _Entry extends StatelessWidget {
  const _Entry(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: onTap == null ? null : const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
