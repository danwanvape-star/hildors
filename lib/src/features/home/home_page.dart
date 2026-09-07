import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../device/device_error_message.dart';
import '../../device/p20_command_session.dart';
import '../../device/p20_device_client.dart';
import '../../experience/projection_service.dart';
import '../../media/bundled_video_controller.dart';
import '../control/control_page.dart';
import '../video/device_playlist_draft.dart';
import '../video/playlist_management_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.client,
    required this.session,
    required this.projection,
    this.isActive = true,
    super.key,
  });

  final P20DeviceClient client;
  final P20CommandSession session;
  final ProjectionService projection;
  final bool isActive;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DeviceConnectionState _connection;
  StreamSubscription<DeviceConnectionState>? _subscription;
  String? _error;
  var _devicePlaying = true;

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

  void _sendDeviceCommand(VoidCallback command, {bool? playing}) {
    if (_connection != DeviceConnectionState.connected) return;
    try {
      command();
      if (playing != null) setState(() => _devicePlaying = playing);
    } catch (error) {
      debugPrint('Device playback command failed: $error');
      setState(() => _error = '设备暂时没有响应，请确认连接后重试。');
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
              devicePlaying: _devicePlaying,
              onPrevious: () => _sendDeviceCommand(widget.client.previousTrack),
              onTogglePlayback: () => _sendDeviceCommand(
                () => widget.client.setPlaying(!_devicePlaying),
                playing: !_devicePlaying,
              ),
              onNext: () => _sendDeviceCommand(widget.client.nextTrack),
              onOpenStartup: () => _openPlaylist(DevicePlaylistKind.startup),
              onOpenBluetooth: () =>
                  _openPlaylist(DevicePlaylistKind.bluetooth),
              videoPreviewEnabled: widget.isActive,
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
    required this.devicePlaying,
    required this.onPrevious,
    required this.onTogglePlayback,
    required this.onNext,
    required this.onOpenStartup,
    required this.onOpenBluetooth,
    required this.videoPreviewEnabled,
  });

  final bool connected;
  final bool devicePlaying;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePlayback;
  final VoidCallback onNext;
  final VoidCallback onOpenStartup;
  final VoidCallback onOpenBluetooth;
  final bool videoPreviewEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.secondary.withValues(alpha: 0.34)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF062F35), Color(0xFF111527), Color(0xFF23132F)],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.secondary.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('当前角色', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 3),
                Text('HILDORS Collection',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            )),
            _StatusPill(connected: connected),
          ]),
          const SizedBox(height: 14),
          _ShowcaseVideoPreview(enabled: videoPreviewEnabled),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '全息设备播放控制',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton.filledTonal(
                tooltip: '设备上一条',
                onPressed: connected ? onPrevious : null,
                icon: const Icon(Icons.skip_previous),
              ),
              IconButton.filled(
                tooltip: devicePlaying ? '暂停设备播放' : '继续设备播放',
                onPressed: connected ? onTogglePlayback : null,
                icon: Icon(devicePlaying ? Icons.pause : Icons.play_arrow),
              ),
              IconButton.filledTonal(
                tooltip: '设备下一条',
                onPressed: connected ? onNext : null,
                icon: const Icon(Icons.skip_next),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _PlaylistShortcut(
              icon: Icons.wb_sunny_outlined,
              title: '日常展示',
              subtitle: '开机自动播放',
              onTap: onOpenStartup,
            )),
            const SizedBox(width: 10),
            Expanded(
                child: _PlaylistShortcut(
              icon: Icons.graphic_eq,
              title: '音乐联动',
              subtitle: '连接蓝牙后播放',
              onTap: onOpenBluetooth,
            )),
          ]),
        ],
      ),
    );
  }
}

class _ShowcaseVideoPreview extends StatefulWidget {
  const _ShowcaseVideoPreview({required this.enabled});

  final bool enabled;

  @override
  State<_ShowcaseVideoPreview> createState() => _ShowcaseVideoPreviewState();
}

class _ShowcaseVideoPreviewState extends State<_ShowcaseVideoPreview> {
  static const _assets = [
    'assets/videos/showcase/showcase_01.mp4',
    'assets/videos/showcase/showcase_02.mp4',
    'assets/videos/showcase/showcase_03.mp4',
    'assets/videos/showcase/showcase_04.mp4',
  ];

  VideoPlayerController? _controller;
  var _index = 0;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _load(0);
  }

  @override
  void didUpdateWidget(covariant _ShowcaseVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled == widget.enabled) return;
    if (widget.enabled) {
      _load(_index);
    } else {
      final controller = _controller;
      _controller = null;
      setState(() => _loading = false);
      controller?.dispose();
    }
  }

  Future<void> _load(int index) async {
    setState(() => _loading = true);
    final previous = _controller;
    try {
      final next = await createBundledVideoController(_assets[index]);
      await next.setLooping(true);
      await next.setVolume(0);
      await next.play();
      if (!mounted) {
        await next.dispose();
        return;
      }
      setState(() {
        _controller = next;
        _index = index;
        _loading = false;
      });
      await previous?.dispose();
    } catch (error, stackTrace) {
      debugPrint('Home demo video failed: ' + error.toString());
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => _loading = false);
    }
  }

  void _move(int offset) {
    final next = (_index + offset + _assets.length) % _assets.length;
    _load(next);
  }

  Future<void> _toggle() async {
    final controller = _controller;
    if (controller == null) return;
    controller.value.isPlaying
        ? await controller.pause()
        : await controller.play();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller?.value.isInitialized ?? false;
    return Container(
      height: 220,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/images/p20_product_showcase.jpg',
            fit: BoxFit.cover),
        if (ready)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller!.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xCC000000)],
            ),
          ),
        ),
        if (_loading) const Center(child: CircularProgressIndicator()),
        Positioned(
          left: 10,
          right: 10,
          bottom: 8,
          child: Row(children: [
            IconButton.filledTonal(
              tooltip: '上一个展示视频',
              onPressed: () => _move(-1),
              icon: const Icon(Icons.skip_previous),
            ),
            IconButton.filled(
              tooltip: ready && controller!.value.isPlaying ? '暂停预览' : '播放预览',
              onPressed: ready ? _toggle : null,
              icon: Icon(ready && controller!.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow),
            ),
            IconButton.filledTonal(
              tooltip: '下一个展示视频',
              onPressed: () => _move(1),
              icon: const Icon(Icons.skip_next),
            ),
            const Spacer(),
            for (var i = 0; i < _assets.length; i++)
              Container(
                width: i == _index ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.only(left: 5),
                decoration: BoxDecoration(
                  color: i == _index
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white38,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
          child: Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon,
                    size: 21, color: Theme.of(context).colorScheme.secondary),
                const Spacer(),
                const Icon(Icons.chevron_right, size: 20),
              ]),
              const SizedBox(height: 12),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
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
