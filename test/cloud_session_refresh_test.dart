import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/cloud_business_intake.dart';

void main() {
  late Directory directory;
  late HttpServer server;
  late File session;
  final oldToken = 'a' * 43, newToken = 'b' * 43, refresh = 'c' * 43;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('hildors-session-test-');
    session = File('${directory.path}/session.json');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  });
  tearDown(() async {
    await server.close(force: true);
    await directory.delete(recursive: true);
  });
  Future<void> reply(
      HttpRequest request, int code, Map<String, dynamic> body) async {
    request.response.statusCode = code;
    request.response.write(jsonEncode(body));
    await request.response.close();
  }

  CloudBusinessIntake service() => CloudBusinessIntake(
      baseUrl: 'http://127.0.0.1:${server.port}', sessionFile: session);
  test('expired access refreshes same identity and persists refresh credential',
      () async {
    await session.writeAsString(jsonEncode(
        {'token': oldToken, 'refreshToken': refresh, 'expiresAt': 0}));
    final paths = <String>[];
    server.listen((request) async {
      paths.add(request.uri.path);
      if (request.uri.path == '/v1/session-refresh') {
        expect(
            jsonDecode(await utf8.decoder.bind(request).join())['refreshToken'],
            refresh);
        await reply(request, 200,
            {'token': newToken, 'refreshToken': refresh, 'expiresIn': 86400});
      } else {
        expect(request.headers.value(HttpHeaders.authorizationHeader),
            'Bearer $newToken');
        await reply(request, 200, {'items': []});
      }
    });
    await service().orderRequest('GET', '/v1/me/customization-orders');
    expect(paths, ['/v1/session-refresh', '/v1/me/customization-orders']);
    expect(jsonDecode(await session.readAsString())['refreshToken'], refresh);
  });
  test('legacy expired access never creates a replacement user', () async {
    await session.writeAsString(jsonEncode({'token': oldToken}));
    final paths = <String>[];
    server.listen((request) async {
      paths.add(request.uri.path);
      await reply(request, 401, {});
    });
    await expectLater(
        service().orderRequest('GET', '/v1/me/customization-orders'),
        throwsA(isA<HttpException>()));
    expect(paths, ['/v1/me/session/renew']);
    expect(jsonDecode(await session.readAsString())['token'], oldToken);
  });
  test('unexpected 401 refreshes once before replaying the original request',
      () async {
    await session.writeAsString(jsonEncode({
      'token': oldToken,
      'refreshToken': refresh,
      'expiresAt':
          DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch
    }));
    var reads = 0;
    server.listen((request) async {
      if (request.uri.path == '/v1/session-refresh') {
        await reply(request, 200,
            {'token': newToken, 'refreshToken': refresh, 'expiresIn': 86400});
      } else {
        reads++;
        await reply(request, reads == 1 ? 401 : 200, {'items': []});
      }
    });
    await service().orderRequest('GET', '/v1/me/customization-orders');
    expect(reads, 2);
  });
  test('corrupted saved identity fails closed without network registration',
      () async {
    await session.writeAsString('{broken');
    var calls = 0;
    server.listen((request) async {
      calls++;
      await reply(request, 201, {'token': newToken});
    });
    await expectLater(
        service().orderRequest('GET', '/v1/me/customization-orders'),
        throwsA(isA<HttpException>()));
    expect(calls, 0);
  });
  test(
      'creator profile exposes unrecoverable identity instead of pretending missing',
      () async {
    await session.writeAsString(jsonEncode({'token': oldToken}));
    server.listen((request) async {
      await reply(request, 401, {});
    });
    await expectLater(
        service().loadCreatorProfile(), throwsA(isA<HttpException>()));
  });
  test('valid legacy access is upgraded without creating a user', () async {
    await session.writeAsString(jsonEncode({'token': oldToken}));
    final paths = <String>[];
    server.listen((request) async {
      paths.add(request.uri.path);
      await reply(
          request,
          200,
          request.uri.path == '/v1/me/session/renew'
              ? {'token': newToken, 'refreshToken': refresh, 'expiresIn': 86400}
              : {'status': 'approved'});
    });
    expect((await service().loadCreatorProfile())?['status'], 'approved');
    expect(paths, ['/v1/me/session/renew', '/v1/me/creator-profile']);
  });
}
