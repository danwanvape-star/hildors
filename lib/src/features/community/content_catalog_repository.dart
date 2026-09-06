import 'community_content.dart';

abstract interface class ContentCatalogRepository {
  Future<List<CommunityContent>> fetchApprovedContent();
}

class PreviewContentCatalogRepository implements ContentCatalogRepository {
  const PreviewContentCatalogRepository({
    this.delay = Duration.zero,
  });

  final Duration delay;

  @override
  Future<List<CommunityContent>> fetchApprovedContent() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return communityPreviewItems
        .where((item) => item.rightsStatus == CommunityRightsStatus.verified)
        .toList(growable: false);
  }
}
