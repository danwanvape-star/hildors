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
              return _CatalogError(onRetry: () {
                setState(_loadContent);
              });
            }
            final allItems = snapshot.data ?? const <CommunityContent>[];
            final items = filterCatalogContent(
              allItems,
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
      ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: '搜索角色、场景或创作者',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: const Icon(Icons.tune),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          const _DownloadNotice(),
          const SizedBox(height: 16),
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
          Wrap(
            spacing: 8,
            children: ['全部', '宠物', '派对', '音乐']
                .map((category) => ChoiceChip(
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    ))
                .toList(),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('HILDORS 精选', style: Theme.of(context).textTheme.titleLarge),
              Text('${_downloadedIds.length} 个已下载'),
            ],
          ),
          const SizedBox(height: 4),
          const Text('展示已通过审核并适配设备的 MythBuild 内容。'),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(_downloadedOnly ? '还没有下载内容' : '没有找到匹配内容'),
              ),
            ),
          for (final item in items)
            _ContentCard(
              item: item,
              downloaded: _downloadedIds.contains(item.id),
              onTap: () async {
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
              },
            ),
        ],
      );
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
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.download_for_offline_outlined,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('先下载，再连接设备',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('联网时把内容下载到手机；下载完成后再连接 P20/P11 局域网并发送到设备。'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.item,
    required this.downloaded,
    required this.onTap,
  });

  final CommunityContent item;
  final bool downloaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            radius: 28,
            child: Icon(downloaded ? Icons.download_done : Icons.view_in_ar),
          ),
          title: Text(item.title),
          subtitle: Text(
            '${item.category} · ${item.fileSizeMb} MB · ${item.supportedModels.join('/')}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
