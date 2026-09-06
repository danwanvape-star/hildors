import 'package:flutter/material.dart';

import 'community_content.dart';
import 'community_detail_page.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  var _category = '全部';
  final _downloadedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final items = _category == '全部'
        ? communityPreviewItems
        : communityPreviewItems.where((item) => item.category == _category);
    return Scaffold(
      appBar: AppBar(title: const Text('内容库')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            enabled: false,
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
      ),
    );
  }
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
