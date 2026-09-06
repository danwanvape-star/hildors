import 'dart:async';

import 'package:flutter/material.dart';

import '../../device/p20_command_session.dart';
import '../../device/p20_device_client.dart';
import '../../experience/projection_service.dart';
import '../control/control_page.dart';
import '../customization/customization_page.dart';
import '../interaction/interaction_page.dart';
import '../video/device_playlist_draft.dart';
import '../video/playlist_management_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.client,
    required this.session,
    required this.projection,
    super.key,
  });

  final P20DeviceClient client;
  final P20CommandSession session;
  final ProjectionService projection;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DeviceConnectionState _connection;
  StreamSubscription<DeviceConnectionState>? _subscription;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connection = widget.client.connectionState;
    _subscription = widget.client.connectionStates.listen((state) {
      if (mounted) setState(() => _connection = state);
    });
  }

  bool get _busy =>
      _connection == DeviceConnectionState.connecting ||
      _connection == DeviceConnectionState.reconnecting;

  Future<void> _connect() async {
    setState(() => _error = null);
    try {
      await widget.client.connect();
    } catch (error) {
      if (mounted) setState(() => _error = '连接失败：$error');
    }
  }

  void _openControl() => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ControlPage(client: widget.client),
        ),
      );

  void _openPlaylist(DevicePlaylistKind kind) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlaylistManagementPage(
            client: widget.client,
            session: widget.session,
            initialKind: kind,
          ),
        ),
      );

  void _openCustomization() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CustomizationPage()),
      );

  void _openMysticPortal() => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => InteractionPage(projection: widget.projection),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/hildors_logo.jpg',
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              const Text('HILDORS'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: '设备控制',
              onPressed: _openControl,
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _NowPlayingCard(
              connected: _connection == DeviceConnectionState.connected,
              onOpenStartup: () => _openPlaylist(DevicePlaylistKind.startup),
              onOpenBluetooth: () =>
                  _openPlaylist(DevicePlaylistKind.bluetooth),
            ),
            const SizedBox(height: 16),
            _HeroCard(onTap: _openCustomization),
            const SizedBox(height: 16),
            _DeviceCard(
              connection: _connection,
              busy: _busy,
              error: _error,
              onConnect: _connect,
              onControl: _openControl,
            ),
            const SizedBox(height: 24),
            _SubscriptionCard(onTap: _openCustomization),
            const SizedBox(height: 24),
            Text('继续体验', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(child: Icon(Icons.auto_awesome)),
                title: const Text('Mystic Portal'),
                subtitle: const Text('每日一牌、三牌阵与星座互动'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openMysticPortal,
              ),
            ),
            const SizedBox(height: 24),
            Text('探索场景', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            const Row(
              children: [
                Expanded(
                  child: _PillarCard(
                    icon: Icons.pets_outlined,
                    title: '养成系宠物',
                    subtitle: '陪伴与成长',
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _PillarCard(
                    icon: Icons.groups_outlined,
                    title: '社交与家庭',
                    subtitle: '聚会氛围角色',
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class _NowPlayingCard extends StatelessWidget {
  const _NowPlayingCard({
    required this.connected,
    required this.onOpenStartup,
    required this.onOpenBluetooth,
  });

  final bool connected;
  final VoidCallback onOpenStartup;
  final VoidCallback onOpenBluetooth;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.play_arrow_rounded)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('当前播放',
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(connected ? '设备已连接 · 等待读取播放状态' : '连接设备后查看当前内容'),
                      ],
                    ),
                  ),
                  Chip(label: Text(connected ? '局域网在线' : '未连接')),
                ],
              ),
              const SizedBox(height: 18),
              Text('播放列表', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PlaylistShortcut(
                      icon: Icons.power_settings_new,
                      title: '开机播放列表',
                      subtitle: '未连接蓝牙时播放',
                      onTap: onOpenStartup,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PlaylistShortcut(
                      icon: Icons.bluetooth_audio,
                      title: '蓝牙播放列表',
                      subtitle: '连接蓝牙后播放',
                      onTap: onOpenBluetooth,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _PlaylistShortcut extends StatelessWidget {
  const _PlaylistShortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle,
                    maxLines: 2, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('定制你的专属全息角色',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700)),
                      SizedBox(height: 8),
                      Text('上传照片与需求，打造持续更新的专属内容'),
                      SizedBox(height: 12),
                      Chip(label: Text('未来订阅服务')),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/hildors_logo.jpg',
                    width: 78,
                    height: 104,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading:
              const CircleAvatar(child: Icon(Icons.workspace_premium_outlined)),
          title: const Text('专属内容订阅'),
          subtitle: const Text('持续获得角色与动作内容，订阅方案筹备中'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard(
      {required this.connection,
      required this.busy,
      required this.error,
      required this.onConnect,
      required this.onControl});

  final DeviceConnectionState connection;
  final bool busy;
  final String? error;
  final VoidCallback onConnect;
  final VoidCallback onControl;

  @override
  Widget build(BuildContext context) {
    final connected = connection == DeviceConnectionState.connected;
    final status = switch (connection) {
      DeviceConnectionState.connected => '设备已连接',
      DeviceConnectionState.connecting => '正在连接…',
      DeviceConnectionState.reconnecting => '正在重连…',
      DeviceConnectionState.disconnected => '设备未连接',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(connected ? Icons.wifi : Icons.wifi_off,
                    color: connected
                        ? Theme.of(context).colorScheme.primary
                        : null),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(status,
                          style: Theme.of(context).textTheme.titleMedium),
                      const Text('局域网控制 · P20 / P11'),
                    ],
                  ),
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        busy ? null : (connected ? onControl : onConnect),
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(connected ? Icons.tune : Icons.link),
                    label: Text(connected ? '设备控制' : '连接 P20'),
                  ),
                ),
                if (!connected) ...[
                  const SizedBox(width: 10),
                  OutlinedButton(
                      onPressed: onControl, child: const Text('连接设置')),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard(
      {required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
          child: Column(
            children: [
              Icon(icon),
              const SizedBox(height: 8),
              Text(title,
                  maxLines: 1,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
}
