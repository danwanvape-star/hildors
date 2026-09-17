import 'dart:io';
import 'package:flutter/material.dart';
import '../community/downloaded_character_store.dart';
import '../community/collection_catalog_page.dart';
import '../customization/character_entitlement_repository.dart';
import '../customization/customization_order_repository.dart';
import '../customization/character_gate_prototype_pages.dart'
    show characterGateCatalog;
import 'character_package_page.dart';
import 'character_video_package.dart';
import 'pending_playlist_store.dart';
import 'device_playlist_draft.dart';

/// Original/custom roles have no delivered clip manifests yet. Never synthesize
/// playable files from their character IDs or concept thumbnails.
class CharacterPackagePicker extends StatefulWidget {
  const CharacterPackagePicker(
      {this.repository,
      this.downloadedStore,
      this.loadDownloaded,
      this.saveToPlaylist,
      this.orderRepository,
      this.picking = true,
      this.embedded = false,
      super.key});
  final CharacterEntitlementRepository? repository;
  final DownloadedCharacterStore? downloadedStore;
  final Future<List<CharacterVideoPackage>> Function()? loadDownloaded;
  final CustomizationOrderRepository? orderRepository;
  final bool picking;
  final bool embedded;
  final Future<void> Function(DevicePlaylistKind, Map<String, PendingVideo>)?
      saveToPlaylist;
  @override
  State<CharacterPackagePicker> createState() => _CharacterPackagePickerState();
}

class _CharacterPackagePickerState extends State<CharacterPackagePicker> {
  late Future<List<CharacterVideoPackage>> _packages = _load();
  bool _opening = false;
  DownloadedCharacterStore? _store;
  Future<List<CharacterVideoPackage>> _load() async {
    final claimed =
        await (widget.repository ?? const LocalCharacterEntitlementRepository())
            .loadClaimedCharacterIds();
    final orders = await (widget.orderRepository ??
            const LocalCustomizationOrderRepository())
        .loadOrders();
    _store = widget.downloadedStore ?? await DownloadedCharacterStore.current();
    final downloaded = await (widget.loadDownloaded?.call() ??
        _store?.load() ??
        Future.value(<CharacterVideoPackage>[]));
    return [
      ...downloaded,
      for (final package in officialVideoPackages)
        if (claimed.contains(package.id)) package,
      for (final character in characterGateCatalog)
        if (claimed.contains(character.$1))
          CharacterVideoPackage(
              id: character.$1,
              title: character.$2,
              cover: character.$4,
              videos: const []),
      for (final order in orders)
        if (order.status == '已交付')
          CharacterVideoPackage(
              id: 'custom-${order.id}',
              title: order.characterName,
              videos: const []),
    ];
  }

  Future<void> _select(CharacterVideoPackage package) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final videos = await Navigator.of(context)
          .push<List<PackageVideoSelection>>(MaterialPageRoute(
              builder: (_) => CharacterPackagePage(
                  package: package,
                  picking: true,
                  removeDownload: package.downloaded && _store != null
                      ? () async {
                          await _store!.remove(package.id);
                          if (mounted) setState(() => _packages = _load());
                        }
                      : null)));
      if (!mounted || videos == null || videos.isEmpty) return;
      if (widget.picking) {
        Navigator.pop(context, videos);
        return;
      }
      final target = await showModalBottomSheet<DevicePlaylistKind>(
          context: context,
          showDragHandle: true,
          builder: (context) => SafeArea(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const ListTile(
                    title: Text('加入哪个播放列表？'),
                    subtitle: Text('先加入待处理区，不代表已上传到设备')),
                ListTile(
                    title: const Text('日常展示'),
                    onTap: () =>
                        Navigator.pop(context, DevicePlaylistKind.startup)),
                ListTile(
                    title: const Text('音乐联动'),
                    onTap: () =>
                        Navigator.pop(context, DevicePlaylistKind.bluetooth)),
              ])));
      if (!mounted || target == null) return;
      await (widget.saveToPlaylist ?? PendingPlaylistStore.merge)(target, {
        for (final selection in videos)
          selection.key: (
            title: '${selection.package.title} · ${selection.video.title}',
            source: selection.video.source,
            asset: selection.video.asset
          )
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '已加入${target == DevicePlaylistKind.startup ? '日常展示' : '音乐联动'}待处理区，尚未上传设备')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('未能加入列表，请重试')));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: widget.embedded ? null : AppBar(title: const Text('我的角色')),
        body: FutureBuilder<List<CharacterVideoPackage>>(
          future: _packages,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: TextButton(
                      onPressed: () => setState(() => _packages = _load()),
                      child: const Text('我的角色读取失败，点击重试')));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.isEmpty) {
              return Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.collections_bookmark_outlined,
                              size: 40),
                          const SizedBox(height: 16),
                          const Text('还没有可选择的角色'),
                          const SizedBox(height: 8),
                          const Text('先到藏品内容库收藏角色，再选择其中的视频。',
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                              onPressed: () async {
                                await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                        builder: (_) => Scaffold(
                                            appBar: AppBar(
                                                title: const Text('内容库')),
                                            body:
                                                const CollectionCatalogPage())));
                                if (mounted) {
                                  setState(() => _packages = _load());
                                }
                              },
                              child: const Text('浏览内容库')),
                        ],
                      )));
            }
            return LayoutBuilder(builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context);
              final columns =
                  constraints.maxWidth >= 360 && scale.scale(12) <= 17 ? 3 : 2;
              final width =
                  (constraints.maxWidth - 32 - (columns - 1) * 10) / columns;
              return CustomScrollView(slivers: [
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Text(
                            widget.picking
                                ? '选择角色，再勾选需要加入当前列表的视频'
                                : '选择角色中的视频，加入日常展示或音乐联动',
                            style: const TextStyle(fontSize: 12)))),
                SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 12,
                            mainAxisExtent: width +
                                scale.scale(13) * 3.4 +
                                scale.scale(11) * 3 +
                                scale.scale(12) * 2 +
                                50),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final package = snapshot.data![index];
                          final cover = package.cover ??
                              (package.videos.isEmpty
                                  ? null
                                  : package.videos.first.thumbnail);
                          return Card(
                              margin: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                  onTap:
                                      _opening ? null : () => _select(package),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        InkWell(
                                            onTap: _opening
                                                ? null
                                                : () => _select(package),
                                            child: AspectRatio(
                                                aspectRatio: 1,
                                                child: cover == null
                                                    ? const ColoredBox(
                                                        color:
                                                            Color(0xff111e2a),
                                                        child: Icon(
                                                            Icons
                                                                .person_outline,
                                                            size: 44))
                                                    : package.downloaded
                                                        ? Image.file(
                                                            File(cover),
                                                            fit: BoxFit.contain,
                                                            errorBuilder: (context,
                                                                    error,
                                                                    stack) =>
                                                                const Icon(Icons
                                                                    .person_outline))
                                                        : Image.asset(cover,
                                                            fit: BoxFit
                                                                .contain))),
                                        Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                8, 8, 8, 0),
                                            child: Text(package.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    height: 1.5,
                                                    fontWeight:
                                                        FontWeight.w600))),
                                        Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text(
                                                package.videos.isEmpty
                                                    ? '暂无可用视频'
                                                    : package.downloaded
                                                        ? '已下载 ${package.videos.length}/${package.totalVideos ?? package.videos.length} 个视频'
                                                        : '${package.videos.length} 个视频',
                                                style: const TextStyle(
                                                    fontSize: 11))),
                                        const Spacer(),
                                        Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                6, 0, 6, 6),
                                            child: OutlinedButton(
                                                onPressed: _opening ||
                                                        package.videos.isEmpty
                                                    ? null
                                                    : () => _select(package),
                                                style: OutlinedButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 4),
                                                    textStyle: const TextStyle(
                                                        fontSize: 12)),
                                                child: Text(widget.picking
                                                    ? '选择视频'
                                                    : '加入播放列表'))),
                                      ])));
                        }, childCount: snapshot.data!.length))),
              ]);
            });
          },
        ),
      );
}
