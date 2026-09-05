import 'package:flutter/material.dart';

import 'community_content.dart';
import 'community_detail_page.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('社区')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              enabled: false,
              decoration: InputDecoration(
                hintText: '搜索角色、创作者或场景',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.tune),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            const _RightsNotice(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('社区内容预览', style: Theme.of(context).textTheme.titleLarge),
                const Chip(label: Text('API 待接入')),
              ],
            ),
            const SizedBox(height: 4),
            const Text('以下为界面与授权流程示例，不代表已经上线的社区内容。'),
            const SizedBox(height: 12),
            for (final item in communityPreviewItems)
              _CommunityCard(
                item: item,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CommunityDetailPage(content: item),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _RightsNotice extends StatelessWidget {
  const _RightsNotice();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('授权后才能发送到设备',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('内容由社区创作者提供。App 将核验授权状态、设备适配和文件完整性。'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({required this.item, required this.onTap});

  final CommunityContent item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading:
              const CircleAvatar(radius: 28, child: Icon(Icons.view_in_ar)),
          title: Text(item.title),
          subtitle: Text(
              '${item.creatorName} · ${item.fileSizeMb} MB · ${item.supportedModels.join('/')}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
