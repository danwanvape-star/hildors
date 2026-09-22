import '../../localization/localization.dart';
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

  Future<void> _deleteDeviceVideo(String name) async {
    final listId = _live.listId;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(context.l10n.deviceDeleteTitle),
              content: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(context.l10n.deviceDeleteIntro),
                    Text(name),
                    Text(context.l10n.deviceDeleteAudioNote),
                    Text(context.l10n.deviceDeleteNote),
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.l10n.playlistCancel)),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(context.l10n.deviceDelete))
              ],
            ));
    if (!mounted ||
        confirmed != true ||
        listId != _live.listId ||
        !_live.canEdit) {
      return;
    }
    await _live.delete(name);
  }

  Future<void> _addVideo() async {
    if (!_pendingReady) return;
    final target = _kind;
    final choice = await showModalBottomSheet<int>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  title: Text(context.l10n.playlistFromCharacters),
                  subtitle: Text(context.l10n.playlistChooseCharacter),
                  onTap: () => Navigator.pop(context, 0)),
              ListTile(
                  title: Text(context.l10n.playlistFromPhone),
                  onTap: () => Navigator.pop(context, 1)),
            ])));
    if (!mounted || choice == null) return;
    try {
      if (choice == 0) {
        final videos = await Navigator.of(context)
            .push<List<PackageVideoSelection>>(
                MaterialPageRoute(builder: (_) => CharacterPackagePicker()));
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
            type: FileType.custom, allowedExtensions: ['mp4', 'mov', 'm4v']);
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.playlistPickFailed)));
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
          content: Text(context.l10n.playlistPendingSaveFailed),
          action: SnackBarAction(
              label: context.l10n.playlistRetry,
              onPressed: () => _savePending(kind)),
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
                  title: Text(context.l10n.playlistReselectTitle),
                  content: Text(context.l10n.playlistReselectNote),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(context.l10n.playlistCancel)),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(context.l10n.playlistReselect))
                  ],
                ));
        if (reselect != true || !mounted) return;
        final picked = await FilePicker.pickFile(
            type: FileType.custom, allowedExtensions: ['mp4', 'mov', 'm4v']);
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.playlistReadFailed)));
      }
    }
  }

  Future<void> _adjustDeviceVideo(String fileName) async {
    final kind = _kind;
    final selectSource = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(context.l10n.playlistOriginalTitle),
              content: Text(context.l10n.playlistOriginalNote),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.l10n.playlistCancel)),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(context.l10n.playlistChooseOriginal)),
              ],
            ));
    if (selectSource != true || !mounted) return;
    try {
      final picked = await FilePicker.pickFile(
          type: FileType.custom, allowedExtensions: ['mp4', 'mov', 'm4v']);
      if (!mounted || picked?.path == null) return;
      final video = (
        title: context.l10n.playlistSourceTitle(fileName),
        source: picked!.path!,
        asset: false
      );
      final key = 'device-source:${kind.name}:$fileName';
      setState(() => _pending[kind]![key] = video);
      await _savePending(kind);
      if (!mounted) return;
      await _openPending(kind, key, video);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.playlistOriginalFailed)));
      }
    }
  }

  Future<void> _removePending(DevicePlaylistKind kind, String key) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(context.l10n.playlistRemovePending),
              content: Text(context.l10n.playlistRemovePendingNote),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.l10n.playlistCancel)),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(context.l10n.playlistRemove))
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
        P20PlayMode.singleLoop => context.l10n.playlistSingleLoop,
        P20PlayMode.sequenceLoop => context.l10n.coreSequenceLoop,
        P20PlayMode.randomLoop => context.l10n.coreRandomLoop,
        P20PlayMode.singleOnce => context.l10n.p20SingleOnce,
      };
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(
                  60 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2.5)),
              child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                          onPressed:
                              _pendingReady && !_live.busy ? _addVideo : null,
                          icon: Icon(Icons.playlist_add),
                          label: Text(context.l10n.submissionAddVideo)))),
            ),
            title: Text(context.l10n.playlistTitle),
            actions: [
              IconButton(
                  tooltip: context.l10n.p20Refresh,
                  onPressed: _live.connected && !_live.loading && !_live.busy
                      ? _live.refresh
                      : null,
                  icon: Icon(Icons.refresh)),
            ]),
        body: LayoutBuilder(
            builder: (context, constraints) => Column(children: [
                  ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight * 0.55),
                      child: SingleChildScrollView(
                          child: Padding(
                              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SegmentedButton<DevicePlaylistKind>(
                                      segments: [
                                        ButtonSegment(
                                            value: DevicePlaylistKind.startup,
                                            label: Text(context.l10n.p20Daily)),
                                        ButtonSegment(
                                            value: DevicePlaylistKind.bluetooth,
                                            label: Text(
                                                context.l10n.p20Bluetooth)),
                                      ],
                                      selected: {_kind},
                                      onSelectionChanged: _live.busy
                                          ? null
                                          : (value) => _live
                                              .selectList(value.single.index),
                                    ),
                                    SizedBox(height: 12),
                                    if (!_live.connected) ...[
                                      Text(context.l10n.p20ConnectNote),
                                      Text(context.l10n.p20ConnectWifi),
                                      FilledButton.icon(
                                          onPressed:
                                              _connecting ? null : _connect,
                                          icon: Icon(Icons.wifi),
                                          label: Text(_connecting
                                              ? context.l10n.p20Connecting
                                              : context.l10n.p20Connect)),
                                    ] else ...[
                                      Text(_live.loading
                                          ? context.l10n.p20Reading
                                          : _live.loaded
                                              ? context.l10n.p20ConnectedCount(
                                                  _live.videos.length)
                                              : context.l10n.p20ReadFailed),
                                      if (_live.loading || _live.busy)
                                        LinearProgressIndicator(),
                                      SizedBox(height: 12),
                                      DropdownButtonFormField<P20PlayMode>(
                                        key: ValueKey(
                                            '${_live.listId}:${_live.mode}:${_live.loaded}'),
                                        initialValue: _live.mode,
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                            labelText: context.l10n.p20Mode,
                                            border: OutlineInputBorder()),
                                        items: [
                                          for (final mode in P20PlayMode.values)
                                            DropdownMenuItem(
                                                value: mode,
                                                child: Text(_modeName(mode)))
                                        ],
                                        onChanged: _live.canEdit
                                            ? (value) {
                                                if (value != null) {
                                                  _live.setMode(value);
                                                }
                                              }
                                            : null,
                                      ),
                                      SizedBox(height: 12),
                                    ],
                                  ])))),
                  Expanded(
                      child: ListView(
                          padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                          children: [
                        if (_live.connected) ...[
                          Tooltip(
                              message: context.l10n.p20OrderNote,
                              child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Icon(Icons.info_outline, size: 18))),
                          if (_live.loaded && _live.videos.isEmpty)
                            Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text(context.l10n.p20Empty)),
                          for (var index = 0;
                              index < _live.videos.length;
                              index++)
                            Card(
                                child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    child: Column(children: [
                                      Row(children: [
                                        Text((index + 1).toString()),
                                        SizedBox(width: 8),
                                        Expanded(
                                            child: Tooltip(
                                                message: _live
                                                    .videos[index].fileName,
                                                child: Text(
                                                    _live
                                                        .videos[index].fileName,
                                                    maxLines: 1,
                                                    overflow: TextOverflow
                                                        .ellipsis))),
                                        IconButton(
                                            tooltip: context.l10n.devicePlay,
                                            onPressed: _live.canEdit
                                                ? () => _live.play(_live
                                                    .videos[index].fileName)
                                                : null,
                                            icon: Icon(Icons.play_arrow)),
                                      ]),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            IconButton(
                                                tooltip:
                                                    context.l10n.playlistUp,
                                                onPressed:
                                                    _live.canEdit && index > 0
                                                        ? () => _live.move(
                                                            index, index - 1)
                                                        : null,
                                                icon: Icon(Icons.arrow_upward)),
                                            IconButton(
                                                tooltip:
                                                    context.l10n.playlistDown,
                                                onPressed: _live.canEdit &&
                                                        index + 1 <
                                                            _live.videos.length
                                                    ? () => _live.move(
                                                        index, index + 1)
                                                    : null,
                                                icon:
                                                    Icon(Icons.arrow_downward)),
                                            IconButton(
                                                tooltip:
                                                    context.l10n.playlistFrame,
                                                onPressed: _live.canEdit
                                                    ? () => _adjustDeviceVideo(
                                                        _live.videos[index]
                                                            .fileName)
                                                    : null,
                                                icon: Icon(Icons.crop)),
                                            IconButton(
                                                tooltip: context
                                                    .l10n.deviceDeleteFrom,
                                                onPressed: _live.canEdit
                                                    ? () => _deleteDeviceVideo(
                                                        _live.videos[index]
                                                            .fileName)
                                                    : null,
                                                icon:
                                                    Icon(Icons.delete_outline)),
                                          ]),
                                    ]))),
                        ],
                        if (_live.error != null)
                          Text(_live.error == 'operation_unconfirmed'
                              ? context.l10n.p20Unconfirmed
                              : context.l10n.errorNetwork),
                        if (_connectionError != null)
                          Text(context.l10n.errorNetwork),
                        SizedBox(height: 20),
                        Text(context.l10n.p20Pending),
                        Text(context.l10n.p20PendingNote),
                        if (_pendingLoadFailed)
                          TextButton(
                              onPressed: _restorePending,
                              child:
                                  Text(context.l10n.playlistPendingLoadFailed)),
                        for (final entry in _pending[_kind]!.entries)
                          Card(
                              child: ListTile(
                            leading: Icon(Icons.hourglass_empty),
                            title: Text(entry.value.title),
                            subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(context.l10n.playlistConvertPending),
                                  TextButton.icon(
                                      onPressed: () => _openPending(
                                          _kind, entry.key, entry.value),
                                      icon: Icon(Icons.crop, size: 18),
                                      label: Text(context.l10n.playlistFrame)),
                                ]),
                            trailing: IconButton(
                                tooltip:
                                    context.l10n.playlistRemovePendingAction,
                                icon: Icon(Icons.close),
                                onPressed: () =>
                                    _removePending(_kind, entry.key)),
                            onTap: () =>
                                _openPending(_kind, entry.key, entry.value),
                          )),
                      ])),
                ])),
      );
  @override
  void dispose() {
    _live.removeListener(_changed);
    _live.dispose();
    super.dispose();
  }
}
