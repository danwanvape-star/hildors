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
}
