import 'dart:io';
import 'package:flutter/foundation.dart';
import 'verified_video_download.dart';
import 'verified_video_cache.dart';

enum VideoDownloadStatus {
  idle,
  downloading,
  verifying,
  cancelling,
  cancelled,
  failed,
  complete
}

/// One controller per selected clip; session tokens are supplied per attempt.
class VideoDownloadController extends ChangeNotifier {
  VideoDownloadController(this.service,
      {required this.packageId, required this.clipId});
  final VerifiedVideoDownload service;
  final String packageId, clipId;
  VideoDownloadStatus status = VideoDownloadStatus.idle;
  int received = 0, total = 0;
  File? file;
  String? errorMessage;
  DownloadCancellation? _cancellation;
  bool _disposed = false;
  int _attempt = 0;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> start(String sessionToken) async {
    if (_disposed ||
        _cancellation != null ||
        status == VideoDownloadStatus.complete) {
      return;
    }
    final cancellation = DownloadCancellation();
    _attempt++;
    _cancellation = cancellation;
    status = VideoDownloadStatus.downloading;
    received = 0;
    total = 0;
    file = null;
    errorMessage = null;
    _changed();
    try {
      file = await service.download(
          packageId: packageId,
          clipId: clipId,
          sessionToken: sessionToken,
          cancellation: cancellation,
          onProgress: (count, length) {
            received = count;
            total = length;
            _changed();
          },
          onVerifying: () {
            status = VideoDownloadStatus.verifying;
            _changed();
          });
      status = VideoDownloadStatus.complete;
    } on DownloadCancelled {
      status = VideoDownloadStatus.cancelled;
    } catch (_) {
      status = VideoDownloadStatus.failed;
      errorMessage = '下载未完成，请检查网络和账号权限后重试';
    } finally {
      _cancellation = null;
      _changed();
    }
  }

  Future<void> restore() async {
    if (_disposed || _cancellation != null) return;
    final attempt = _attempt;
    final cached =
        await VerifiedVideoCache(service.cacheDirectory, service.baseUri.origin)
            .find(packageId, clipId);
    if (_disposed || _cancellation != null || attempt != _attempt) return;
    file = cached;
    if (cached != null) {
      status = VideoDownloadStatus.complete;
      errorMessage = null;
    } else if (status == VideoDownloadStatus.complete) {
      status = VideoDownloadStatus.idle;
    }
    _changed();
  }

  void cancel() {
    if (_cancellation == null) return;
    status = VideoDownloadStatus.cancelling;
    _cancellation!.cancel();
    _changed();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancellation?.cancel();
    super.dispose();
  }
}
