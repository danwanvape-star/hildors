import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/community_page.dart';
import 'package:hildors_cockpit/src/features/community/content_catalog_repository.dart';

void main() {
  testWidgets('content grid fits three columns on a phone viewport',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: CommunityPage(
          catalogRepository:
              PreviewContentCatalogRepository(delay: Duration.zero),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('全息展示 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
