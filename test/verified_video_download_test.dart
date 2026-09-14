import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/verified_video_download.dart';

void main() {
  test('verified download commits only complete bytes and cleans failures',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('hildors-cache-test-');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final bytes = utf8.encode('download fixture');
    var corrupt = false, foreignPath = false, unauthorized = false;
    final token = List.filled(43, 'a').join();
    server.listen((req) async {
      expect(req.headers.value('authorization'), 'Bearer $token');
      if (unauthorized) {
        req.response.statusCode = 401;
      } else if (req.uri.path.endsWith('/manifest')) {
        req.response.write(jsonEncode({
          'packageId': 'p',
          'clipId': 'c',
          'bytes': bytes.length,
          'sha256': sha256.convert(bytes).toString(),
          'contentType': 'video/mp4',
          'authorizationRequired': true,
          'downloadPath': foreignPath
              ? 'https://example.com/steal'
              : '/v1/me/packages/p/clips/c/download'
        }));
      } else {
        req.response.add(corrupt ? List.filled(bytes.length, 0) : bytes);
      }
      await req.response.close();
    });
    try {
      final service = VerifiedVideoDownload(
          Uri.parse('http://127.0.0.1:${server.port}'), directory);
      Future<File> run() =>
          service.download(packageId: 'p', clipId: 'c', sessionToken: token);
      final file = await run();
      expect(await file.readAsBytes(), bytes);
      corrupt = true;
      await expectLater(run(), throwsFormatException);
      foreignPath = true;
      await expectLater(run(), throwsFormatException);
      unauthorized = true;
      await expectLater(run(), throwsA(isA<HttpException>()));
      expect(await directory.list().length, 1);
      expect(await file.readAsBytes(), bytes);
      expect(
          () =>
              VerifiedVideoDownload(Uri.parse('http://example.com'), directory),
          throwsArgumentError);
    } finally {
      await server.close(force: true);
      await directory.delete(recursive: true);
    }
  });
}
