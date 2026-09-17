import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_repository.dart';
import 'package:hildors_cockpit/src/features/community/remote_package_detail_page.dart';

void main() {
  testWidgets('selected single video shows an expandable story below playback',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final story = List.filled(18, '她在失落的星港守护最后一盏导航灯。').join();
    final item = RemoteCatalogPackage(
      id: 'guardian',
      title: '星港守望者',
      source: 'hildors',
      format: 'single',
      tags: const [],
      description: story,
      clips: const [RemoteCatalogClip('main', '待机', 12)],
    );

    await tester.pumpWidget(MaterialApp(
      home: RemotePackageDetailPage(item: item, catalog: [item]),
    ));
    final clip = find.byKey(const ValueKey('clip-guardian-main'));
    await tester.ensureVisible(clip);
    await tester.tap(clip);
    await tester.pumpAndSettle();

    final unavailableTop = tester.getTopLeft(find.text('视频预览暂不可用')).dy;
    final storyTop = tester.getTopLeft(find.byKey(const Key('content-story'))).dy;
    expect(storyTop, greaterThan(unavailableTop));
    expect(
      tester.widget<Text>(find.byKey(const Key('content-story'))).maxLines,
      4,
    );
    expect(find.text('展开背景故事'), findsOneWidget);

    await tester.tap(find.text('展开背景故事'));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('content-story'))).maxLines,
      isNull,
    );
    expect(find.text('收起背景故事'), findsOneWidget);
  });

  testWidgets('package playback shows a friendly fallback for legacy content',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const item = RemoteCatalogPackage(
      id: 'legacy',
      title: '旧内容包',
      source: 'hildors',
      format: 'package',
      tags: [],
      clips: [RemoteCatalogClip('dance', '舞蹈', 9)],
    );

    await tester.pumpWidget(const MaterialApp(
      home: RemotePackageDetailPage(item: item, catalog: [item]),
    ));
    final clip = find.byKey(const ValueKey('clip-legacy-dance'));
    await tester.ensureVisible(clip);
    await tester.tap(clip);
    await tester.pumpAndSettle();

    expect(find.text('背景故事待补充'), findsOneWidget);
  });

  testWidgets('short multiline story can still be expanded', (tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const item = RemoteCatalogPackage(
      id: 'poem',
      title: '五行故事',
      source: 'hildors',
      format: 'single',
      tags: [],
      description: '第一行\n第二行\n第三行\n第四行\n第五行',
      clips: [RemoteCatalogClip('main', '待机', 9)],
    );

    await tester.pumpWidget(const MaterialApp(
      home: RemotePackageDetailPage(item: item, catalog: [item]),
    ));
    await tester.ensureVisible(find.byKey(const ValueKey('clip-poem-main')));
    await tester.tap(find.byKey(const ValueKey('clip-poem-main')));
    await tester.pumpAndSettle();

    expect(find.text('展开背景故事'), findsOneWidget);
  });
}
