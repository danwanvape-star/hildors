import 'dart:async';

import 'package:flutter/material.dart';

import '../../device/p20_command_session.dart';
import '../../device/p20_device_client.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({required this.client, required this.session, super.key});

  final P20DeviceClient client;
  final P20CommandSession session;

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  StreamSubscription<DeviceConnectionState>? _connectionSubscription;
  DeviceConnectionState _connection = DeviceConnectionState.disconnected;
  List<P20VideoEntry> _videos = const [];
  int? _playingIndex;
  bool _loading = false;
  String? _message;

  bool get _connected => _connection == DeviceConnectionState.connected;

  @override
  void initState() {
    super.initState();
    _connectionSubscription = widget.client.connectionStates.listen((value) {
      if (mounted) setState(() => _connection = value);
    });
  }

  Future<void> _refresh() async {
    if (!_connected || _loading) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final videos = await widget.session.queryVideos();
      final current = await widget.session.queryCurrentVideo();
      if (mounted) {
        setState(() {
          _videos = videos;
          _playingIndex = current.playing ? current.index : null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _play(P20VideoEntry video) async {
    try {
      await widget.session.playVideo(video.fileName);
      if (mounted) setState(() => _playingIndex = video.index);
    } catch (error) {
      if (mounted) setState(() => _message = '$error');
    }
  }

  Future<void> _delete(P20VideoEntry video) async {
    if (_playingIndex == video.index) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在播放的视频不能删除，请先播放其他内容')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error),
        title: const Text('永久删除设备文件？'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('以下视频将从全息设备中永久删除：'),
            const SizedBox(height: 10),
            SelectableText(video.fileName,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(
              '此操作无法撤销。手机中已下载的副本和内容购买记录不会受到影响。',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('永久删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.session.deleteVideo(video.fileName);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已从设备永久删除 ${video.fileName}')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _message = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视频库'),
        actions: [
          IconButton(
            onPressed: _connected && !_loading ? _refresh : null,
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: !_connected
          ? const Center(child: Text('请先在“控制”页连接设备'))
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _videos.isEmpty
                  ? Center(
                      child: FilledButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.sync),
                        label: const Text('读取视频列表'),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _videos.length + (_message == null ? 0 : 1),
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (_message != null && index == 0) {
                          return Card(
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(_message!),
                            ),
                          );
                        }
                        final offset = _message == null ? index : index - 1;
                        final video = _videos[offset];
                        return Card(
                          child: ListTile(
                            leading:
                                CircleAvatar(child: Text('${video.index + 1}')),
                            title: Text(video.fileName),
                            subtitle: _playingIndex == video.index
                                ? const Text('正在播放')
                                : null,
                            trailing: Wrap(
                              children: [
                                IconButton(
                                  onPressed: () => _play(video),
                                  tooltip: '播放',
                                  icon: const Icon(Icons.play_arrow),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: '更多操作',
                                  onSelected: (value) {
                                    if (value == 'delete') _delete(video);
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_forever_outlined,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error),
                                          const SizedBox(width: 10),
                                          Text('从设备永久删除',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .error)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
