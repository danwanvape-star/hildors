import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/community_content.dart';
import 'package:hildors_cockpit/src/features/community/content_catalog_repository.dart';

void main() {
  test('preview catalog exposes playable videos and concept thumbnails',
      () async {
    const repository = PreviewContentCatalogRepository(delay: Duration.zero);

    final items = await repository.fetchApprovedContent();

    expect(items, hasLength(12));
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
      category: '角色',
      query: '展示 01',
      downloadedIds: {'hildors_demo_01'},
      downloadedOnly: true,
    );

    expect(items.map((item) => item.id), ['hildors_demo_01']);
  });

  test('catalog filter matches creator case-insensitively', () {
    final items = filterCatalogContent(
      communityPreviewItems,
      category: '全部',
      query: 'hildors demo',
      downloadedIds: const {},
      downloadedOnly: false,
    );

    expect(items.length, 4);
  });

  test('preview catalog provides four phone-playable video assets', () {
    expect(
      communityPreviewItems
          .map((item) => item.previewAsset)
          .whereType<String>(),
      [
        'assets/videos/showcase/showcase_01.mp4',
        'assets/videos/showcase/showcase_02.mp4',
        'assets/videos/showcase/showcase_03.mp4',
        'assets/videos/showcase/showcase_04.mp4',
      ],
    );
  });
}
