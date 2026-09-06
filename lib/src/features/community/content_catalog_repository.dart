import 'community_content.dart';

abstract interface class ContentCatalogRepository {
  Future<List<CommunityContent>> fetchApprovedContent();
}

class PreviewContentCatalogRepository implements ContentCatalogRepository {
  const PreviewContentCatalogRepository({this.delay = Duration.zero});

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

List<CommunityContent> filterCatalogContent(
  Iterable<CommunityContent> items, {
  required String category,
  required String query,
  required Set<String> downloadedIds,
  required bool downloadedOnly,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return items.where((item) {
    if (category != '全部' && item.category != category) return false;
    if (downloadedOnly && !downloadedIds.contains(item.id)) return false;
    if (normalizedQuery.isEmpty) return true;
    return item.title.toLowerCase().contains(normalizedQuery) ||
        item.creatorName.toLowerCase().contains(normalizedQuery) ||
        item.summary.toLowerCase().contains(normalizedQuery);
  }).toList(growable: false);
}
