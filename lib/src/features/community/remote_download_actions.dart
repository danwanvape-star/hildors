import 'package:flutter/material.dart';
import 'download_access_repository.dart';
import 'verified_video_download.dart';
import 'video_download_controller.dart';
import 'video_download_panel.dart';

/// Route-owned IO integration, supplied through RemoteCatalogPage.clipActions.
/// The session provider must read the current user session, not a build-time token.
class RemoteDownloadActions extends StatefulWidget {
  const RemoteDownloadActions(
      {super.key,
      required this.service,
      required this.packageId,
      required this.clipId,
      required this.getSessionToken});
  final VerifiedVideoDownload service;
  final String packageId, clipId;
  final Future<String?> Function() getSessionToken;
  @override
  State<RemoteDownloadActions> createState() => _RemoteDownloadActionsState();
}

class _RemoteDownloadActionsState extends State<RemoteDownloadActions> {
  late VideoDownloadController _controller;
  late Future<DownloadAccess> _access;
  @override
  void initState() {
    super.initState();
    _controller = VideoDownloadController(widget.service,
        packageId: widget.packageId, clipId: widget.clipId);
    _access = _check();
  }

  Future<DownloadAccess> _check() async {
    final controller = _controller;
    final access = await DownloadAccessRepository(widget.service.baseUri)
        .check(widget.packageId, widget.clipId, await widget.getSessionToken());
    if (access == DownloadAccess.allowed &&
        mounted &&
        controller == _controller) {
      await controller.restore();
    }
    return access;
  }

  @override
  void didUpdateWidget(covariant RemoteDownloadActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service ||
        oldWidget.packageId != widget.packageId ||
        oldWidget.clipId != widget.clipId) {
      _controller.dispose();
      _controller = VideoDownloadController(widget.service,
          packageId: widget.packageId, clipId: widget.clipId);
    }
    _access = _check();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<DownloadAccess>(
      future: _access,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
              padding: EdgeInsets.all(12), child: Text('正在确认下载权限…'));
        }
        if (snapshot.data == DownloadAccess.allowed && !snapshot.hasError) {
          return VideoDownloadPanel(
              key: ObjectKey(_controller),
              controller: _controller,
              enabled: true,
              getSessionToken: () async {
                final token = await widget.getSessionToken();
                final access =
                    await DownloadAccessRepository(widget.service.baseUri)
                        .check(widget.packageId, widget.clipId, token);
                if (access == DownloadAccess.signInRequired) return null;
                if (access != DownloadAccess.allowed) {
                  throw StateError('下载权限已变化');
                }
                return token;
              });
        }
        final message = snapshot.hasError
            ? '暂时无法确认下载权限'
            : switch (snapshot.data) {
                DownloadAccess.signInRequired => '登录后可查看下载权限',
                DownloadAccess.disabled => '下载暂未开放',
                _ => '此视频暂无下载权限或暂不可用',
              };
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(message),
          TextButton(
              onPressed: () => setState(() {
                    _access = _check();
                  }),
              child: const Text('重新检查'))
        ]);
      });
}
