import 'community_content.dart';

typedef DownloadProgressCallback = void Function(ContentDownloadProgress value);

class ContentDownloadProgress {
  const ContentDownloadProgress({
    required this.status,
    required this.receivedBytes,
    required this.totalBytes,
    this.errorMessage,
  });

  final ContentDownloadStatus status;
  final int receivedBytes;
  final int totalBytes;
  final String? errorMessage;

  double get fraction {
    if (totalBytes <= 0) return 0;
    return (receivedBytes / totalBytes).clamp(0, 1);
  }
}

abstract interface class ContentDownloadService {
  Future<void> download(
    CommunityContent content, {
    required DownloadProgressCallback onProgress,
  });
}

class PreviewContentDownloadService implements ContentDownloadService {
  const PreviewContentDownloadService({
    this.stepDelay = const Duration(milliseconds: 120),
  });

  final Duration stepDelay;

  @override
  Future<void> download(
    CommunityContent content, {
    required DownloadProgressCallback onProgress,
  }) async {
    final totalBytes = content.fileSizeMb * 1024 * 1024;
    onProgress(ContentDownloadProgress(
      status: ContentDownloadStatus.downloading,
      receivedBytes: 0,
      totalBytes: totalBytes,
    ));
    for (var step = 1; step <= 4; step++) {
      if (stepDelay > Duration.zero) {
        await Future<void>.delayed(stepDelay);
      }
      onProgress(ContentDownloadProgress(
        status: step == 4
            ? ContentDownloadStatus.downloaded
            : ContentDownloadStatus.downloading,
        receivedBytes: totalBytes * step ~/ 4,
        totalBytes: totalBytes,
      ));
    }
  }
}
