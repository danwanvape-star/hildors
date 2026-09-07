import 'package:flutter/material.dart';

import 'community_content.dart';
import 'community_detail_page.dart';
import 'content_catalog_repository.dart';

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

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  void _loadContent() {
    _contentFuture = _catalog.fetchApprovedContent();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('内容库')),
        body: FutureBuilder<List<CommunityContent>>(
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
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('全部内容')),
                  ButtonSegment(value: true, label: Text('我的下载')),
                ],
                selected: {_downloadedOnly},
                onSelectionChanged: (selection) {
                  setState(() => _downloadedOnly = selection.single);
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'HILDORS 精选',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text('${_downloadedIds.length} 个已下载'),
                ],
              ),
              const SizedBox(height: 10),
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
              if (items.isEmpty)
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
            ],
          );
        },
      );

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
                '先下载到手机，再连接设备发送',
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
                    const Positioned(
                      left: 6,
                      top: 6,
                      child: Icon(Icons.download_done, size: 20),
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
