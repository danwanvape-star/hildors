import '../../localization/localization.dart';
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
      if (mounted) setState(() => _message = 'DEVICE_REQUEST_FAILED');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _play(P20VideoEntry video) async {
    try {
      await widget.session.playVideo(video.fileName);
      if (mounted) setState(() => _playingIndex = video.index);
    } catch (error) {
      if (mounted) setState(() => _message = 'DEVICE_REQUEST_FAILED');
    }
  }

  Future<void> _delete(P20VideoEntry video) async {
    if (_playingIndex == video.index) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.devicePlayingDelete)),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error),
        title: Text(context.l10n.deviceDeleteTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.deviceDeleteIntro),
            SizedBox(height: 10),
            SelectableText(video.fileName,
                style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 12),
            Text(
              context.l10n.deviceDeleteNote,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.deviceCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.deviceDelete),
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
          SnackBar(content: Text(context.l10n.deviceDeleted(video.fileName))),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _message = 'DEVICE_REQUEST_FAILED');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.deviceVideoLibrary),
        actions: [
          IconButton(
            onPressed: _connected && !_loading ? _refresh : null,
            tooltip: context.l10n.deviceRefresh,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: !_connected
          ? Center(child: Text(context.l10n.deviceConnectFirst))
          : _loading
              ? Center(child: CircularProgressIndicator())
              : _videos.isEmpty
                  ? Center(
                      child: FilledButton.icon(
                        onPressed: _refresh,
                        icon: Icon(Icons.sync),
                        label: Text(context.l10n.deviceReadVideos),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.all(16),
                      itemCount: _videos.length + (_message == null ? 0 : 1),
                      separatorBuilder: (_, __) => SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (_message != null && index == 0) {
                          return Card(
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(context.l10n.errorNetwork),
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
                                ? Text(context.l10n.devicePlaying)
                                : null,
                            trailing: Wrap(
                              children: [
                                IconButton(
                                  onPressed: () => _play(video),
                                  tooltip: context.l10n.devicePlay,
                                  icon: Icon(Icons.play_arrow),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: context.l10n.deviceMore,
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
                                          SizedBox(width: 10),
                                          Text(context.l10n.deviceDeleteFrom,
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
