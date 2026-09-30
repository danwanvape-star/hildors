import 'upload_name_dialog.dart';
import 'playlist_management_page.dart';
import 'device_playlist_draft.dart';
import '../../device/device_access.dart';
import 'p20_media_upload_flow.dart';
import 'p20_upload_page.dart';
import '../../localization/localization.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'character_video_package.dart';
import 'fan_framing_page.dart';

class CharacterPackagePage extends StatefulWidget {
  const CharacterPackagePage(
      {required this.package,
      this.picking = false,
      this.removeDownload,
      super.key});
  final Future<void> Function()? removeDownload;
  final CharacterVideoPackage package;
  final bool picking;
  @override
  State<CharacterPackagePage> createState() => _CharacterPackagePageState();
}

class _CharacterPackagePageState extends State<CharacterPackagePage> {
  final Set<String> selected = {};
  bool _removing = false;
  Future<void> _upload(String source, bool asset, String title) async {
    final device = DeviceAccess.maybeOf(context);
    if (device == null || !device.client.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.coreDeviceDisconnected)));
      return;
    }
    final originRoute = ModalRoute.of(context);
    final generation = device.client.generation;
    var list = P20MediaList.daily;
    if (device.client.profile.listCount == 2) {
      final selected = await showModalBottomSheet<P20MediaList>(
          context: context,
          builder: (context) => SafeArea(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                ListTile(title: Text(context.l10n.controlsChooseList)),
                ListTile(
                    title: Text(context.l10n.controlsStartup),
                    onTap: () => Navigator.pop(context, P20MediaList.daily)),
                ListTile(
                    title: Text(context.l10n.controlsBluetooth),
                    onTap: () =>
                        Navigator.pop(context, P20MediaList.bluetooth)),
              ])));
      if (selected == null) return;
      list = selected;
    }
    if (!mounted || generation != device.client.generation) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => FanFramingPage(
            source: source,
            asset: asset,
            onUpload: (frameContext, framing) async {
              if (generation != device.client.generation ||
                  !device.client.isConnected) {
                ScaffoldMessenger.of(frameContext).showSnackBar(SnackBar(
                    content: Text(frameContext.l10n.coreDeviceDisconnected)));
                return;
              }
              final displayName =
                  await chooseUploadDisplayName(frameContext, title);
              if (displayName == null ||
                  !frameContext.mounted ||
                  generation != device.client.generation) {
                return;
              }
              final name = await Navigator.of(frameContext)
                  .push<String>(MaterialPageRoute(
                      builder: (_) => P20UploadPage(
                          autoStart: true,
                          displayName: displayName,
                          onReturnToList: (_) {
                            Navigator.of(frameContext).pushAndRemoveUntil(
                                MaterialPageRoute<void>(
                                    builder: (_) => PlaylistManagementPage(
                                        client: device.client,
                                        session: device.session,
                                        initialKind: list == P20MediaList.daily
                                            ? DevicePlaylistKind.startup
                                            : DevicePlaylistKind.bluetooth)),
                                (route) => identical(route, originRoute));
                          },
                          client: device.client,
                          session: device.session,
                          source: source,
                          asset: asset,
                          framing: framing,
                          list: list)));
              if (name != null && frameContext.mounted) {
                Navigator.pop(frameContext);
              }
            })));
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(context.l10n.controlsDeleteTitle),
                content: Text(context.l10n.controlsDeleteNote),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(context.l10n.controlsCancel)),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(context.l10n.controlsDelete))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => _removing = true);
    try {
      await widget.removeDownload!();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _removing = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.controlsDeleteFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.package.title), actions: [
          if (widget.removeDownload != null)
            IconButton(
                tooltip: context.l10n.controlsDeleteLocal,
                onPressed: _removing ? null : _remove,
                icon: Icon(Icons.delete_outline))
        ]),
        body: ListView(padding: EdgeInsets.all(16), children: [
          Text(context.l10n.controlsPackageCount(widget.package.videos.length)),
          if (widget.package.downloaded)
            Text(context.l10n.controlsDownloaded(widget.package.videos.length,
                widget.package.totalVideos ?? widget.package.videos.length)),
          if (widget.package.credit.isNotEmpty) Text(widget.package.credit),
          if (widget.package.description.isNotEmpty)
            Text(widget.package.description),
          SizedBox(height: 12),
          if (widget.package.videos.isEmpty)
            Text(context.l10n.controlsNoVideos),
          for (final video in widget.package.videos)
            Card(
                child: ListTile(
              leading: video.thumbnail == null
                  ? Icon(Icons.video_file_outlined)
                  : !video.asset
                      ? Image.file(File(video.thumbnail!),
                          width: 56,
                          height: 56,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) =>
                              Icon(Icons.video_file_outlined))
                      : Image.asset(video.thumbnail!,
                          width: 56, height: 56, fit: BoxFit.contain),
              title: Text(video.title),
              subtitle:
                  Text(context.l10n.controlsSeconds(video.durationSeconds)),
              trailing: widget.picking
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      if (!video.asset)
                        IconButton(
                            tooltip: context.l10n.controlsPreviewLocal,
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) => FanFramingPage(
                                        source: video.source,
                                        asset: video.asset))),
                            icon: Icon(Icons.play_circle_outline)),
                      Checkbox(
                          value: selected.contains(video.id),
                          onChanged: (value) => setState(() {
                                value == true
                                    ? selected.add(video.id)
                                    : selected.remove(video.id);
                              }))
                    ])
                  : IconButton(
                      tooltip: context.l10n.p20UploadAction,
                      icon: Icon(Icons.upload),
                      onPressed: () =>
                          _upload(video.source, video.asset, video.title)),
              onTap: () {
                if (widget.picking) {
                  setState(() {
                    selected.contains(video.id)
                        ? selected.remove(video.id)
                        : selected.add(video.id);
                  });
                } else {
                  _upload(video.source, video.asset, video.title);
                }
              },
            )),
          if (widget.picking)
            FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () => Navigator.pop(
                        context,
                        widget.package.videos
                            .where((v) => selected.contains(v.id))
                            .map(
                                (v) => PackageVideoSelection(widget.package, v))
                            .toList()),
                child: Text(context.l10n.controlsAddCount(selected.length))),
        ]),
      );
}

class OfficialPackageLibrary extends StatelessWidget {
  const OfficialPackageLibrary({this.picking = false, super.key});
  final bool picking;
  @override
  Widget build(BuildContext context) =>
      ListView(padding: EdgeInsets.all(16), children: [
        Text(context.l10n.controlsExamples),
        for (final package in officialVideoPackages)
          Card(
              child: ListTile(
            title: Text(package.title),
            subtitle:
                Text(context.l10n.controlsVideoCount(package.videos.length)),
            leading: Image.asset(package.videos.first.thumbnail!,
                width: 56, height: 56, fit: BoxFit.contain),
            trailing: Icon(Icons.chevron_right),
            onTap: () async {
              final result = await Navigator.of(context)
                  .push<List<PackageVideoSelection>>(MaterialPageRoute(
                      builder: (_) => CharacterPackagePage(
                          package: package, picking: picking)));
              if (picking && result != null && context.mounted) {
                Navigator.pop(context, result);
              }
            },
          )),
      ]);
}
