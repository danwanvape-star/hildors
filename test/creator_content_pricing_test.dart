import 'package:hildors_cockpit/src/config/launch_config.dart';
import 'package:flutter/material.dart';
import 'package:hildors_cockpit/src/features/customization/creator_workbench_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/creator_content_repository.dart';
import 'package:hildors_cockpit/src/features/community/creator_content_page.dart';

class Transport implements CreatorContentTransport {
  Transport(
      {this.tier = 'partner',
      this.canUpload = true,
      this.capabilityFails = false,
      this.pending = false});
  final String tier;
  final bool canUpload, capabilityFails, pending;
  final calls = <Map<String, dynamic>>[];
  @override
  Future<CreatorContentResponse> request(
      {required String method,
      required String path,
      Map<String, dynamic>? body,
      String? filePath,
      String? contentType,
      int? ifMatch}) async {
    calls.add({'method': method, 'path': path, 'body': body});
    if (path.endsWith('content-capabilities')) {
      return capabilityFails
          ? const CreatorContentResponse(500, {})
          : CreatorContentResponse(200, {
              'canUpload': canUpload,
              'canSetPaid': tier == 'partner',
              'tier': tier
            });
    }
    if (path.contains('?')) {
      return CreatorContentResponse(200, {
        'items': [
          {...content, if (pending) 'submissionStatus': 'pending'}
        ]
      });
    }
    if (path == '/v1/content-tags') {
      return const CreatorContentResponse(200, {'items': []});
    }
    return CreatorContentResponse(200, {
      ...content,
      'version': 8,
      'clips': [
        {'id': 'a', 'title': 'Video', 'pricing': body!['pricing']}
      ]
    });
  }
}

final content = <String, dynamic>{
  'id': 'one',
  'title': 'Title',
  'description': 'Story',
  'format': 'single',
  'status': 'draft',
  'submissionStatus': 'draft',
  'version': 7,
  'tags': <String>[],
  'clips': [
    {
      'id': 'a',
      'title': 'Video',
      'pricing': {'mode': 'free', 'currency': 'USD', 'amountMinor': 0}
    }
  ]
};
void main() {
  for (final tier in ['standard', 'verified']) {
    testWidgets('$tier creator gets upload entrance but no paid controls',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: CreatorWorkbenchPage(
              repository:
                  RemoteCreatorContentRepository(Transport(tier: tier)))));
      expect(find.text('定制任务'),
          LaunchConfig.customizationOrders ? findsOneWidget : findsNothing);
      await tester.tap(find.text('上传内容 / 我的投稿'));
      await tester.pumpAndSettle();
      expect(find.text('创建投稿'), findsOneWidget);
      await tester.tap(find.text('Title'));
      await tester.pumpAndSettle();
      expect(find.textContaining('标准创作者、认证创作者仅可投稿'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('上传 MP4'), 300,
          scrollable: find
              .descendant(
                  of: find.byType(CreatorContentEditorPage),
                  matching: find.byType(Scrollable))
              .first);
      expect(find.text('设置价格'), findsNothing);
      expect(find.text('免费'), findsOneWidget);
    });
  }
  for (final fails in [false, true]) {
    testWidgets('denied or failed capabilities prevent uploading $fails',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: CreatorContentPage(
              repository: RemoteCreatorContentRepository(
                  Transport(canUpload: false, capabilityFails: fails)))));
      await tester.pumpAndSettle();
      expect(find.text('创建投稿'), findsNothing);
      expect(find.text('重试'), findsOneWidget);
    });
  }
  testWidgets('pending review has no pricing edit even for partner',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: CreatorContentPage(
            repository:
                RemoteCreatorContentRepository(Transport(pending: true)))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Title'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('免费'), 300,
        scrollable: find
            .descendant(
                of: find.byType(CreatorContentEditorPage),
                matching: find.byType(Scrollable))
            .first);
    expect(find.text('设置价格'), findsNothing);
    expect(find.text('上传 MP4'), findsNothing);
  });

  test('pricing uses exact decimal cents and current optimistic version',
      () async {
    final transport = Transport();
    final dynamic repo = RemoteCreatorContentRepository(transport);
    final dynamic capabilities = await repo.loadCapabilities();
    expect(capabilities.canSetPaid, true);
    final dynamic saved = await repo.updatePricing(
        CreatorContent.fromJson(content),
        clipId: 'a',
        amountMinor: 199);
    expect(saved.version, 8);
    expect(transport.calls.last['body'], {
      'version': 7,
      'pricing': {'mode': 'paid', 'currency': 'USD', 'amountMinor': 199}
    });
    expect(transport.calls.last['path'], '/v1/me/content/one/clips/a/pricing');
  });
  testWidgets(
      'partner pricing follows release profile and rejects invalid precision',
      (tester) async {
    final transport = Transport();
    await tester.pumpWidget(MaterialApp(
        home: CreatorContentPage(
            repository: RemoteCreatorContentRepository(transport))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Title'));
    await tester.pumpAndSettle();
    if (LaunchConfig.usFree) {
      expect(
          tester
              .widget<CreatorContentEditorPage>(
                  find.byType(CreatorContentEditorPage))
              .canSetPaid,
          isFalse);
      await tester.scrollUntilVisible(find.text('上传 MP4'), 300,
          scrollable: find
              .descendant(
                  of: find.byType(CreatorContentEditorPage),
                  matching: find.byType(Scrollable))
              .first);
      expect(find.text('上传 MP4'), findsOneWidget);
      expect(find.text('免费'), findsOneWidget);
      expect(find.text('设置价格'), findsNothing);
      expect(transport.calls.where((c) => c['method'] == 'POST'), isEmpty);
      expect(tester.takeException(), isNull);
      return;
    }
    await tester.scrollUntilVisible(find.text('设置价格'), 300,
        scrollable: find
            .descendant(
                of: find.byType(CreatorContentEditorPage),
                matching: find.byType(Scrollable))
            .first);
    await tester.tap(find.text('设置价格'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('付费'));
    await tester.pumpAndSettle();
    for (final invalid in ['1.999', '-1', '0', '1e2', '1000000']) {
      await tester.enterText(
          find.byKey(const Key('creator-price-usd')), invalid);
      await tester.tap(find.text('保存价格'));
      await tester.pumpAndSettle();
      expect(transport.calls.where((c) => c['method'] == 'POST'), isEmpty);
    }
    await tester.enterText(find.byKey(const Key('creator-price-usd')), '1.99');
    await tester.tap(find.text('保存价格'));
    await tester.pumpAndSettle();
    expect(find.text('USD 1.99'), findsOneWidget);
    await tester.tap(find.text('设置价格'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('免费'));
    await tester.tap(find.text('保存价格'));
    await tester.pumpAndSettle();
    expect(transport.calls.last['body'], {
      'version': 8,
      'pricing': {'mode': 'free', 'currency': 'USD', 'amountMinor': 0}
    });
  });
}
