import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../theme/hildors_theme.dart';
import '../video/device_playlist_draft.dart';
import '../video/playlist_store.dart';
import 'community_content.dart';
import 'community_detail_page.dart';
import 'content_catalog_repository.dart';
import 'local_content_registry.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({this.catalogRepository, super.key});

  final ContentCatalogRepository? catalogRepository;

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  late final ContentCatalogRepository _catalog =
      widget.catalogRepository ?? const PreviewContentCatalogRepository();
  late Future<List<CommunityContent>> _contentFuture;
  var _category = '全部';
  var _query = '';
  var _downloadedOnly = false;
  final _downloadedIds = <String>{};
  List<File> _importedFiles = const [];
  final _localContentRegistry = const LocalContentRegistry();

  @override
  void initState() {
    super.initState();
    _loadContent();
    _loadDownloadedContent();
  }

  void _loadContent() {
    _contentFuture = _catalog.fetchApprovedContent();
  }

  Future<void> _loadDownloadedContent() async {
    final ids = await _localContentRegistry.load();
    if (!mounted) return;
    setState(() {
      _downloadedIds
        ..clear()
        ..addAll(ids);
      _importedFiles = const [];
    });
    final files = await _localContentRegistry.importedFiles();
    if (!mounted) return;
    setState(() => _importedFiles = files);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('藏品'),
              Text(
                'COLLECTION ARCHIVE',
                style: TextStyle(
                  color: HildorsColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.85, -0.9),
              radius: 1.15,
              colors: [
                Color(0x242C547A),
                Color(0x100C3435),
                Colors.transparent
              ],
            ),
          ),
          child: FutureBuilder<List<CommunityContent>>(
            future: _contentFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _CatalogError(onRetry: () => setState(_loadContent));
              }
              final items = filterCatalogContent(
                snapshot.data ?? const <CommunityContent>[],
                category: _category,
                query: _query,
                downloadedIds: _downloadedIds,
                downloadedOnly: _downloadedOnly,
              );
              return _buildCatalog(context, items);
            },
          ),
        ),
      );

  Widget _buildCatalog(
    BuildContext context,
    List<CommunityContent> items,
  ) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 600 ? 4 : 3;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              const _DownloadNotice(),
              const SizedBox(height: 12),
              _CollectionHero(
                localMode: _downloadedOnly,
                downloadedCount: _downloadedIds.length,
              ),
              const SizedBox(height: 14),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('官方内容')),
                  ButtonSegment(value: true, label: Text('本地导入')),
                ],
                selected: {_downloadedOnly},
                onSelectionChanged: (selection) {
                  setState(() => _downloadedOnly = selection.single);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: '在内容中搜索',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: const Icon(Icons.tune),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['全部', '角色', '音乐']
                      .map((category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: _category == category,
                              onSelected: (_) =>
                                  setState(() => _category = category),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _downloadedOnly ? '本机内容' : '精选角色',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${items.length.toString().padLeft(2, '0')} ITEMS',
                    style: const TextStyle(
                      color: HildorsColors.textSecondary,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (items.isEmpty && (!_downloadedOnly || _importedFiles.isEmpty))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      _downloadedOnly ? '还没有下载内容' : '没有找到匹配内容',
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.57,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _ContentTile(
                      item: item,
                      downloaded: _downloadedIds.contains(item.id),
                      onTap: () => _openContent(item),
                    );
                  },
                ),
              if (_downloadedOnly) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _importLocalVideo,
                  icon: const Icon(Icons.video_file_outlined),
                  label: const Text('从手机导入视频'),
                ),
                const SizedBox(height: 8),
                Text(
                  '文件仅保存在 App 私有空间，并通过局域网发送到设备，不会上传至 HILDORS。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_importedFiles.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ..._importedFiles.map((file) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.video_file_outlined),
                          title: Text(
                              file.path.split(Platform.pathSeparator).last),
                          subtitle: Text(
                              '用户本地导入 · ${(file.lengthSync() / 1048576).toStringAsFixed(1)} MB'),
                          trailing: TextButton.icon(
                            label: const Text('加入列表'),
                            icon: const Icon(Icons.playlist_add),
                            onPressed: () => _addToPlaylist(file),
                          ),
                          onTap: () => _addToPlaylist(file),
                        ),
                      )),
                ],
              ],
            ],
          );
        },
      );

  Future<void> _importLocalVideo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入本地视频'),
        content: const Text(
          '请确认你拥有该内容的合法使用权。文件只保存在本机，不会上传到 HILDORS 内容库。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认并选择文件'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['mp4', 'mov', 'm4v'],
    );
    if (picked?.path == null || !mounted) return;
    try {
      await _localContentRegistry.importFile(picked!.path!, picked.name);
      final files = await _localContentRegistry.importedFiles();
      if (!mounted) return;
      setState(() => _importedFiles = files);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已导入 App 本机内容，可在连接设备后发送。')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导入失败，请检查文件后重试。')),
      );
    }
  }

  Future<void> _addToPlaylist(File file) async {
    final kind = await showModalBottomSheet<DevicePlaylistKind>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('加入播放列表'),
          const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '保存到本机列表。视频仍需发送到设备；设备列表同步暂未开放。',
              )),
          ListTile(
              title: const Text('日常展示'),
              leading: const Icon(Icons.wb_sunny_outlined),
              onTap: () => Navigator.pop(context, DevicePlaylistKind.startup)),
          ListTile(
              title: const Text('音乐联动'),
              leading: const Icon(Icons.graphic_eq),
              onTap: () =>
                  Navigator.pop(context, DevicePlaylistKind.bluetooth)),
        ],
      )),
    );
    if (kind == null) return;
    try {
      await PlaylistStore.add(
          kind, file.path.split(Platform.pathSeparator).last);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('已加入本机播放列表，可从首页进入查看'),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('保存失败，请重试')));
    }
  }

  Future<void> _openContent(CommunityContent item) async {
    final downloaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CommunityDetailPage(
          content: item,
          initiallyDownloaded: _downloadedIds.contains(item.id),
        ),
      ),
    );
    if (downloaded == true && mounted) {
      await _localContentRegistry.add(item.id);
      if (!mounted) return;
      setState(() => _downloadedIds.add(item.id));
    }
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 52),
              const SizedBox(height: 12),
              const Text('内容库加载失败，请检查网络后重试'),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('重新加载'),
              ),
            ],
          ),
        ),
      );
}

class _CollectionHero extends StatelessWidget {
  const _CollectionHero({
    required this.localMode,
    required this.downloadedCount,
  });

  final bool localMode;
  final int downloadedCount;

  @override
  Widget build(BuildContext context) => Container(
        height: 132,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x4D65B8FF)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/content_thumbnails/celestial_mage.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0.2, -0.25),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xF2070D15),
                    Color(0xC20A1220),
                    Color(0x33101725),
                  ],
                  stops: [0, 0.58, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HILDORS / ARCHIVE 01',
                    style: TextStyle(
                      color: HildorsColors.teal,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    localMode ? '我的本机藏品' : '角色收藏库',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    localMode
                        ? '$downloadedCount 个内容已保存，可发送到全息设备'
                        : '发现官方角色、动作与音乐联动内容',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _DownloadNotice extends StatelessWidget {
  const _DownloadNotice();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              Icons.download_for_offline_outlined,
              size: 22,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                '先下载至 App，再连接设备发送',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      );
}

String _compactTitle(String title) {
  const prefix = 'HILDORS ';
  return title.startsWith(prefix) ? title.substring(prefix.length) : title;
}

class _ContentTile extends StatelessWidget {
  const _ContentTile({
    required this.item,
    required this.downloaded,
    required this.onTap,
  });

  final CommunityContent item;
  final bool downloaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumbnail = item.thumbnailAsset;
    final playable = item.previewAsset != null;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: downloaded
              ? HildorsColors.teal.withValues(alpha: 0.55)
              : HildorsColors.hairline,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbnail != null)
                    Image.asset(thumbnail, fit: BoxFit.cover)
                  else
                    ColoredBox(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.view_in_ar, size: 34),
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x99000000)],
                        stops: [0.55, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCC0B111A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0x4D34E7D4)),
                      ),
                      child: Text(
                        item.id.startsWith('hildors_demo')
                            ? 'DEMO'
                            : 'ORIGINAL',
                        style: const TextStyle(
                          color: HildorsColors.teal,
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            playable ? Icons.play_arrow : Icons.auto_awesome,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            playable ? '视频' : '概念',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (downloaded)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: HildorsColors.teal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.download_done,
                          color: HildorsColors.background,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _compactTitle(item.title),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${item.category} · ${item.fileSizeMb}MB',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.creatorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: HildorsColors.textSecondary,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
