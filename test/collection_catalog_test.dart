import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/collection_catalog_page.dart';

void main() {
  test('出处、形式、题材和搜索共同筛选，不虚构视频文件', () {
    expect(filterCollectionCatalog(source: 'HILDORS 出品', format: '单条视频'),
        hasLength(4));
    expect(filterCollectionCatalog(source: '创作者作品').every((v) => v.isConcept),
        isTrue);
    expect(filterCollectionCatalog(source: 'HILDORS 出品', topic: '神话'),
        hasLength(1));
    expect(filterCollectionCatalog(query: '机械'), hasLength(1));
    expect(filterCollectionCatalog(source: 'HILDORS 出品', format: '角色视频包'),
        isEmpty);
  });
  for (final scenario in [(320.0, 1.0), (390.0, 1.0), (320.0, 2.0)]) {
    testWidgets('三列方形封面不溢出 $scenario', (tester) async {
      tester.view.physicalSize = Size(scenario.$1, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final capture = GlobalKey();
      if (const bool.fromEnvironment('CAPTURE_CATALOG')) {
        await tester.runAsync(() async {
          final textFont = FontLoader('CatalogPreview')
            ..addFont(File('C:/Windows/Fonts/msyh.ttc')
                .readAsBytes()
                .then((bytes) => ByteData.sublistView(bytes)));
          final icons = FontLoader('MaterialIcons')
            ..addFont(File(
                    'E:/Flutter/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
                .readAsBytes()
                .then((bytes) => ByteData.sublistView(bytes)));
          await textFont.load();
          await icons.load();
        });
      }
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(useMaterial3: true).copyWith(
              textTheme: ThemeData.dark().textTheme.apply(
                  fontFamily: const bool.fromEnvironment('CAPTURE_CATALOG')
                      ? 'CatalogPreview'
                      : null)),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scenario.$2)),
              child: child!),
          home: RepaintBoundary(
              key: capture,
              child: const Scaffold(
                  body: SafeArea(child: CollectionCatalogPage())))));
      await tester.pumpAndSettle();
      final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
      expect(
          (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
              .crossAxisCount,
          3);
      final square = find.byType(AspectRatio).first;
      expect(tester.getSize(square).width, tester.getSize(square).height);
      expect(tester.takeException(), isNull);
      if (scenario == (390.0, 1.0) &&
          const bool.fromEnvironment('CAPTURE_CATALOG')) {
        final boundary = capture.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/ui-previews').create(recursive: true);
          await File('build/ui-previews/collection-catalog.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('筛选可组合，空结果可重置', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CollectionCatalogPage())));
    await tester.tap(find.widgetWithText(ChoiceChip, 'HILDORS 出品'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, '角色视频包'));
    await tester.pumpAndSettle();
    expect(find.text('暂无符合条件的内容'), findsOneWidget);
    await tester.tap(find.text('查看全部内容'));
    await tester.pumpAndSettle();
    expect(find.text('8 项内容'), findsOneWidget);
  });
}
