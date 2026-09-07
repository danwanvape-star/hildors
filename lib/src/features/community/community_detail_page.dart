import 'package:flutter/material.dart';

import 'community_content.dart';
import 'content_preview_player.dart';
import 'content_download_service.dart';

class CommunityDetailPage extends StatefulWidget {
  const CommunityDetailPage({
    required this.content,
    this.initiallyDownloaded = false,
    this.downloadService,
    super.key,
  });

  final CommunityContent content;
  final bool initiallyDownloaded;
  final ContentDownloadService? downloadService;

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  late final ContentDownloadService _downloadService =
      widget.downloadService ?? const PreviewContentDownloadService();
  late var _status = widget.initiallyDownloaded
      ? ContentDownloadStatus.downloaded
      : ContentDownloadStatus.notDownloaded;
  var _downloadProgress = 0.0;
  String? _downloadError;

  CommunityContent get content => widget.content;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            Navigator.pop(context, _status == ContentDownloadStatus.downloaded);
          }
        },
        child: Scaffold(
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
              ContentPreviewPlayer(assetPath: content.previewAsset),
              const SizedBox(height: 20),
              Text(content.title,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text('创作者：${content.creatorName}'),
              const SizedBox(height: 12),
              Text(content.summary),
              const SizedBox(height: 20),
              _InfoRow(
                label: '审核状态',
                value: content.canDownload ? 'HILDORS 已审核' : '审核中',
              ),
              _InfoRow(label: '使用许可', value: _licenseLabel(content.license)),
              _InfoRow(
                label: '推荐列表',
                value: content.playlistTarget == DevicePlaylistTarget.local
                    ? '普通播放列表'
                    : '蓝牙播放列表',
              ),
              _InfoRow(
                label: '适配设备',
                value: content.supportedModels.join(' / '),
              ),
              _InfoRow(label: '视频时长', value: '${content.durationSeconds} 秒'),
              _InfoRow(label: '文件大小', value: '${content.fileSizeMb} MB'),
              const SizedBox(height: 20),
              if (_status == ContentDownloadStatus.downloading) ...[
                LinearProgressIndicator(value: _downloadProgress),
                const SizedBox(height: 10),
                Center(
                  child:
                      Text('正在下载至 App ${(_downloadProgress * 100).round()}%'),
                ),
              ] else
                FilledButton.icon(
                  onPressed: content.canDownload ? _handlePrimaryAction : null,
                  icon: Icon(
                    _status == ContentDownloadStatus.downloaded
                        ? Icons.send_to_mobile_outlined
                        : Icons.download_for_offline_outlined,
                  ),
                  label: Text(
                    _status == ContentDownloadStatus.downloaded
                        ? '发送到设备'
                        : _status == ContentDownloadStatus.failed
                            ? '重新下载'
                            : '下载至 App',
                  ),
                ),
              if (_status == ContentDownloadStatus.downloaded) ...[
                const SizedBox(height: 8),
                const Center(child: Text('已保存到 App 本机内容，断网后仍可发送到设备。')),
              ],
              if (_downloadError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _downloadError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _showReportSheet(context),
                icon: const Icon(Icons.copyright_outlined),
                label: const Text('举报或提交版权投诉'),
              ),
            ],
          ),
        ),
      );

  Future<void> _handlePrimaryAction() async {
    if (_status == ContentDownloadStatus.downloaded) {
      await _showPlaylistTargetSheet();
      return;
    }

    setState(() {
      _status = ContentDownloadStatus.downloading;
      _downloadProgress = 0;
      _downloadError = null;
    });
    try {
      await _downloadService.download(
        content,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _status = progress.status;
            _downloadProgress = progress.fraction;
            _downloadError = progress.errorMessage;
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = ContentDownloadStatus.failed;
        _downloadError = '下载失败，请检查网络后重试';
      });
    }
  }

  Future<void> _showPlaylistTargetSheet() async {
    var selectedTarget = content.playlistTarget;
    final target = await showModalBottomSheet<DevicePlaylistTarget>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('发送到哪个播放列表', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              const Text('设备会根据蓝牙连接状态自动播放对应列表。'),
              RadioListTile<DevicePlaylistTarget>(
                value: DevicePlaylistTarget.local,
                groupValue: selectedTarget,
                title: const Text('普通播放列表'),
                subtitle: const Text('设备未连接蓝牙时播放'),
                onChanged: (value) {
                  if (value != null) {
                    setSheetState(() => selectedTarget = value);
                  }
                },
              ),
              RadioListTile<DevicePlaylistTarget>(
                value: DevicePlaylistTarget.bluetooth,
                groupValue: selectedTarget,
                title: const Text('蓝牙播放列表'),
                subtitle: const Text('设备连接蓝牙音源时播放'),
                onChanged: (value) {
                  if (value != null) {
                    setSheetState(() => selectedTarget = value);
                  }
                },
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, selectedTarget),
                child: const Text('确认发送'),
              ),
            ],
          ),
        ),
      ),
    );
    if (target == null || !mounted) return;
    final label = target == DevicePlaylistTarget.local ? '普通播放列表' : '蓝牙播放列表';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已选择$label；设备传输接口将在通信协议确认后接入。')),
    );
  }

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
            const Text('投诉将携带内容 ID、版本和创作者信息提交给运营方，并暂停新的下载和设备投放。'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('了解'),
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
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
