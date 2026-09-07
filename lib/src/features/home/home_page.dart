import 'dart:async';

import 'package:flutter/material.dart';
import '../../device/device_error_message.dart';
import '../../device/p20_command_session.dart';
import '../../device/p20_device_client.dart';
import '../../experience/projection_service.dart';
import '../control/control_page.dart';
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
    } catch (error, stackTrace) {
      debugPrint('Device connection failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() => _error = friendlyDeviceConnectionError(error));
      }
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
            _DeviceCard(
              connection: _connection,
              busy: _busy,
              error: _error,
              onConnect: _connect,
              onControl: _openControl,
            ),
            const SizedBox(height: 16),
            _NowPlayingCard(
              connected: _connection == DeviceConnectionState.connected,
              onOpenStartup: () => _openPlaylist(DevicePlaylistKind.startup),
              onOpenBluetooth: () =>
                  _openPlaylist(DevicePlaylistKind.bluetooth),
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 520,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.secondary.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: colors.secondary.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/p20_product_showcase.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33000000),
                  Color(0x22000000),
                  Color(0xF20A1015),
                ],
                stops: [0, 0.48, 0.78],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: 18,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '设备播放列表',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 3),
                      const Text('选择设备当前使用的播放场景'),
                    ],
                  ),
                ),
                _StatusPill(connected: connected),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 88,
            child: Column(
              children: [
                _PlaylistShortcut(
                  icon: Icons.wb_sunny_outlined,
                  title: '日常展示',
                  subtitle: '管理开机后自动播放的内容',
                  onTap: onOpenStartup,
                ),
                const SizedBox(height: 10),
                _PlaylistShortcut(
                  icon: Icons.graphic_eq,
                  title: '音乐联动',
                  subtitle: '管理连接蓝牙后播放的内容',
                  onTap: onOpenBluetooth,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.connected});
  final bool connected;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: connected
              ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(connected ? Icons.wifi : Icons.wifi_off, size: 14),
          const SizedBox(width: 5),
          Text(connected ? '在线' : '未连接'),
        ]),
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
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 88,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 28),
                ],
              ),
            ),
          ),
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
