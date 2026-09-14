import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/verified_video_download.dart';
import 'package:hildors_cockpit/src/features/community/video_download_controller.dart';
import 'package:hildors_cockpit/src/features/community/verified_video_cache.dart';

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
      final restored =
          VideoDownloadController(service, packageId: 'p', clipId: 'c');
      await restored.restore();
      expect(restored.status, VideoDownloadStatus.complete);
      expect(restored.file!.path, file.path);
      restored.dispose();
      expect(
          await VerifiedVideoCache(directory, 'https://different.test')
              .find('p', 'c'),
          isNull);
      expect(
          await VerifiedVideoCache(directory, service.baseUri.origin)
              .find('p', 'other'),
          isNull);
      unauthorized = false;
      foreignPath = false;
      corrupt = false;
      final controller =
          VideoDownloadController(service, packageId: 'p', clipId: 'c');
      var cancelOnce = true;
      controller.addListener(() {
        if (cancelOnce && controller.status == VideoDownloadStatus.verifying) {
          cancelOnce = false;
          controller.cancel();
        }
      });
      await controller.start(token);
      expect(controller.status, VideoDownloadStatus.cancelled);
      expect(controller.file, isNull);
      expect(await directory.list().length, 1);
      corrupt = true;
      await controller.start(token);
      expect(controller.status, VideoDownloadStatus.failed);
      corrupt = false;
      await controller.start(token);
      expect(controller.status, VideoDownloadStatus.complete);
      expect(await controller.file!.readAsBytes(), bytes);
      final saved = controller.file;
      await controller.start(token);
      expect(controller.file, saved);
      controller.dispose();
      final cancelled = DownloadCancellation()..cancel();
      await expectLater(
          service.download(
              packageId: 'p',
              clipId: 'c',
              sessionToken: token,
              cancellation: cancelled),
          throwsA(isA<DownloadCancelled>()));
      corrupt = true;
      await expectLater(run(), throwsFormatException);
      foreignPath = true;
      await expectLater(run(), throwsFormatException);
      unauthorized = true;
      await expectLater(run(), throwsA(isA<HttpException>()));
      expect(await directory.list().length, 2);
      expect(await file.readAsBytes(), bytes);
      await file.writeAsBytes(List.filled(bytes.length, 0));
      await saved!.writeAsBytes(List.filled(bytes.length, 0));
      final missing =
          VideoDownloadController(service, packageId: 'p', clipId: 'c');
      await missing.restore();
      expect(missing.file, isNull);
      expect(missing.status, VideoDownloadStatus.idle);
      missing.dispose();
      expect(await directory.list().length,
          2); // Bad files are ignored, not deleted.
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
