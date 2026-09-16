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
      tags: ['游戏'],
      clips: [RemoteCatalogClip('official-clip', '待机', 10)],
    ),
    const RemoteCatalogPackage(
      id: 'creator',
      title: '创作者角色',
      source: 'creator',
      format: 'package',
      tags: ['二次元'],
      clips: [RemoteCatalogClip('creator-clip', '舞蹈', 12)],
    ),
  ];

  testWidgets('藏品页按后台顺序、标题和列数展示', (tester) async {
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

    expect(find.text('大神创作'), findsOneWidget);
    expect(find.text('品牌精选'), findsOneWidget);
    expect(tester.getTopLeft(find.text('大神创作')).dy,
        lessThan(tester.getTopLeft(find.text('品牌精选')).dy));
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

    expect(find.text('精选角色'), findsOneWidget);
    expect(find.text('官方角色'), findsWidgets);
    expect(find.text('创作者角色'), findsWidgets);
    expect(find.text('暂时无法加载内容库'), findsNothing);
  });
}
