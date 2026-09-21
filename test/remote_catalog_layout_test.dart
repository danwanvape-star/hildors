import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_page.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_repository.dart';
import 'package:hildors_cockpit/src/features/community/remote_layout_repository.dart';

void main() {
  final packages = [
    const RemoteCatalogPackage(
      id: 'official',
      title: '官方角色',
      source: 'hildors',
      format: 'single',
      coverUrl: 'https://example.test/should-not-be-used.jpg',
      tags: ['游戏'],
      clips: [RemoteCatalogClip('official-clip', '待机', 10)],
    ),
    const RemoteCatalogPackage(
      id: 'creator',
      title: '创作者角色',
      source: 'creator',
      format: 'package',
      coverUrl: 'https://example.test/creator-cover.jpg',
      tags: ['二次元'],
      clips: [RemoteCatalogClip('creator-clip', '舞蹈', 12)],
    ),
  ];

  testWidgets('藏品页统一网格使用布局列数而不按来源拆分', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: RemoteCatalogPage(
      load: () async => packages,
      loadLayout: () async => const [
        RemoteLayoutBlock(
            id: 'creators',
            type: 'creators',
            title: '大神创作',
            visible: true,
            columns: 1),
        RemoteLayoutBlock(
            id: 'hildors',
            type: 'hildors',
            title: '品牌精选',
            visible: true,
            columns: 3),
      ],
    ))));
    await tester.pumpAndSettle();

    expect(find.text('大神创作'), findsNothing);
    expect(find.text('品牌精选'), findsNothing);
    expect(tester.getTopLeft(find.text('官方角色')).dy,
        lessThan(tester.getTopLeft(find.text('创作者角色')).dy));
    expect(tester.getSize(find.text('创作者角色').first).width, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('布局服务失败时内容仍可浏览', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: RemoteCatalogPage(
      load: () async => packages,
      loadLayout: () => Future.error(Exception('offline')),
    ))));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('官方角色'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('官方角色'), findsWidgets);
    await tester.scrollUntilVisible(find.text('创作者角色'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('创作者角色'), findsWidgets);
    expect(find.text('暂时无法加载内容库'), findsNothing);
  });

  testWidgets('可按后台题材标签和内容形式组合筛选', (tester) async {
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: RemoteCatalogPage(load: () async => packages))));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ChoiceChip, '游戏'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '二次元'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '角色视频包'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '角色视频包'));
    await tester.pumpAndSettle();
    expect(find.text('创作者角色'), findsOneWidget);
    expect(find.text('官方角色'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, '游戏'));
    await tester.pumpAndSettle();
    expect(find.text('暂无符合条件的内容'), findsOneWidget);
    await tester.tap(find.text('清除筛选'));
    await tester.pumpAndSettle();
    expect(find.text('官方角色'), findsWidgets);
    expect(find.text('创作者角色'), findsWidgets);
  });

  testWidgets('角色包一级只显示角色主图，进入后才显示包内视频', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: RemoteCatalogPage(load: () async => packages))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('创作者角色'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('package-cover-creator')), findsWidgets);
    expect(find.text('舞蹈'), findsNothing);
    expect(
        find.byKey(const ValueKey('single-thumbnail-official')), findsNothing);
    await tester.tap(find.text('创作者角色').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('package-detail-cover-creator')),
        findsOneWidget);
    await tester.scrollUntilVisible(find.text('舞蹈'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('包内视频'), findsOneWidget);
    expect(find.text('舞蹈'), findsOneWidget);
  });
}
