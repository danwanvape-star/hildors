import 'package:flutter/material.dart';
import '../video/character_package_picker.dart';
import 'owned_package_download.dart';
import 'remote_catalog_repository.dart';

class OwnedDownloadButton extends StatelessWidget {
  const OwnedDownloadButton({super.key, required this.package, this.clip});
  final RemoteCatalogPackage package;
  final RemoteCatalogClip? clip;
  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
        icon: const Icon(Icons.download_for_offline_outlined),
        label: const Text('下载到我的角色'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => OwnedDownloadPage(package: package, clip: clip))),
      );
}

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
        appBar: AppBar(title: const Text('下载到我的角色')),
        body: AnimatedBuilder(
            animation: task,
            builder: (context, _) {
              final clips =
                  widget.clip == null ? widget.package.clips : [widget.clip!];
              final remaining =
                  clips.where((c) => !task.completed.contains(c.id)).toList();
              return ListView(padding: const EdgeInsets.all(16), children: [
                Text(widget.package.title,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(widget.package.credit),
                const SizedBox(height: 8),
                const Text('仅已领取或购买的内容可下载。下载后可在“我的角色”离线查看。'),
                const SizedBox(height: 12),
                Text(
                    '已下载 ${task.completed.length}/${widget.package.clips.length}'),
                if (task.preparing) const LinearProgressIndicator(),
                if (task.busy) ...[
                  Text('正在下载：${task.activeTitle}'),
                  LinearProgressIndicator(
                      value: task.total > 0
                          ? (task.received / task.total).clamp(0, 1)
                          : null),
                  TextButton(onPressed: task.cancel, child: const Text('取消下载')),
                ],
                if (task.message.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(task.message)),
                if (clips.length > 1)
                  FilledButton(
                      onPressed: task.busy ||
                              task.preparing ||
                              remaining.isEmpty ||
                              remaining.any((c) => !task.allowed.contains(c.id))
                          ? null
                          : () => task.download(remaining),
                      child: const Text('全部下载')),
                for (final clip in clips)
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(clip.title),
                                if (task.completed.contains(clip.id))
                                  const Text('已下载')
                                else
                                  OutlinedButton(
                                      onPressed: task.busy ||
                                              task.preparing ||
                                              !task.allowed.contains(clip.id)
                                          ? null
                                          : () => task.download([clip]),
                                      child: const Text('下载视频')),
                              ]))),
                if (!task.busy && !task.preparing)
                  TextButton(
                      onPressed: task.prepare, child: const Text('刷新下载权限')),
                if (task.completed.isNotEmpty)
                  FilledButton.tonal(
                      onPressed: task.busy
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => const CharacterPackagePicker(
                                      picking: false))),
                      child: const Text('查看我的角色')),
              ]);
            }),
      );
}
