import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/collection_hub_page.dart';
import 'package:hildors_cockpit/src/features/community/collection_catalog_page.dart';
import 'package:hildors_cockpit/src/features/video/character_package_picker.dart';

void main() {
  testWidgets('藏品保留官方和原创内容，移除本地视频入口', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CollectionHubPage()));
    expect(find.byType(CollectionCatalogPage), findsOneWidget);
    expect(find.text('本地视频'), findsNothing);
    await tester.tap(find.text('我的角色').first);
    await tester.pump();
    expect(
        tester
            .widget<CharacterPackagePicker>(find.byType(CharacterPackagePicker))
            .picking,
        isFalse);
    expect(find.text('我的收藏'), findsNothing);
    await tester.tap(find.text('内容库').first);
    await tester.pump();
    expect(find.byType(CollectionCatalogPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
