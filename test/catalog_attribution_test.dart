import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_repository.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_page.dart';

Map<String, dynamic> record(String id,
        {String creatorId = 'artist-a', bool anonymous = false}) =>
    {
      'id': id,
      'title': '角色 $id',
      'status': 'published',
      'source': 'creator',
      'format': 'package',
      'description': '星际舞者的角色简介',
      'tags': ['科幻'],
      'creator': {'id': creatorId, 'name': 'Nova', 'anonymous': anonymous},
      'clips': [
        {'id': '$id-one', 'title': '待机 $id', 'durationSeconds': 10},
        {'id': '$id-two', 'title': '舞蹈 $id', 'durationSeconds': 12}
      ],
    };

void main() {
  testWidgets(
      'per-item credit survives repository and creator space groups stable IDs only',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = RemoteCatalogRepository('https://example.test',
        fetch: (_) async => jsonEncode({
              'items': [
                record('a'),
                record('b'),
                record('other', creatorId: 'artist-b'),
                record('hidden', anonymous: true)
              ]
            }));
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RemoteCatalogPage(load: repo.load))));
    await tester.pumpAndSettle();
    expect(find.text('匿名创作者'), findsOneWidget);
    expect(find.text('Nova'), findsNWidgets(3));
    await tester.tap(find.text('角色 a'));
    await tester.pumpAndSettle();
    expect(find.text('星际舞者的角色简介'), findsOneWidget);
    final one = tester.getTopLeft(find.text('待机 a'));
    final two = tester.getTopLeft(find.text('舞蹈 a'));
    expect(one.dy, two.dy);
    expect(one.dx, lessThan(two.dx));
    await tester.tap(find.text('Nova'));
    await tester.pumpAndSettle();
    expect(find.text('角色 a'), findsOneWidget);
    expect(find.text('角色 b'), findsOneWidget);
    expect(find.text('角色 other'), findsNothing);
    expect(find.text('角色 hidden'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'anonymous attribution hides identity and compact detail tolerates large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 1000);
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
                load: () async => [
                      RemoteCatalogPackage.fromJson(
                          record('hidden', anonymous: true))
                    ]))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('角色 hidden'));
    await tester.tap(find.text('角色 hidden'));
    await tester.pumpAndSettle();
    expect(find.text('Nova'), findsNothing);
    expect(find.text('匿名创作者'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '匿名创作者'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'clip actions open for the selected video rather than every thumbnail',
      (tester) async {
    final selected = <String>[];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: RemoteCatalogPage(
      load: () async => [RemoteCatalogPackage.fromJson(record('a'))],
      clipActions: (package, clip) => TextButton(
          onPressed: () => selected.add(clip.id),
          child: Text('加入 ${clip.title}')),
    ))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('角色 a'));
    await tester.tap(find.text('角色 a'));
    await tester.pumpAndSettle();
    expect(find.text('加入 舞蹈 a'), findsNothing);
    await tester.ensureVisible(find.text('舞蹈 a'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('舞蹈 a'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('加入 舞蹈 a'));
    expect(selected, ['a-two']);
    expect(find.text('加入 待机 a'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
