import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hildors_cockpit/src/features/customization/creator_application_page.dart';
import 'package:hildors_cockpit/src/features/community/creator_content_repository.dart';
import 'package:hildors_cockpit/src/features/customization/creator_application_repository.dart';

class Transport implements CreatorContentTransport {
  final calls = <Map<String, dynamic>>[];
  CreatorContentResponse response = const CreatorContentResponse(200, {
    'status': 'draft',
    'version': 1,
    'applicationVideos': [],
  });
  @override
  Future<CreatorContentResponse> request(
      {required String method,
      required String path,
      Map<String, dynamic>? body,
      String? filePath,
      String? contentType,
      int? ifMatch}) async {
    calls.add({
      'method': method,
      'path': path,
      'body': body,
      'filePath': filePath,
      'ifMatch': ifMatch
    });
    return response;
  }
}

void main() {
  testWidgets('oversized certification video is rejected before upload',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final directory = Directory.systemTemp.createTempSync('creator-limit');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/large.mp4');
    final handle = file.openSync(mode: FileMode.write);
    handle.truncateSync(15000001);
    handle.closeSync();
    final transport = WorkflowTransport();
    await tester.pumpWidget(MaterialApp(
        home: CreatorApplicationPage(
      repository: CreatorApplicationRepository(transport: transport),
      pickVideos: () async => [file.path],
    )));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('上传本人作品'));
    await tester.tap(find.text('上传本人作品'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('请压缩后重新选择'), findsOneWidget);
    expect(transport.firstUpload, isTrue);
  });
  testWidgets('upload explains missing email instead of silently disabling',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var picked = false;
    final transport = WorkflowTransport();
    transport.profile!['email'] = '';
    await tester.pumpWidget(MaterialApp(
        home: CreatorApplicationPage(
      repository: CreatorApplicationRepository(transport: transport),
      pickVideos: () async {
        picked = true;
        return [];
      },
    )));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('上传本人作品'));
    expect(
        tester
            .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, '上传本人作品'))
            .onPressed,
        isNotNull);
    await tester.tap(find.text('上传本人作品'));
    await tester.pumpAndSettle();
    expect(find.textContaining('请填写有效邮箱'), findsWidgets);
    expect(picked, isFalse);
  });
  testWidgets('creator name rejects Chinese and numeric-only names',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: CreatorApplicationPage(
      repository: CreatorApplicationRepository(transport: WorkflowTransport()),
    )));
    await tester.pumpAndSettle();
    for (final value in ['若谷', '12345', 'Nova Studio']) {
      await tester.enterText(find.byKey(const Key('application-name')), value);
      await tester.pump();
      expect(find.textContaining('至少包含一个英文字母'), findsWidgets);
    }
  });
  testWidgets('failed draft save retains every selected video for retry',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final transport = WorkflowTransport()..failSave = true;
    await tester.pumpWidget(MaterialApp(
        home: CreatorApplicationPage(
      repository: CreatorApplicationRepository(transport: transport),
      pickVideos: () async => ['a.mp4', 'b.mp4'],
    )));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('上传本人作品'));
    await tester.tap(find.text('上传本人作品'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('重试上传'), findsNWidgets(2));
  });
  test('duplicate email and invalid application show actionable messages',
      () async {
    for (final item in {
      'EMAIL_IN_USE': '邮箱',
      'INVALID_CREATOR_APPLICATION': '协议'
    }.entries) {
      final transport = Transport()
        ..response = CreatorContentResponse(409, {'code': item.key});
      await expectLater(
          CreatorApplicationRepository(transport: transport).save({}),
          throwsA(isA<FormatException>()
              .having((e) => e.message, 'message', contains(item.value))));
    }
  });
  testWidgets(
      'video workflow keeps failed batch for retry and submits latest version',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final directory =
        Directory.systemTemp.createTempSync('creator-application-test');
    addTearDown(() => directory.deleteSync(recursive: true));
    final files = ['a.mp4', 'b.mp4']
        .map((name) =>
            File('${directory.path}/$name')..writeAsBytesSync([1, 2, 3]))
        .toList();
    final transport = WorkflowTransport();
    await tester.pumpWidget(MaterialApp(
        home: CreatorApplicationPage(
            repository: CreatorApplicationRepository(transport: transport),
            pickVideos: () async => files.map((f) => f.path).toList())));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '提交创作者申请'))
            .onPressed,
        isNull);
    await tester.ensureVisible(find.text('上传本人作品'));
    await tester.tap(find.text('上传本人作品'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.byTooltip('重试上传'), findsNWidgets(2));
    for (var i = 0; i < 2; i++) {
      await tester.ensureVisible(find.byTooltip('重试上传').first);
      await tester.tap(find.byTooltip('重试上传').first);
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
    }
    expect(find.byTooltip('重试上传'), findsNothing);
    expect(find.byTooltip('移除作品'), findsNWidgets(2));
    await tester.ensureVisible(find.text('提交创作者申请'));
    await tester.tap(find.text('提交创作者申请'));
    await tester.pumpAndSettle();
    expect(find.text('创作者申请审核中'), findsOneWidget);
    expect(transport.stale, isFalse);
    expect(transport.profile!['version'], 8);
  });
  testWidgets('approved creator sees human grade', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: CreatorApplicationPage(
            repository: CreatorApplicationRepository(
                transport: PageTransport(
                    {'status': 'approved', 'abilityLevel': 'legend'})))));
    await tester.pumpAndSettle();
    expect(find.text('创作等级：大神'), findsOneWidget);
    expect(find.text('进入创作者工作台'), findsOneWidget);
  });
  testWidgets('pending review is locked and shows the review reason',
      (tester) async {
    final transport = PageTransport({
      'status': 'pending',
      'applicationVersion': 2,
      'version': 2,
      'reviewNote': '等待人工审核'
    });
    await tester.pumpWidget(MaterialApp(
        home: CreatorApplicationPage(
            repository: CreatorApplicationRepository(transport: transport))));
    await tester.pumpAndSettle();
    expect(find.text('创作者申请审核中'), findsOneWidget);
    expect(find.text('等待人工审核'), findsOneWidget);
    expect(find.text('上传本人作品'), findsNothing);
  });
  testWidgets(
      'draft offers system roles and four directions without portfolio URL',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: CreatorApplicationPage(
            repository:
                CreatorApplicationRepository(transport: PageTransport(null)))));
    await tester.pumpAndSettle();
    expect(find.text('系统角色'), findsOneWidget);
    expect(find.text('擅长角色'), findsOneWidget);
    expect(find.text('擅长内容方向'), findsOneWidget);
    expect(find.text('作品集链接'), findsNothing);
  });
  test('application uses active system tags and fixed directions', () async {
    final transport = Transport()
      ..response = const CreatorContentResponse(200, {
        'items': [
          {'id': 'a', 'name': '系统角色', 'active': true},
          {'id': 'b', 'name': '停用角色', 'active': false},
        ]
      });
    final repository = CreatorApplicationRepository(transport: transport);
    expect(await repository.loadTags(), ['系统角色']);
    expect(creatorApplicationDirections, ['简单动作', '歌舞表演', '特效炫技', '角色成长']);
  });
  test('private upload and submit carry the latest version', () async {
    final transport = Transport();
    final repository = CreatorApplicationRepository(transport: transport);
    await repository.upload('/private/my work.mp4', 7);
    expect(transport.calls.single['ifMatch'], 7);
    expect(transport.calls.single['path'],
        '/v1/me/creator-application/videos?name=my%20work.mp4');
    await repository.submit(8);
    expect(transport.calls.last['body'], {'version': 8});
  });
  test('pending and suspended cannot edit; grading is never guessed', () {
    for (final status in ['pending', 'suspended', 'approved']) {
      expect(
          CreatorApplication({'status': status, 'applicationVersion': 2})
              .editable,
          isFalse);
    }
    expect(CreatorApplication({'status': 'rejected'}).editable, isTrue);
    expect(CreatorApplication({'abilityLevel': 'master'}).grade, '宗师');
    expect(CreatorApplication({'status': 'approved'}).grade, isNull);
    expect(CreatorApplication({'status': 'pending'}).editable, isTrue);
  });
  test('processor busy reports retry instead of a stale application', () async {
    final transport = Transport()
      ..response =
          const CreatorContentResponse(409, {'code': 'PROCESSOR_BUSY'});
    await expectLater(
        CreatorApplicationRepository(transport: transport).upload('a.mp4', 1),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('稍后重试'))));
  });
}

class WorkflowTransport extends PageTransport {
  WorkflowTransport()
      : super({
          'version': 1,
          'status': 'draft',
          'applicationVersion': 2,
          'displayName': 'Creator2026',
          'email': 'creator@example.com',
          'characterTags': ['系统角色'],
          'skillTags': ['简单动作'],
          'marketRegion': 'CN',
          'adultConfirmed': true,
          'agreementAccepted': true,
          'applicationVideos': <Map<String, dynamic>>[]
        });
  bool firstUpload = true, stale = false, failSave = false;
  @override
  Future<CreatorContentResponse> request(
      {required String method,
      required String path,
      Map<String, dynamic>? body,
      String? filePath,
      String? contentType,
      int? ifMatch}) async {
    if (method == 'GET') return super.request(method: method, path: path);
    if (failSave && method == 'POST') {
      return const CreatorContentResponse(409, {'code': 'EMAIL_IN_USE'});
    }
    final current = profile!;
    if ((ifMatch ?? body?['version']) != current['version']) stale = true;
    if (method == 'PUT' && firstUpload) {
      firstUpload = false;
      return const CreatorContentResponse(409, {'code': 'PROCESSOR_BUSY'});
    }
    current['version'] = (current['version'] as int) + 1;
    if (method == 'PUT') {
      (current['applicationVideos'] as List).add({
        'id': 'v${current['version']}',
        'name': filePath!.replaceAll('\\', '/').split('/').last
      });
    }
    if (path.endsWith('/submit')) current['status'] = 'pending';
    return CreatorContentResponse(200, Map.of(current));
  }
}

class PageTransport extends Transport {
  PageTransport(this.profile);
  final Map<String, dynamic>? profile;
  @override
  Future<CreatorContentResponse> request(
      {required String method,
      required String path,
      Map<String, dynamic>? body,
      String? filePath,
      String? contentType,
      int? ifMatch}) async {
    if (path == '/v1/content-tags') {
      return const CreatorContentResponse(200, {
        'items': [
          {'id': 'a', 'name': '系统角色', 'active': true}
        ]
      });
    }
    return CreatorContentResponse(profile == null ? 404 : 200, profile ?? {});
  }
}
