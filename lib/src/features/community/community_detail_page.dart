import 'package:flutter/material.dart';

import 'community_content.dart';

class CommunityDetailPage extends StatelessWidget {
  const CommunityDetailPage({required this.content, super.key});

  final CommunityContent content;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('内容详情'),
          actions: [
            IconButton(
              tooltip: '举报或版权投诉',
              onPressed: () => _showReportSheet(context),
              icon: const Icon(Icons.flag_outlined),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(child: Icon(Icons.view_in_ar, size: 80)),
            ),
            const SizedBox(height: 20),
            Text(content.title,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text('创作者：${content.creatorName}'),
            const SizedBox(height: 12),
            Text(content.summary),
            const SizedBox(height: 20),
            _InfoRow(
                label: '权利状态', value: content.canInstall ? '已通过社区授权校验' : '审核中'),
            _InfoRow(label: '使用许可', value: _licenseLabel(content.license)),
            _InfoRow(
                label: '目标列表',
                value: content.playlistTarget == DevicePlaylistTarget.local
                    ? '本地播放列表'
                    : '蓝牙播放列表'),
            _InfoRow(label: '适配设备', value: content.supportedModels.join(' / ')),
            _InfoRow(label: '内容版本', value: content.version),
            _InfoRow(label: '文件大小', value: '${content.fileSizeMb} MB'),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.send_to_mobile_outlined),
              label: const Text('发送到设备 · 等待接口'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showReportSheet(context),
              icon: const Icon(Icons.copyright_outlined),
              label: const Text('举报或提交版权投诉'),
            ),
          ],
        ),
      );

  String _licenseLabel(CommunityLicense license) => switch (license) {
        CommunityLicense.personalUse => '仅限个人非商业使用',
        CommunityLicense.commercialUse => '允许商业使用',
        CommunityLicense.publicDomain => '公共领域',
      };

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('举报与版权投诉', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text('正式接入后，投诉将携带内容 ID、版本和创作者信息提交给社区运营方，并立即冻结新的设备投放。'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('投诉接口尚未接入')));
              },
              child: const Text('了解投诉流程'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 88,
                child:
                    Text(label, style: Theme.of(context).textTheme.bodySmall)),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
