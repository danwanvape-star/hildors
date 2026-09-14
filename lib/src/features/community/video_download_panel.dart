import 'package:flutter/material.dart';
import 'video_download_controller.dart';

/// Parent owns the controller and disposes it when the detail route closes.
class VideoDownloadPanel extends StatefulWidget {
  const VideoDownloadPanel(
      {super.key,
      required this.controller,
      required this.getSessionToken,
      this.enabled = false});
  final VideoDownloadController controller;
  final Future<String?> Function() getSessionToken;
  final bool enabled;
  @override
  State<VideoDownloadPanel> createState() => _VideoDownloadPanelState();
}

class _VideoDownloadPanelState extends State<VideoDownloadPanel> {
  bool _authenticating = false;
  String? _authError;
  Future<void> _start() async {
    if (_authenticating || !widget.enabled) return;
    setState(() {
      _authenticating = true;
      _authError = null;
    });
    try {
      final token = await widget.getSessionToken();
      if (!mounted || !widget.enabled) return;
      if (token == null || token.isEmpty) {
        setState(() => _authError = '请先登录后下载');
        return;
      }
      await widget.controller.start(token);
    } catch (_) {
      if (mounted) setState(() => _authError = '暂时无法确认登录状态，请稍后重试');
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final task = widget.controller;
        final active = [
          VideoDownloadStatus.downloading,
          VideoDownloadStatus.verifying,
          VideoDownloadStatus.cancelling
        ].contains(task.status);
        final label = switch (task.status) {
          VideoDownloadStatus.idle => '保存到App本地',
          VideoDownloadStatus.downloading => task.total == 0
              ? '正在准备下载'
              : '下载中 ${(100 * task.received / task.total).floor()}%',
          VideoDownloadStatus.verifying => '正在校验视频',
          VideoDownloadStatus.cancelling => '正在取消并清理',
          VideoDownloadStatus.cancelled => '下载已取消',
          VideoDownloadStatus.failed => task.errorMessage ?? '下载失败，请重试',
          VideoDownloadStatus.complete => '已保存到App本地 · 未发送设备',
        };
        return Card(
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(label),
                      if (active) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                            value: task.status ==
                                        VideoDownloadStatus.downloading &&
                                    task.total > 0
                                ? (task.received / task.total).clamp(0.0, 1.0)
                                : null),
                        TextButton(
                            onPressed:
                                task.status == VideoDownloadStatus.cancelling
                                    ? null
                                    : task.cancel,
                            child: const Text('取消下载')),
                      ] else if (task.status !=
                          VideoDownloadStatus.complete) ...[
                        if (_authError != null) Text(_authError!),
                        if (!widget.enabled)
                          const Text('下载暂未开放')
                        else
                          FilledButton(
                              onPressed: _authenticating ? null : _start,
                              child: Text(_authenticating
                                  ? '确认登录状态中'
                                  : task.status == VideoDownloadStatus.idle
                                      ? '登录后下载'
                                      : '重新下载')),
                      ],
                    ])));
      });
}
