import 'dart:async';
import 'package:flutter/material.dart';

import '../../device/p20_command_session.dart';
import '../../device/p20_device_client.dart';
import 'device_playlist_draft.dart';

class PlaylistManagementPage extends StatefulWidget {
  const PlaylistManagementPage({
    required this.client,
    required this.session,
    this.initialKind = DevicePlaylistKind.startup,
    super.key,
  });

  final P20DeviceClient client;
  final P20CommandSession session;
  final DevicePlaylistKind initialKind;

  @override
  State<PlaylistManagementPage> createState() => _PlaylistManagementPageState();
}

class _PlaylistManagementPageState extends State<PlaylistManagementPage> {
  StreamSubscription<DeviceConnectionState>? _subscription;
  late DeviceConnectionState _connection;
  late DevicePlaylistKind _kind;
  var _loading = false;
  List<P20VideoEntry> _deviceVideos = const [];
  String? _error;

  late var _startup = const DevicePlaylistDraft(
    kind: DevicePlaylistKind.startup,
    enabled: true,
    loopMode: PlaylistLoopMode.listLoop,
    videoNames: ['PET_WELCOME.MP4', 'FAMILY_HOST.MP4', 'AMBIENT_LOOP.MP4'],
  );
  late var _bluetooth = const DevicePlaylistDraft(
    kind: DevicePlaylistKind.bluetooth,
    enabled: true,
    loopMode: PlaylistLoopMode.listLoop,
    videoNames: ['MUSIC_JELLYFISH.MP4', 'NEON_EARTH.MP4'],
  );

  bool get _connected => _connection == DeviceConnectionState.connected;
  DevicePlaylistDraft get _draft =>
      _kind == DevicePlaylistKind.startup ? _startup : _bluetooth;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    _connection = widget.client.connectionState;
    _subscription = widget.client.connectionStates.listen((value) {
      if (mounted) setState(() => _connection = value);
    });
  }

  void _update(DevicePlaylistDraft value) {
    setState(() {
      if (_kind == DevicePlaylistKind.startup) {
        _startup = value;
      } else {
        _bluetooth = value;
      }
    });
  }

  Future<void> _readDeviceVideos() async {
    if (!_connected || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final videos = await widget.session.queryVideos();
      if (mounted) setState(() => _deviceVideos = videos);
    } catch (error) {
      if (mounted) setState(() => _error = '读取设备视频失败：$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDeviceVideoPicker() async {
    if (_deviceVideos.isEmpty) await _readDeviceVideos();
    if (!mounted || _deviceVideos.isEmpty) return;
    final available = _deviceVideos
        .where((video) => !_draft.videoNames.contains(video.fileName))
        .toList(growable: false);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text('从设备视频库添加', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (available.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: Text('设备视频均已加入当前草案')),
              ),
            for (final video in available)
              ListTile(
                leading: const Icon(Icons.video_file_outlined),
                title: Text(video.fileName),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () {
                  _update(_draft.add(video.fileName));
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeFromPlaylist(String fileName) async {
    final kind = _kind;
    final previous = _draft;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移出播放列表？'),
        content: Text('“$fileName”只会从当前播放列表移除，不会删除手机或设备中的视频文件。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移出列表'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _update(previous.remove(fileName));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('已将 $fileName 移出播放列表'),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () {
              if (!mounted) return;
              setState(() {
                if (kind == DevicePlaylistKind.startup) {
                  _startup = previous;
                } else {
                  _bluetooth = previous;
                }
              });
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('设备播放列表'),
          actions: [
            IconButton(
              tooltip: '读取设备视频',
              onPressed: _connected && !_loading ? _readDeviceVideos : null,
              icon: _loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _ProtocolNotice(),
            const SizedBox(height: 12),
            _DeviceSourceCard(
              connected: _connected,
              videoCount: _deviceVideos.length,
              error: _error,
              onRead: _connected ? _readDeviceVideos : null,
            ),
            const SizedBox(height: 16),
            SegmentedButton<DevicePlaylistKind>(
              segments: const [
                ButtonSegment(
                  value: DevicePlaylistKind.startup,
                  icon: Icon(Icons.power_settings_new),
                  label: Text('开机播放'),
                ),
                ButtonSegment(
                  value: DevicePlaylistKind.bluetooth,
                  icon: Icon(Icons.bluetooth_audio),
                  label: Text('蓝牙播放'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (value) =>
                  setState(() => _kind = value.single),
            ),
            const SizedBox(height: 18),
            Text(
              _kind == DevicePlaylistKind.startup
                  ? '设备开机且未连接蓝牙时自动播放'
                  : '蓝牙音源连接后由硬件自动切换播放',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SwitchListTile(
              value: _draft.enabled,
              onChanged: (value) => _update(_draft.copyWith(enabled: value)),
              title: Text(
                _kind == DevicePlaylistKind.startup ? '开机自动播放' : '连接蓝牙后播放画面',
              ),
              subtitle: const Text('当前修改仅保存在交互草案中'),
            ),
            DropdownButtonFormField<PlaylistLoopMode>(
              key: ValueKey(_kind),
              initialValue: _draft.loopMode,
              decoration: const InputDecoration(
                labelText: '循环方式',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: PlaylistLoopMode.listLoop,
                  child: Text('列表循环'),
                ),
                DropdownMenuItem(
                  value: PlaylistLoopMode.singleLoop,
                  child: Text('单曲循环'),
                ),
                DropdownMenuItem(
                  value: PlaylistLoopMode.playOnce,
                  child: Text('播放一次'),
                ),
              ],
              onChanged: (value) {
                if (value != null) _update(_draft.copyWith(loopMode: value));
              },
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text('播放顺序',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                Text('${_draft.videoNames.length} 个视频'),
                IconButton(
                  tooltip: '从设备添加',
                  onPressed: _connected ? _showDeviceVideoPicker : null,
                  icon: const Icon(Icons.playlist_add),
                ),
              ],
            ),
            if (_draft.videoNames.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('当前播放列表为空')),
              ),
            for (var index = 0; index < _draft.videoNames.length; index++)
              Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(_draft.videoNames[index]),
                  subtitle: index == 0 ? const Text('默认首条') : null,
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: '上移',
                        onPressed: index == 0
                            ? null
                            : () => _update(_draft.move(index, index - 1)),
                        icon: const Icon(Icons.keyboard_arrow_up),
                      ),
                      IconButton(
                        tooltip: '下移',
                        onPressed: index == _draft.videoNames.length - 1
                            ? null
                            : () => _update(_draft.move(index, index + 1)),
                        icon: const Icon(Icons.keyboard_arrow_down),
                      ),
                      IconButton(
                        tooltip: '移出草案',
                        onPressed: () =>
                            _removeFromPlaylist(_draft.videoNames[index]),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.sync_disabled),
              label: const Text('保存到设备 · 等待新版协议'),
            ),
            if (_kind == DevicePlaylistKind.bluetooth)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.settings_backup_restore),
                  title: Text('蓝牙断开后的恢复策略'),
                  subtitle: Text('建议恢复连接前播放的普通视频；等待协议确认'),
                ),
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

class _DeviceSourceCard extends StatelessWidget {
  const _DeviceSourceCard({
    required this.connected,
    required this.videoCount,
    required this.error,
    required this.onRead,
  });

  final bool connected;
  final int videoCount;
  final String? error;
  final VoidCallback? onRead;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(connected ? Icons.router : Icons.wifi_off),
          title: Text(connected ? '设备视频素材已连接' : '设备未连接'),
          subtitle: Text(
            error ??
                (connected
                    ? videoCount == 0
                        ? '可读取统一视频列表，作为两套列表的素材来源'
                        : '已读取 $videoCount 个设备视频'
                    : '请先连接 P20/P11 局域网'),
          ),
          trailing: connected
              ? TextButton(onPressed: onRead, child: const Text('读取'))
              : null,
        ),
      );
}

class _ProtocolNotice extends StatelessWidget {
  const _ProtocolNotice();

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '旧协议可以读取设备统一视频列表。两套列表的归属和设置仍是草案，不会写入硬件。',
                ),
              ),
            ],
          ),
        ),
      );
}
