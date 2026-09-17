import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/owned_download_page.dart';
import 'package:hildors_cockpit/src/features/community/owned_package_download.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_repository.dart';

const package = RemoteCatalogPackage(
    id: 'p',
    title: '测试角色',
    source: 'hildors',
    format: 'package',
    tags: [],
    clips: [RemoteCatalogClip('a', '待机', 3), RemoteCatalogClip('b', '动作', 4)]);

// Isolate widget layout from network; authorization/download behavior is covered
// by the real HTTP controller and backend integration suites.
class PageController extends OwnedPackageDownloadController {
  PageController()
      : super(
            package: package,
            baseUri: Uri.parse('https://example.test'),
            identity: () async =>
                throw StateError('UI must not resolve a session'));
  final requested = <String>[];
  @override
  Future<void> prepare() async {}
  @override
  Future<void> download(List<RemoteCatalogClip> clips) async {
    requested.addAll(clips.map((c) => c.id));
  }
}

void main() {
  testWidgets(
      'unowned download actions are disabled on narrow large-text screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final task = PageController()..message = '当前视频暂不可下载';
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!),
        home: OwnedDownloadPage(package: package, controller: task)));
    await tester.pumpAndSettle();
    final all = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, '下载可用视频'));
    expect(all.onPressed, isNull);
    for (final button
        in tester.widgetList<OutlinedButton>(find.byType(OutlinedButton))) {
      expect(button.onPressed, isNull);
    }
    expect(find.text('当前视频暂不可下载'), findsOneWidget);
    expect(find.textContaining('领取'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('whole package action selects only not-yet-downloaded clips',
      (tester) async {
    final task = PageController()
      ..allowed.addAll(['a', 'b'])
      ..completed.add('a');
    await tester.pumpWidget(MaterialApp(
        home: OwnedDownloadPage(package: package, controller: task)));
    await tester.pumpAndSettle();
    expect(find.text('已下载 1/2'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '下载可用视频'));
    expect(task.requested, ['b']);
    expect(find.text('查看我的角色'), findsOneWidget);
  });
  testWidgets('mixed bulk action selects allowed missing videos only',
      (tester) async {
    final task = PageController()..allowed.add('a');
    await tester.pumpWidget(MaterialApp(
        home: OwnedDownloadPage(package: package, controller: task)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '下载可用视频'));
    expect(task.requested, ['a']);
  });
  testWidgets(
      'paid entry explains unavailable purchase without opening download page',
      (tester) async {
    final paid = RemoteCatalogClip('paid', '付费', 3,
        pricing: ClipPricing.fromJson(
            {'mode': 'paid', 'currency': 'USD', 'amountMinor': 1299}));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: OwnedDownloadButton(
                package: RemoteCatalogPackage(
                    id: 'paid',
                    title: '付费',
                    source: 'hildors',
                    format: 'single',
                    tags: [],
                    clips: [paid])))));
    await tester.tap(find.text('US\$ 12.99 · 购买下载'));
    await tester.pumpAndSettle();
    expect(find.text('暂未开放购买'), findsOneWidget);
    expect(find.byType(OwnedDownloadPage), findsNothing);
  });
}
