import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_repository.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_page.dart';
import 'remote_catalog_test.dart' show item;

void main() {
  for (final withThumbnail in [true, false]) {
    testWidgets(
        'catalog and creator select thumbnail; detail selects preview (thumbnail: $withThumbnail)',
        (tester) async {
      final repo = RemoteCatalogRepository('https://example.test',
          fetch: (_) async => jsonEncode({
                'items': [
                  {
                    ...item('a'),
                    'coverPreviewPath': '/v1/covers/cover-a/preview',
                    if (withThumbnail)
                      'coverThumbnailPath': '/v1/covers/cover-a/thumbnail',
                    'creator': {
                      'id': 'creator-a',
                      'name': 'Alice',
                      'anonymous': false
                    }
                  }
                ]
              }));
      final packages = await repo.load();
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: RemoteCatalogPage(load: () async => packages))));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.byKey(const ValueKey('package-cover-a')).first, 300,
          scrollable: find.byType(Scrollable).first);
      expect(find.byTooltip('图片加载失败，点击重试'), findsWidgets);
      final image = tester
          .widget<Image>(find.byKey(const ValueKey('package-cover-a')).first);
      expect(
          (image.image as NetworkImage).url,
          withThumbnail
              ? 'https://example.test/v1/covers/cover-a/thumbnail'
              : 'https://example.test/v1/covers/cover-a');
      await tester.tap(find.text('测试角色 a').first);
      await tester.pumpAndSettle();
      final detail = tester
          .widget<Image>(find.byKey(const ValueKey('package-detail-cover-a')));
      expect((detail.image as NetworkImage).url,
          'https://example.test/v1/covers/cover-a/preview');
      await tester.tap(find.widgetWithText(TextButton, 'Alice'));
      await tester.pumpAndSettle();
      final creatorImage = tester.widget<Image>(find.byType(Image).last);
      expect(
          (creatorImage.image as NetworkImage).url,
          withThumbnail
              ? 'https://example.test/v1/covers/cover-a/thumbnail'
              : 'https://example.test/v1/covers/cover-a');
    });
  }
}
