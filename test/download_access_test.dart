import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/download_access_repository.dart';

void main() {
  test(
      'access gate handles no session, disabled, unavailable, malformed and expired responses',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var calls = 0, status = 200;
    var data = <String, dynamic>{'canDownload': true, 'reason': 'ALLOWED'};
    server.listen((req) async {
      calls++;
      expect(req.uri.path, '/v1/me/packages/p/clips/c/access');
      req.response.statusCode = status;
      req.response.write(jsonEncode(data));
      await req.response.close();
    });
    try {
      final gate = DownloadAccessRepository(
          Uri.parse('http://127.0.0.1:${server.port}'));
      final token = List.filled(43, 'a').join();
      expect(await gate.check('p', 'c', null), DownloadAccess.signInRequired);
      expect(calls, 0);
      expect(await gate.check('p', 'c', token), DownloadAccess.allowed);
      data = {'canDownload': false, 'reason': 'DOWNLOAD_NOT_ENABLED'};
      expect(await gate.check('p', 'c', token), DownloadAccess.disabled);
      data = {'canDownload': false, 'reason': 'CONTENT_UNAVAILABLE'};
      expect(await gate.check('p', 'c', token), DownloadAccess.unavailable);
      data = {'canDownload': true, 'reason': 'CONTENT_UNAVAILABLE'};
      await expectLater(gate.check('p', 'c', token), throwsFormatException);
      status = 401;
      expect(await gate.check('p', 'c', token), DownloadAccess.signInRequired);
    } finally {
      await server.close(force: true);
    }
  });
}
