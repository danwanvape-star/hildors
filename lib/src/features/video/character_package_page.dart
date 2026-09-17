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
  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('删除本地下载？'),
                content: const Text('删除此角色包的 App 本地下载文件。云端权益会保留，需要时可重新下载。'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('删除'))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => _removing = true);
    try {
      await widget.removeDownload!();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _removing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('删除失败，请重试')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.package.title), actions: [
          if (widget.removeDownload != null)
            IconButton(
                tooltip: '删除本地下载',
                onPressed: _removing ? null : _remove,
                icon: const Icon(Icons.delete_outline))
        ]),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text('角色视频包 · ${widget.package.videos.length} 个视频'),
          if (widget.package.downloaded)
            Text(
                '已下载 ${widget.package.videos.length}/${widget.package.totalVideos ?? widget.package.videos.length} 个视频'),
          if (widget.package.credit.isNotEmpty) Text(widget.package.credit),
          if (widget.package.description.isNotEmpty)
            Text(widget.package.description),
          const SizedBox(height: 12),
          if (widget.package.videos.isEmpty)
            const Text('此角色暂未提供可用视频，待内容包交付后选择。'),
          for (final video in widget.package.videos)
            Card(
                child: ListTile(
              leading: video.thumbnail == null
                  ? const Icon(Icons.video_file_outlined)
                  : !video.asset
                      ? Image.file(File(video.thumbnail!),
                          width: 56,
                          height: 56,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) =>
                              const Icon(Icons.video_file_outlined))
                      : Image.asset(video.thumbnail!,
                          width: 56, height: 56, fit: BoxFit.contain),
              title: Text(video.title),
              subtitle: Text('${video.durationSeconds} 秒'),
              trailing: widget.picking
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      if (!video.asset)
                        IconButton(
                            tooltip: '预览本地视频',
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) => FanFramingPage(
                                        source: video.source,
                                        asset: video.asset))),
                            icon: const Icon(Icons.play_circle_outline)),
                      Checkbox(
                          value: selected.contains(video.id),
                          onChanged: (value) => setState(() {
                                value == true
                                    ? selected.add(video.id)
                                    : selected.remove(video.id);
                              }))
                    ])
                  : const Icon(Icons.crop),
              onTap: () {
                if (widget.picking) {
                  setState(() {
                    selected.contains(video.id)
                        ? selected.remove(video.id)
                        : selected.add(video.id);
                  });
                } else {
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => FanFramingPage(
                          source: video.source, asset: video.asset)));
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
                child: Text('添加 ${selected.length} 个视频到待处理区')),
        ]),
      );
}

class OfficialPackageLibrary extends StatelessWidget {
  const OfficialPackageLibrary({this.picking = false, super.key});
  final bool picking;
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(16), children: [
        const Text('官方示例角色包 · 选择包内视频'),
        for (final package in officialVideoPackages)
          Card(
              child: ListTile(
            title: Text(package.title),
            subtitle: Text('${package.videos.length} 个视频'),
            leading: Image.asset(package.videos.first.thumbnail!,
                width: 56, height: 56, fit: BoxFit.contain),
            trailing: const Icon(Icons.chevron_right),
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
