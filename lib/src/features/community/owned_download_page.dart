import '../../localization/localization.dart';
import '../../config/launch_config.dart';
import 'catalog_localization.dart';
import 'package:flutter/material.dart';
import '../video/character_package_picker.dart';
import 'owned_package_download.dart';
import 'remote_catalog_repository.dart';

class OwnedDownloadButton extends StatelessWidget {
  const OwnedDownloadButton({super.key, required this.package, this.clip});
  final RemoteCatalogPackage package;
  final RemoteCatalogClip? clip;
  RemoteCatalogClip? get effectiveClip =>
      clip ??
      (package.format == 'single' && package.clips.length == 1
          ? package.clips.single
          : null);
  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
        icon: Icon(Icons.download_for_offline_outlined),
        label: Text(downloadLabel(context, effectiveClip)),
        onPressed: LaunchConfig.usFree && effectiveClip?.pricing?.isPaid == true ? null : () {
          if (effectiveClip?.pricing?.isPaid == true) {
            _purchaseUnavailable(context);
            return;
          }
          Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => OwnedDownloadPage(package: package, clip: clip)));
        },
      );
}

void _purchaseUnavailable(BuildContext context) => ScaffoldMessenger.of(context)
    .showSnackBar(SnackBar(content: Text(context.l10n.downloadUnavailable)));

class OwnedDownloadPage extends StatefulWidget {
  const OwnedDownloadPage(
      {super.key, required this.package, this.clip, this.controller});
  final RemoteCatalogPackage package;
  final RemoteCatalogClip? clip;
  final OwnedPackageDownloadController? controller;
  @override
  State<OwnedDownloadPage> createState() => _OwnedDownloadPageState();
}

class _OwnedDownloadPageState extends State<OwnedDownloadPage> {
  late final task = widget.controller ??
      OwnedPackageDownloadController.configured(widget.package);
  @override
  void initState() {
    super.initState();
    task.prepare();
  }

  @override
  void dispose() {
    task.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.downloadTitle)),
        body: AnimatedBuilder(
            animation: task,
            builder: (context, _) {
              final clips =
                  widget.clip == null ? widget.package.clips : [widget.clip!];
              final remaining = clips
                  .where((c) =>
                      !task.completed.contains(c.id) &&
                      task.allowed.contains(c.id) &&
                      c.pricing?.isPaid != true)
                  .toList();
              return ListView(padding: EdgeInsets.all(16), children: [
                Text(widget.package.title,
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 8),
                Text(catalogCredit(context, widget.package)),
                SizedBox(height: 8),
                Text(context.l10n.downloadInfo),
                SizedBox(height: 12),
                Text(
                    context.l10n.downloadProgress(task.completed.length, widget.package.clips.length)),
                if (task.preparing) LinearProgressIndicator(),
                if (task.busy) ...[
                  Text(context.l10n.downloadActive(task.activeTitle)),
                  LinearProgressIndicator(
                      value: task.total > 0
                          ? (task.received / task.total).clamp(0, 1)
                          : null),
                  TextButton(onPressed: task.cancel, child: Text(context.l10n.downloadCancel)),
                ],
                if (task.message.isNotEmpty)
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(downloadMessage(context, task.message))),
                if (clips.length > 1)
                  FilledButton(
                      onPressed:
                          task.busy || task.preparing || remaining.isEmpty
                              ? null
                              : () => task.download(remaining),
                      child: Text(context.l10n.downloadAvailable)),
                for (final clip in clips)
                  Card(
                      child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(clip.title),
                                if (task.completed.contains(clip.id))
                                  Text(context.l10n.downloadDone)
                                else
                                  OutlinedButton(
                                      onPressed: (LaunchConfig.usFree && clip.pricing?.isPaid == true) || task.busy ||
                                              task.preparing ||
                                              (clip.pricing?.isPaid != true &&
                                                  !task.allowed
                                                      .contains(clip.id))
                                          ? null
                                          : () => clip.pricing?.isPaid == true
                                              ? _purchaseUnavailable(context)
                                              : task.download([clip]),
                                      child: Text(downloadLabel(context, clip))),
                              ]))),
                if (!task.busy && !task.preparing)
                  TextButton(
                      onPressed: task.prepare, child: Text(context.l10n.downloadRefresh)),
                if (task.completed.isNotEmpty)
                  FilledButton.tonal(
                      onPressed: task.busy
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => CharacterPackagePicker(
                                      picking: false))),
                      child: Text(context.l10n.downloadView)),
              ]);
            }),
      );
}
