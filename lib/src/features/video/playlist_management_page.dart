import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../../device/device_error_message.dart';
import '../../device/p20_command_session.dart';
import '../../device/p20_device_client.dart';
import 'device_playlist_draft.dart';
import 'playlist_store.dart';
import 'package:file_picker/file_picker.dart';
import 'character_video_package.dart';
import 'character_package_picker.dart';
import 'fan_framing_page.dart';
import 'pending_playlist_store.dart';
import 'p20_upload_page.dart';
import 'p20_media_upload_flow.dart';

bool _isNetworkVideoSource(String source) {
  final scheme = Uri.tryParse(source)?.scheme.toLowerCase();
  return scheme == 'http' || scheme == 'https';
}

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
  String? _playingFileName;
  bool _pendingReady = false;
  bool _pendingLoadFailed = false;
  final _pending = <DevicePlaylistKind, Map<String, PendingVideo>>{
    DevicePlaylistKind.startup: {},
    DevicePlaylistKind.bluetooth: {},
  };

  Future<void> _addVideo() async {
    if (!_pendingReady) return;
    final target = _kind;
    final choice = await showModalBottomSheet<int>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  title: const Text('从我的角色选择'),
                  subtitle: const Text('选择已收藏角色中的视频'),
                  onTap: () => Navigator.pop(context, 0)),
              ListTile(
                  title: const Text('从手机导入视频'),
                  onTap: () => Navigator.pop(context, 1)),
              ListTile(
                  title: const Text('从设备已有视频添加'),
                  enabled: _connected,
                  onTap: _connected ? () => Navigator.pop(context, 2) : null),
            ])));
    if (!mounted || choice == null) return;
    if (choice == 2) {
      await _showDeviceVideoPicker();
      return;
    }
    try {
      if (choice == 0) {
        final videos = await Navigator.of(context).push<
                List<PackageVideoSelection>>(
            MaterialPageRoute(builder: (_) => const CharacterPackagePicker()));
        if (!mounted || videos == null) return;
        setState(() {
          for (final entry in videos) {
            _pending[target]![entry.key] = (
              title: '${entry.package.title} · ${entry.video.title}',
              source: entry.video.source,
              asset: entry.video.asset
            );
          }
        });
        await _savePending(target);
        if (videos.length == 1 && mounted) {
          await _openPending(
              target, videos.single.key, _pending[target]![videos.single.key]!);
        }
      } else {
        final picked = await FilePicker.pickFile(
            type: FileType.custom,
            allowedExtensions: const ['mp4', 'mov', 'm4v']);
        if (!mounted || picked?.path == null) return;
        setState(() => _pending[target]![picked!.path!] =
            (title: picked.name, source: picked.path!, asset: false));
        await _savePending(target);
        if (!mounted) return;
        await _openPending(
            target, picked!.path!, _pending[target]![picked.path!]!);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('视频选择失败，请重试')));
      }
    }
  }

  Future<void> _restorePending() async {
    try {
      final startup =
          await PendingPlaylistStore.load(DevicePlaylistKind.startup);
      final bluetooth =
          await PendingPlaylistStore.load(DevicePlaylistKind.bluetooth);
      if (!mounted) return;
      setState(() {
        _pending[DevicePlaylistKind.startup] = startup;
        _pending[DevicePlaylistKind.bluetooth] = bluetooth;
        _pendingReady = true;
        _pendingLoadFailed = false;
      });
    } catch (_) {
      if (mounted) setState(() => _pendingLoadFailed = true);
    }
  }

  Future<void> _savePending(DevicePlaylistKind kind) async {
    try {
      await PendingPlaylistStore.save(kind, _pending[kind]!);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('待处理列表保存失败，退出后可能丢失，请重试'),
          action:
              SnackBarAction(label: '重试', onPressed: () => _savePending(kind)),
        ));
      }
    }
  }

  Future<void> _openPending(
      DevicePlaylistKind kind, String key, PendingVideo video) async {
    try {
      if (!video.asset &&
          !_isNetworkVideoSource(video.source) &&
          !await File(video.source).exists()) {
        if (!mounted) return;
        final reselect = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('需要重新选择源视频'),
                  content: const Text('原文件已移动或系统缓存已清理。列表记录仍保留，请选择对应视频并重新确认取景。'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('重新选择'))
                  ],
                ));
        if (reselect != true || !mounted) return;
        final picked = await FilePicker.pickFile(
            type: FileType.custom,
            allowedExtensions: const ['mp4', 'mov', 'm4v']);
        if (!mounted || picked?.path == null) return;
        video = (title: picked!.name, source: picked.path!, asset: false);
        final replacement = video;
        setState(() => _pending[kind]![key] = replacement);
        await _savePending(kind);
      }
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => FanFramingPage(
              source: video.source,
              asset: video.asset,
              onUpload: (framingContext, framing) async {
                final name = await Navigator.of(framingContext).push<String>(
                    MaterialPageRoute(
                        builder: (_) => P20UploadPage(
                            client: widget.client,
                            session: widget.session,
                            source: video.source,
                            asset: video.asset,
                            framing: framing,
                            list: kind == DevicePlaylistKind.startup
                                ? P20MediaList.daily
                                : P20MediaList.bluetooth)));
                if (name == null || !mounted) return;
                final draft =
                    (kind == DevicePlaylistKind.startup ? _startup : _bluetooth)
                        .add(name);
                setState(() {
                  if (kind == DevicePlaylistKind.startup) {
                    _startup = draft;
                  } else {
                    _bluetooth = draft;
                  }
                  _pending[kind]!.remove(key);
                  _deviceVideos = const [];
                });
                await _saveList(draft);
                await _savePending(kind);
                if (framingContext.mounted) Navigator.pop(framingContext);
              })));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('无法读取视频，请稍后重试')));
      }
    }
  }

  Future<void> _adjustDeviceVideo(String fileName) async {
    final kind = _kind;
    final selectSource = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('需要原始视频'),
              content: const Text(
                  '设备中的文件只有文件名，无法直接恢复原始画面。请从手机选择对应的原始视频，再调整画面。保存只记录取景参数，不会转码、上传或覆盖设备文件。'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('选择原始视频')),
              ],
            ));
    if (selectSource != true || !mounted) return;
    try {
      final picked = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: const ['mp4', 'mov', 'm4v']);
      if (!mounted || picked?.path == null) return;
      final video =
          (title: '$fileName · 原始视频取景', source: picked!.path!, asset: false);
      final key = 'device-source:${kind.name}:$fileName';
      setState(() => _pending[kind]![key] = video);
      await _savePending(kind);
      if (!mounted) return;
      await _openPending(kind, key, video);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('无法读取原始视频，请稍后重试')));
      }
    }
  }

  Future<void> _removePending(DevicePlaylistKind kind, String key) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('移除待处理视频？'),
              content: const Text('只移除本列表记录，不删除手机源文件或设备视频。'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('移除'))
              ],
            ));
    if (!mounted || confirmed != true) return;
    setState(() => _pending[kind]!.remove(key));
    await _savePending(kind);
  }

  late var _startup = const DevicePlaylistDraft(
    kind: DevicePlaylistKind.startup,
    enabled: true,
    loopMode: PlaylistLoopMode.listLoop,
    videoNames: ['showcase_01.mp4', 'showcase_02.mp4'],
  );
  late var _bluetooth = const DevicePlaylistDraft(
    kind: DevicePlaylistKind.bluetooth,
    enabled: true,
    loopMode: PlaylistLoopMode.listLoop,
    videoNames: ['showcase_03.mp4', 'showcase_04.mp4'],
  );

  bool get _connected => _connection == DeviceConnectionState.connected;
  DevicePlaylistDraft get _draft =>
      _kind == DevicePlaylistKind.startup ? _startup : _bluetooth;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    _connection = widget.client.connectionState;
    _restoreLists();
    _restorePending();
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
    _saveList(value);
  }

  Future<void> _restoreLists() async {
    try {
      final startup = await PlaylistStore.load(_startup);
      final bluetooth = await PlaylistStore.load(_bluetooth);
      if (mounted) {
        setState(() {
          _startup = startup;
          _bluetooth = bluetooth;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = '本机列表读取失败，请重试');
    }
  }

  Future<void> _saveList(DevicePlaylistDraft draft) async {
    try {
      await PlaylistStore.save(draft);
    } catch (_) {
      if (mounted) setState(() => _error = '本机列表保存失败，请重试');
    }
  }

  Future<void> _readDeviceVideos() async {
    if (!_connected || _loading) return;
    final kind = _kind;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final videos = await widget.session.queryVideos(listId: kind.index);
      if (mounted && _kind == kind) setState(() => _deviceVideos = videos);
    } catch (error) {
      if (mounted) {
        setState(() => _error = friendlyDeviceConnectionError(error));
      }
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

  Future<void> _playOnDevice(String fileName) async {
    final kind = _kind;
    if (!_connected) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('请先连接设备后再播放')));
      return;
    }
    if (_playingFileName != null) return;
    setState(() => _playingFileName = fileName);
    try {
      final available = await widget.session.queryVideos(listId: kind.index);
      if (!available.any((video) => video.fileName == fileName)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('设备中没有此视频，请完成转码和上传后再播放')));
        }
        return;
      }
      await widget.session.playVideo(fileName, listId: kind.index);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('已发送到设备播放：$fileName')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(friendlyDeviceConnectionError(error))),
        );
    } finally {
      if (mounted) setState(() => _playingFileName = null);
    }
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
              _saveList(previous);
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
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
              onSelectionChanged: (value) => setState(() {
                _kind = value.single;
                _deviceVideos = const [];
                _error = null;
              }),
            ),
            const SizedBox(height: 10),
            _DeviceStatusBar(
              connected: _connected,
              videoCount: _deviceVideos.length,
              error: _error,
              onRead: _connected ? _readDeviceVideos : null,
            ),
            const SizedBox(height: 12),
            Text(
              _kind == DevicePlaylistKind.startup
                  ? '设备开机后自动播放此列表'
                  : '连接蓝牙后，硬件自动切换到此列表',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
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
                  tooltip: '添加视频',
                  onPressed: _pendingReady ? _addVideo : null,
                  icon: const Icon(Icons.playlist_add),
                ),
              ],
            ),
            if (_pendingLoadFailed)
              TextButton(
                  onPressed: _restorePending,
                  child: const Text('待处理列表读取失败，点击重试')),
            if (_pending[_kind]!.isNotEmpty) ...[
              const Text('待处理视频 · 尚未上传设备'),
              const Text('保留待处理记录，不复制源视频。完成取景后等待转码接入；请勿移动或删除源文件。'),
              for (final entry in _pending[_kind]!.entries)
                Card(
                    child: ListTile(
                  leading: const Icon(Icons.hourglass_empty),
                  title: Text(entry.value.title),
                  subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('待转码 · 尚未上传设备'),
                        TextButton.icon(
                            onPressed: () =>
                                _openPending(_kind, entry.key, entry.value),
                            icon: const Icon(Icons.crop, size: 18),
                            label: const Text('调整画面')),
                      ]),
                  trailing: IconButton(
                      tooltip: '移除待处理视频',
                      icon: const Icon(Icons.close),
                      onPressed: () => _removePending(_kind, entry.key)),
                  onTap: () => _openPending(_kind, entry.key, entry.value),
                )),
            ],
            if (_draft.videoNames.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('当前播放列表为空')),
              ),
            for (var index = 0; index < _draft.videoNames.length; index++)
              Card(
                child: ListTile(
                  leading: _VideoThumbnail(
                    fileName: _draft.videoNames[index],
                    index: index,
                    playing: _playingFileName == _draft.videoNames[index],
                    onPlay: () => _playOnDevice(_draft.videoNames[index]),
                  ),
                  title: Text(_draft.videoNames[index]),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (index == 0) const Text('默认首条'),
                      TextButton.icon(
                        onPressed: () =>
                            _adjustDeviceVideo(_draft.videoNames[index]),
                        icon: const Icon(Icons.crop, size: 18),
                        label: const Text('调整画面'),
                      ),
                    ],
                  ),
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

class _DeviceStatusBar extends StatelessWidget {
  const _DeviceStatusBar({
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
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Icon(
            !connected
                ? Icons.wifi_off
                : error != null
                    ? Icons.sync_problem_outlined
                    : Icons.router,
          ),
          title: Text(
            !connected
                ? '设备未连接'
                : error != null
                    ? '设备网络已连接 · 读取失败'
                    : videoCount == 0
                        ? '设备网络已连接 · 点击读取'
                        : '设备响应正常 · $videoCount 个视频',
          ),
          subtitle: Text(
            error ?? (connected ? '读取设备内容后即可确认控制通道' : '连接设备 Wi-Fi 后再读取播放列表'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: connected
              ? TextButton(
                  onPressed: onRead,
                  child: Text(error == null ? '读取' : '重试'),
                )
              : null,
        ),
      );
}

String? _demoThumbnailFor(String fileName) {
  final normalized = fileName.trim().toLowerCase();
  return switch (normalized) {
    'showcase_01.mp4' => 'assets/images/video_thumbnails/showcase_01.jpg',
    'showcase_02.mp4' => 'assets/images/video_thumbnails/showcase_02.jpg',
    'showcase_03.mp4' => 'assets/images/video_thumbnails/showcase_03.jpg',
    'showcase_04.mp4' => 'assets/images/video_thumbnails/showcase_04.jpg',
    _ => null,
  };
}

class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail({
    required this.fileName,
    required this.index,
    required this.playing,
    required this.onPlay,
  });

  final String fileName;
  final int index;
  final bool playing;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final asset = _demoThumbnailFor(fileName);
    return SizedBox(
      width: 58,
      height: 58,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (asset != null)
              Image.asset(asset, fit: BoxFit.cover)
            else
              ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.movie_outlined),
              ),
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            Center(
              child: Material(
                color: Colors.black.withValues(alpha: 0.62),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPlay,
                  child: SizedBox.square(
                    dimension: 38,
                    child: playing
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow_rounded, size: 28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
