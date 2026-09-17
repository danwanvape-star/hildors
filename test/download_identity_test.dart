import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/cloud_business_intake.dart';

void main() {
  late Directory dir;
  late File session;
  late HttpServer server;
  late CloudBusinessIntake cloud;
  final paths = <String>[];
  setUp(() async {
    paths.clear();
    dir = await Directory.systemTemp.createTemp('download-identity-');
    session = File('${dir.path}/session.json');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    cloud = CloudBusinessIntake(
        baseUrl: 'http://127.0.0.1:${server.port}', sessionFile: session);
    await session.writeAsString(jsonEncode(
        {'token': 'a' * 43, 'refreshToken': 'b' * 43, 'expiresAt': 0}));
  });
  tearDown(() async {
    await server.close(force: true);
    await dir.delete(recursive: true);
  });
  void respond({bool unauthorized = false}) {
    server.listen((r) async {
      paths.add(r.uri.path);
      if (r.uri.path == '/v1/session-refresh') {
        r.response.write(jsonEncode(
            {'token': 'c' * 43, 'refreshToken': 'b' * 43, 'expiresIn': 86400}));
      } else {
        r.response.statusCode = unauthorized ? 401 : 200;
        r.response.write(jsonEncode({'id': 'account-one'}));
      }
      await r.response.close();
    });
  }

  test('renewed identity persists stable account for offline reads', () async {
    respond();
    final identity = await cloud.downloadIdentity();
    expect(identity.accountId, 'account-one');
    expect(paths, ['/v1/session-refresh', '/v1/me']);
    final saved =
        jsonDecode(await session.readAsString()) as Map<String, dynamic>;
    saved['expiresAt'] = 0;
    await session.writeAsString(jsonEncode(saved));
    await cloud.orderRequest('GET', '/v1/me');
    await server.close(force: true);
    expect(await cloud.cachedDownloadAccountId(), 'account-one');
    expect(
        await CloudBusinessIntake(
                baseUrl: cloud.baseUri.toString(), sessionFile: session)
            .cachedDownloadAccountId(),
        'account-one');
  });
  test('different backend cannot reuse credentials or offline account',
      () async {
    respond();
    await cloud.downloadIdentity();
    final other = CloudBusinessIntake(
        baseUrl: 'http://localhost:${server.port}', sessionFile: session);
    expect(await other.cachedDownloadAccountId(), isNull);
    await expectLater(
        other.downloadIdentity(), throwsA(isA<CloudSessionRecoveryRequired>()));
    expect(paths.length, 2);
  });
  test('unauthorized identity cannot establish an offline account', () async {
    respond(unauthorized: true);
    await expectLater(cloud.downloadIdentity(), throwsA(isA<HttpException>()));
    expect(await cloud.cachedDownloadAccountId(), isNull);
    expect(paths.where((p) => p == '/v1/device-session'), isEmpty);
  });

  test('identity binding cannot overwrite a concurrently renewed credential',
      () async {
    final meStarted = Completer<void>();
    final releaseMe = Completer<void>();
    var renewals = 0;
    var otherReads = 0;
    server.listen((r) async {
      if (r.uri.path == '/v1/session-refresh') {
        renewals++;
        r.response.write(jsonEncode({
          'token': (renewals == 1 ? 'c' : 'd') * 43,
          'refreshToken': 'b' * 43,
          'expiresIn': 86400
        }));
      } else if (r.uri.path == '/v1/me') {
        meStarted.complete();
        await releaseMe.future;
        r.response.write(jsonEncode({'id': 'account-one'}));
      } else {
        r.response.statusCode = otherReads++ == 0 ? 401 : 200;
        r.response.write('{}');
      }
      await r.response.close();
    });
    final identity = cloud.downloadIdentity();
    await meStarted.future;
    await cloud.orderRequest('GET', '/other');
    releaseMe.complete();
    final resolved = await identity;
    final stored = jsonDecode(await session.readAsString());
    expect(stored['token'] == 'd' * 43, isTrue);
    expect(resolved.token == stored['token'], isTrue);
    expect(await cloud.cachedDownloadAccountId(), 'account-one');
  });
}
