import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/community_content.dart';
import 'package:hildors_cockpit/src/features/community/content_download_service.dart';

void main() {
  test('preview downloader reports monotonic progress and completion',
      () async {
    const service = PreviewContentDownloadService(stepDelay: Duration.zero);
    final updates = <ContentDownloadProgress>[];

    await service.download(
      communityPreviewItems.first,
      onProgress: updates.add,
    );

    expect(updates.first.status, ContentDownloadStatus.downloading);
    expect(updates.last.status, ContentDownloadStatus.downloaded);
    expect(updates.last.fraction, 1);
    for (var index = 1; index < updates.length; index++) {
      expect(
        updates[index].receivedBytes,
        greaterThanOrEqualTo(updates[index - 1].receivedBytes),
      );
    }
  });

  test('download progress safely handles unknown total size', () {
    const progress = ContentDownloadProgress(
      status: ContentDownloadStatus.downloading,
      receivedBytes: 10,
      totalBytes: 0,
    );

    expect(progress.fraction, 0);
  });
}
