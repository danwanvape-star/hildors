import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_repository.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_page.dart';

Map<String, dynamic> item(String id, {bool withMedia = false}) => {
      'id': id,
      'title': '测试角色 $id',
      'status': 'published',
      'source': 'creator',
      'format': 'package',
      'coverPath': '/v1/covers/cover-$id',
      'tags': ['神话'],
      'clips': [
        {
          'id': '$id-clip',
          'title': '待机',
          'durationSeconds': 10.2,
          if (withMedia) 'previewPath': '/v1/media/video-id',
          if (withMedia) 'thumbnailPath': '/v1/media/video-id/thumbnail'
        }
      ],
    };

void main() {
  test('读取所有分页，保留包内独立视频', () async {
    final requests = <Uri>[];
    final repo =
        RemoteCatalogRepository('https://example.test', fetch: (uri) async {
      requests.add(uri);
      return jsonEncode({
        'items': [item(requests.length == 1 ? 'a' : 'b', withMedia: true)],
        'nextCursor': requests.length == 1 ? 'a' : null
      });
    });
    final packages = await repo.load();
    expect(packages.map((p) => p.id), ['a', 'b']);
    expect(packages.first.clips.single.durationSeconds, 10.2);
    expect(packages.first.clips.single.previewUrl,
        'https://example.test/v1/media/video-id');
    expect(packages.first.clips.single.thumbnailUrl,
        'https://example.test/v1/media/video-id/thumbnail');
    expect(packages.first.coverUrl, 'https://example.test/v1/covers/cover-a');
    expect(requests.last.queryParameters['cursor'], 'a');
  });
  test('分页重复和未发布内容不能静默混入目录', () async {
    final repeated = RemoteCatalogRepository('https://example.test',
        fetch: (_) async => jsonEncode({
              'items': [item('a')],
              'nextCursor': 'a'
            }));
    await expectLater(repeated.load(), throwsFormatException);
    expect(
        () => RemoteCatalogPackage.fromJson({...item('a'), 'status': 'draft'}),
        throwsFormatException);
    expect(() => RemoteCatalogRepository('https://user:secret@example.test'),
        throwsArgumentError);
  });
  testWidgets('目录加载失败可重试，详情只显示视频清单', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RemoteCatalogPage(load: () async {
      if (++calls == 1) throw Exception('private backend failure');
      return [RemoteCatalogPackage.fromJson(item('a'))];
    }))));
    await tester.pumpAndSettle();
    expect(find.text('暂时无法加载内容库'), findsOneWidget);
    expect(find.textContaining('private backend'), findsNothing);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('测试角色 a'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('测试角色 a'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('待机'), 300);
    await tester.pumpAndSettle();
    expect(find.text('包内视频'), findsOneWidget);
    expect(find.text('待机'), findsOneWidget);
    expect(find.text('下载到手机'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('窄屏大字号目录不溢出', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: Scaffold(
            body: RemoteCatalogPage(
                load: () async =>
                    [RemoteCatalogPackage.fromJson(item('a'))]))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
