import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/community_content.dart';
import 'package:hildors_cockpit/src/features/community/content_catalog_repository.dart';

void main() {
  test('preview catalog exposes only approved content', () async {
    const repository = PreviewContentCatalogRepository(delay: Duration.zero);

    final items = await repository.fetchApprovedContent();

    expect(items, isNotEmpty);
    expect(
      items.every(
        (item) => item.rightsStatus == CommunityRightsStatus.verified,
      ),
      isTrue,
    );
  });

  test('catalog filter combines category query and downloaded state', () {
    final items = filterCatalogContent(
      communityPreviewItems,
      category: '宠物',
      query: '太空',
      downloadedIds: {'preview_pet_01'},
      downloadedOnly: true,
    );

    expect(items.map((item) => item.id), ['preview_pet_01']);
  });

  test('catalog filter matches creator and summary case-insensitively', () {
    final items = filterCatalogContent(
      communityPreviewItems,
      category: '全部',
      query: 'MYTHBUILD',
      downloadedIds: const {},
      downloadedOnly: false,
    );

    expect(items.length, communityPreviewItems.length);
  });
}
