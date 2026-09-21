import 'dart:io';
import 'package:flutter/material.dart';

import '../../device/device_error_message.dart';
import '../../device/p20_command_session.dart';
import '../../device/p20_device_client.dart';
import 'device_playlist_draft.dart';
import 'p20_live_playlist.dart';
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
  late final P20LivePlaylist _live;
  DevicePlaylistKind get _kind => DevicePlaylistKind.values[_live.listId];
  bool _connecting = false;
  String? _connectionError;
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
            ])));
    if (!mounted || choice == null) return;
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
                setState(() {
                  _pending[kind]!.remove(key);
                });
                await _savePending(kind);
                await _live.refresh();
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
                  '设备中的文件只有文件名，无法直接恢复原始画面。请从手机选择对应的原始视频，再调整画面。保存只记录取景参数；转码上传会新增设备文件，保留原有文件。'),
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

  @override
  void initState() {
    super.initState();
    _live = P20LivePlaylist(widget.client, widget.session,
        listId: widget.initialKind.index);
    _live.addListener(_changed);
    _restorePending();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _connect() async {
    if (_connecting) return;
    setState(() {
      _connecting = true;
      _connectionError = null;
    });
    try {
      await widget.client.connect();
    } catch (error) {
      if (mounted) {
        setState(() => _connectionError = friendlyDeviceConnectionError(error));
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  String _modeName(P20PlayMode mode) => switch (mode) {
        P20PlayMode.singleLoop => '单曲循环',
        P20PlayMode.sequenceLoop => '顺序循环',
        P20PlayMode.randomLoop => '随机循环',
        P20PlayMode.singleOnce => '单次播放',
      };
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('设备播放列表'), actions: [
          IconButton(
              tooltip: '刷新设备列表',
              onPressed: _live.connected && !_live.loading && !_live.busy
                  ? _live.refresh
                  : null,
              icon: const Icon(Icons.refresh)),
        ]),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              SegmentedButton<DevicePlaylistKind>(
                segments: const [
                  ButtonSegment(
                      value: DevicePlaylistKind.startup, label: Text('A 日常播放')),
                  ButtonSegment(
                      value: DevicePlaylistKind.bluetooth,
                      label: Text('B 蓝牙播放')),
                ],
                selected: {_kind},
                onSelectionChanged: _live.busy
                    ? null
                    : (value) => _live.selectList(value.single.index),
              ),
              const SizedBox(height: 12),
              if (!_live.connected) ...[
                const Text('连接设备后显示机器内的播放列表'),
                const Text('手机先连接产品 Wi-Fi，再点击连接设备。'),
                FilledButton.icon(
                    onPressed: _connecting ? null : _connect,
                    icon: const Icon(Icons.wifi),
                    label: Text(_connecting ? '连接中…' : '连接设备')),
              ] else ...[
                Text(_live.loading
                    ? '正在读取设备列表…'
                    : _live.loaded
                        ? '设备已连接 · ${_live.videos.length} 个视频'
                        : '设备列表读取失败'),
                if (_live.loading || _live.busy)
                  const LinearProgressIndicator(),
                const SizedBox(height: 12),
                DropdownButtonFormField<P20PlayMode>(
                  key:
                      ValueKey('${_live.listId}:${_live.mode}:${_live.loaded}'),
                  initialValue: _live.mode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: '设备播放方式（A/B 共用）',
                      border: OutlineInputBorder()),
                  items: [
                    for (final mode in P20PlayMode.values)
                      DropdownMenuItem(
                          value: mode, child: Text(_modeName(mode)))
                  ],
                  onChanged: _live.canEdit
                      ? (value) {
                          if (value != null) _live.setMode(value);
                        }
                      : null,
                ),
                const SizedBox(height: 12),
                const Text('播放顺序来自设备。上移或下移后立即下发，并重新读取确认。'),
                if (_live.loaded && _live.videos.isEmpty)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('设备当前列表为空')),
                for (var index = 0; index < _live.videos.length; index++)
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${index + 1}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium),
                                Text(_live.videos[index].fileName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                Wrap(spacing: 8, children: [
                                  OutlinedButton.icon(
                                      onPressed: _live.canEdit
                                          ? () => _live.play(
                                              _live.videos[index].fileName)
                                          : null,
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text('播放')),
                                  OutlinedButton.icon(
                                      onPressed: _live.canEdit && index > 0
                                          ? () => _live.move(index, index - 1)
                                          : null,
                                      icon: const Icon(Icons.arrow_upward),
                                      label: const Text('上移')),
                                  OutlinedButton.icon(
                                      onPressed: _live.canEdit &&
                                              index + 1 < _live.videos.length
                                          ? () => _live.move(index, index + 1)
                                          : null,
                                      icon: const Icon(Icons.arrow_downward),
                                      label: const Text('下移')),
                                  TextButton.icon(
                                      onPressed: _live.canEdit
                                          ? () => _adjustDeviceVideo(
                                              _live.videos[index].fileName)
                                          : null,
                                      icon: const Icon(Icons.crop),
                                      label: const Text('调整画面')),
                                ]),
                              ]))),
              ],
              if (_live.error != null) Text(_live.error!),
              if (_connectionError != null) Text(_connectionError!),
              const SizedBox(height: 20),
              Row(children: [
                const Expanded(child: Text('手机待上传视频')),
                IconButton(
                    tooltip: '添加视频',
                    onPressed: _pendingReady && !_live.busy ? _addVideo : null,
                    icon: const Icon(Icons.playlist_add)),
              ]),
              const Text('以下是手机待上传记录，不代表设备中已有内容。'),
              if (_pendingLoadFailed)
                TextButton(
                    onPressed: _restorePending,
                    child: const Text('待处理列表读取失败，点击重试')),
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
            ]),
      );
  @override
  void dispose() {
    _live.removeListener(_changed);
    _live.dispose();
    super.dispose();
  }
}
