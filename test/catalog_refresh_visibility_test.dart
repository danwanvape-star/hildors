import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_page.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_repository.dart';

void main() {
  testWidgets('刷新提示新作品总数并可直接查看创作者作品', (tester) async {
    var loads = 0;
    final official = List.generate(
        4,
        (index) => RemoteCatalogPackage(
              id: 'official-$index',
              title: '官方 $index',
              source: 'hildors',
              format: 'single',
              tags: const [],
              clips: [RemoteCatalogClip('clip-$index', '视频', 10)],
            ));
    const mario = RemoteCatalogPackage(
      id: 'mario',
      title: '超级马里奥',
      source: 'creator',
      format: 'single',
      tags: ['游戏世界'],
      clips: [RemoteCatalogClip('mario-clip', '马里奥', 10)],
    );
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: RemoteCatalogPage(
      load: () async => ++loads == 1 ? official : [...official, mario],
    ))));
    await tester.pumpAndSettle();
    expect(find.text('共 4 项内容 · 创作者作品 0 项'), findsOneWidget);
    await tester.tap(find.byTooltip('刷新目录'));
    await tester.pumpAndSettle();
    expect(loads, 2);
    expect(find.text('共 5 项内容 · 创作者作品 1 项'), findsOneWidget);
    expect(find.text('目录已刷新：共 5 项内容，含 1 项创作者作品'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '创作者作品'));
    await tester.pumpAndSettle();
    expect(find.text('超级马里奥'), findsOneWidget);
    expect(find.text('官方 0'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('默认目录混排来源且出处仅在卡片中展示', (tester) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: RemoteCatalogPage(
      load: () async => const [
        RemoteCatalogPackage(
            id: 'a',
            title: '官方',
            source: 'hildors',
            format: 'single',
            tags: [],
            clips: [RemoteCatalogClip('a1', '视频', 10)]),
        RemoteCatalogPackage(
            id: 'b',
            title: '创作',
            source: 'creator',
            format: 'single',
            tags: [],
            clips: [RemoteCatalogClip('b1', '视频', 10)]),
      ],
    ))));
    await tester.pumpAndSettle();
    expect(find.text('创作者作品'), findsOneWidget);
    expect(find.text('HILDORS 出品'), findsNWidgets(2));
    expect(tester.getTopLeft(find.text('官方')).dy,
        tester.getTopLeft(find.text('创作')).dy);
  });
}
