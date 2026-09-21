import 'package:hildors_cockpit/l10n/generated/app_localizations_zh.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/cloud_business_intake.dart';
import 'package:hildors_cockpit/src/features/customization/cloud_email_identity.dart';
import 'package:hildors_cockpit/src/features/customization/cloud_order_submission.dart';
import 'package:hildors_cockpit/src/features/customization/cloud_orders_page.dart';

class _NetworkHttpOverrides extends HttpOverrides {}

void main() {
  test(
      'delayed unauthorized order request is never replayed after account switch',
      () async {
    await HttpOverrides.runWithHttpOverrides(() async {
      final dir = await Directory.systemTemp.createTemp('email_identity_race');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final arrived = Completer<void>(), release = Completer<void>();
      addTearDown(() async {
        if (!release.isCompleted) release.complete();
        await server.close(force: true);
        await dir.delete(recursive: true);
      });
      final origin = 'http://127.0.0.1:${server.port}', paths = <String>[];
      server.listen((request) async {
        paths.add(request.uri.path);
        await request.drain<void>();
        if (!arrived.isCompleted) arrived.complete();
        await release.future;
        request.response.statusCode = 401;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{}');
        await request.response.close();
      });
      final file = File('${dir.path}/session.json');
      await file.writeAsString(jsonEncode({
        'token': 'a' * 43,
        'refreshToken': 'b' * 43,
        'origin': origin,
        'accountId': 'old',
        'expiresAt': DateTime.now().millisecondsSinceEpoch + 3600000
      }));
      final service = CloudBusinessIntake(
          baseUrl: origin,
          sessionFile: file,
          emailRequest: (method, path, {document, token}) async =>
              CloudBusinessResponse(200, {
                'token': 'c' * 43,
                'refreshToken': 'd' * 43,
                'expiresIn': 3600,
                'userId': 'new',
                'email': 'new@example.com',
                'emailVerified': true
              }));
      final pending = service.orderRequest(
          'POST', '/v1/me/customization-orders',
          document: {'characterName': 'Draft'});
      final rejected =
          expectLater(pending, throwsA(isA<CloudSessionRecoveryRequired>()));
      await arrived.future;
      await service.verifyEmailSignIn('challenge', '123456');
      release.complete();
      await rejected;
      expect(paths, ['/v1/me/customization-orders']);
    }, _NetworkHttpOverrides());
  });

  test(
      'delayed unauthorized content request is never replayed after account switch',
      () async {
    await HttpOverrides.runWithHttpOverrides(() async {
      final dir = await Directory.systemTemp.createTemp('email_identity_race');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final arrived = Completer<void>(), release = Completer<void>();
      addTearDown(() async {
        if (!release.isCompleted) release.complete();
        await server.close(force: true);
        await dir.delete(recursive: true);
      });
      final origin = 'http://127.0.0.1:${server.port}', paths = <String>[];
      server.listen((request) async {
        paths.add(request.uri.path);
        await request.drain<void>();
        if (!arrived.isCompleted) arrived.complete();
        await release.future;
        request.response.statusCode = 401;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{}');
        await request.response.close();
      });
      final file = File('${dir.path}/session.json');
      await file.writeAsString(jsonEncode({
        'token': 'a' * 43,
        'refreshToken': 'b' * 43,
        'origin': origin,
        'accountId': 'old',
        'expiresAt': DateTime.now().millisecondsSinceEpoch + 3600000
      }));
      final service = CloudBusinessIntake(
          baseUrl: origin,
          sessionFile: file,
          emailRequest: (method, path, {document, token}) async =>
              CloudBusinessResponse(200, {
                'token': 'c' * 43,
                'refreshToken': 'd' * 43,
                'expiresIn': 3600,
                'userId': 'new',
                'email': 'new@example.com',
                'emailVerified': true
              }));
      final pending = service.contentRequest('POST', '/v1/me/reports',
          document: {'characterName': 'Draft'});
      final rejected =
          expectLater(pending, throwsA(isA<CloudSessionRecoveryRequired>()));
      await arrived.future;
      await service.verifyEmailSignIn('challenge', '123456');
      release.complete();
      await rejected;
      expect(paths, ['/v1/me/reports']);
    }, _NetworkHttpOverrides());
  });

  testWidgets('email access fits narrow order page with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = CloudBusinessIntake(
        baseUrl: 'https://example.test',
        emailRequest: (method, path, {document, token}) async =>
            const CloudBusinessResponse(
                200, {'enabled': false, 'requireOrderEmail': false}));
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: CloudOrdersPage(
            emailService: service,
            request: (method, path, {document, bytes, contentType}) async =>
                {'items': []})));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('邮箱登录 / 找回订单'));
    await tester.pumpAndSettle();
    expect(find.text(AppLocalizationsZh().errorServiceUnavailable),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('legacy token binds; same account preserves pending identity', () async {
    final dir = await Directory.systemTemp.createTemp('email_legacy');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/session.json');
    await file.writeAsString(jsonEncode({'token': 'a' * 43}));
    final service = CloudBusinessIntake(
        baseUrl: 'https://example.test',
        sessionFile: file,
        emailRequest: (method, path, {document, token}) async {
          expect(token, isNotNull);
          return CloudBusinessResponse(200, {
            'token': 'c' * 43,
            'refreshToken': 'd' * 43,
            'expiresIn': 3600,
            'userId': 'same',
            'email': 'test@example.com',
            'emailVerified': true
          });
        });
    await service.verifyEmailSignIn('challenge', '123456');
    expect(service.identityRevision, 1);
    await service.verifyEmailSignIn('challenge2', '123456');
    expect(service.identityRevision, 1);
  });

  test('expired verified access refreshes without minting guest', () async {
    final dir = await Directory.systemTemp.createTemp('email_refresh');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async {
      await server.close(force: true);
      await dir.delete(recursive: true);
    });
    final origin = 'http://127.0.0.1:${server.port}';
    final paths = <String>[];
    server.listen((request) async {
      paths.add(request.uri.path);
      await request.drain<void>();
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(
          request.uri.path == '/v1/session-refresh'
              ? {'token': 'c' * 43, 'refreshToken': 'd' * 43, 'expiresIn': 3600}
              : {'userId': 'same', 'email': 'a@b.com', 'emailVerified': true}));
      await request.response.close();
    });
    final file = File('${dir.path}/session.json');
    await file.writeAsString(jsonEncode({
      'token': 'a' * 43,
      'refreshToken': 'b' * 43,
      'origin': origin,
      'expiresAt': 1,
      'accountId': 'same'
    }));
    final service = CloudBusinessIntake(baseUrl: origin, sessionFile: file);
    expect(
        await HttpOverrides.runWithHttpOverrides(
            service.hasVerifiedEmail, _NetworkHttpOverrides()),
        true);
    expect(paths, ['/v1/session-refresh', '/v1/me/account']);
    expect(service.identityRevision, 0);
  });
  test('identity switch rejects an existing order upload retry', () async {
    var revision = 0, uploads = 0, creates = 0;
    final submission = CloudOrderSubmission(
        identityRevision: () => revision,
        request: (method, path, {document, bytes, contentType}) async {
          if (bytes == null) {
            creates++;
            return {'id': 'old-order'};
          }
          uploads++;
          throw const HttpException('upload interrupted');
        });
    final materials = [
      CloudOrderMaterial(name: 'a.png', bytes: Uint8List.fromList([1]))
    ];
    await expectLater(submission.submit({'characterName': 'A'}, materials),
        throwsA(isA<HttpException>()));
    revision++;
    await expectLater(submission.submit({'characterName': 'A'}, materials),
        throwsA(isA<CloudSessionRecoveryRequired>()));
    expect(creates, 1);
    expect(uploads, 1);
  });

  testWidgets(
      'disabled order gate preserves existing flow without account request',
      (tester) async {
    final calls = <String>[];
    final service = CloudBusinessIntake(
        baseUrl: 'https://example.test',
        emailRequest: (method, path, {document, token}) async {
          calls.add(path);
          return const CloudBusinessResponse(
              200, {'enabled': false, 'requireOrderEmail': false});
        });
    bool? allowed;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => TextButton(
                onPressed: () async {
                  allowed =
                      await ensureCloudOrderEmail(context, service: service);
                },
                child: const Text('submit')))));
    await tester.tap(find.text('submit'));
    await tester.pumpAndSettle();
    expect(allowed, true);
    expect(calls, ['/v1/email-auth/config']);
  });

  testWidgets(
      'disabled login shows service message and cancellation leaves draft',
      (tester) async {
    var sends = 0;
    final service = CloudBusinessIntake(
        baseUrl: 'https://example.test',
        emailRequest: (method, path, {document, token}) async {
          if (path.endsWith('/start')) sends++;
          return const CloudBusinessResponse(
              200, {'enabled': false, 'requireOrderEmail': false});
        });
    bool? loggedIn;
    final draft = TextEditingController(text: '保留角色草稿');
    addTearDown(draft.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                    body: Column(children: [
                  TextField(controller: draft),
                  TextButton(
                      onPressed: () async {
                        loggedIn = await showCloudEmailSignIn(context,
                            service: service);
                      },
                      child: const Text('login'))
                ])))));
    await tester.tap(find.text('login'));
    await tester.pumpAndSettle();
    expect(find.text(AppLocalizationsZh().errorServiceUnavailable),
        findsOneWidget);
    await tester.tap(find.text('发送验证码'));
    expect(sends, 0);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(loggedIn, false);
    expect(draft.text, '保留角色草稿');
  });
  test('expired session can sign in without guest creation or renewal',
      () async {
    final dir = await Directory.systemTemp.createTemp('email_identity');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/session.json');
    await file.writeAsString(jsonEncode({
      'token': 'a' * 43,
      'refreshToken': 'b' * 43,
      'origin': 'https://example.test',
      'expiresAt': 1,
      'accountId': 'old'
    }));
    final calls = <String>[];
    final service = CloudBusinessIntake(
        baseUrl: 'https://example.test',
        sessionFile: file,
        emailRequest: (method, path, {document, token}) async {
          calls.add(path);
          expect(token, isNull);
          return CloudBusinessResponse(
              200,
              path.endsWith('/start')
                  ? {
                      'challengeId': 'challenge',
                      'expiresIn': 600,
                      'resendAfter': 60
                    }
                  : {
                      'token': 'c' * 43,
                      'refreshToken': 'd' * 43,
                      'expiresIn': 3600,
                      'userId': 'new',
                      'email': 'test@example.com',
                      'emailVerified': true
                    });
        });
    await service.startEmailSignIn('test@example.com');
    await service.verifyEmailSignIn('challenge', '123456');
    expect(calls, ['/v1/email-auth/start', '/v1/email-auth/verify']);
    expect(await service.cachedDownloadAccountId(), 'new');
    expect(service.identityRevision, 1);
  });

  test('disabled provider reports failure without a fake challenge', () async {
    final dir = await Directory.systemTemp.createTemp('email_disabled');
    addTearDown(() => dir.delete(recursive: true));
    final service = CloudBusinessIntake(
        baseUrl: 'https://example.test',
        sessionFile: File('${dir.path}/session.json'),
        emailRequest: (method, path, {document, token}) async =>
            const CloudBusinessResponse(
                503, {'code': 'EMAIL_SERVICE_UNAVAILABLE'}));
    expect(service.startEmailSignIn('test@example.com'),
        throwsA(isA<HttpException>()));
  });
}
