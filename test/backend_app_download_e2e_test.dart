import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/download_access_repository.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_repository.dart';
import 'package:hildors_cockpit/src/features/community/verified_video_download.dart';
import 'package:hildors_cockpit/src/features/community/video_download_controller.dart';

void main() {
  test(
      'real backend publication to App verified download and cache restoration',
      () async {
    final cache = await Directory.systemTemp.createTemp('hildors-client-e2e-');
    final process =
        await Process.start('node', ['backend/fixtures/app-download-e2e.mjs']);
    // Never print the fixture handshake: it contains ephemeral test credentials.
    process.stderr.drain<void>();
    final output =
        process.stdout.transform(utf8.decoder).transform(const LineSplitter());
    VideoDownloadController? first, reopened;
    try {
      final line = await output.first.timeout(const Duration(seconds: 90));
      final config = jsonDecode(line) as Map<String, dynamic>;
      final base = Uri.parse(config['base'] as String);
      final id = config['packageId'] as String,
          token = config['token'] as String;
      final catalog = await RemoteCatalogRepository(base.toString()).load();
      expect(catalog.single.id, id);
      expect(catalog.single.clips.single.id, 'clip');
      final gate = DownloadAccessRepository(base);
      expect(await gate.check(id, 'clip', null), DownloadAccess.signInRequired);
      expect(await gate.check(id, 'clip', token), DownloadAccess.allowed);
      final service = VerifiedVideoDownload(base, cache);
      first = VideoDownloadController(service, packageId: id, clipId: 'clip');
      await first.start(token);
      expect(first.status, VideoDownloadStatus.complete);
      final sourceHash = await sha256
          .bind(File('assets/videos/showcase/showcase_02.mp4').openRead())
          .first;
      expect(await sha256.bind(first.file!.openRead()).first, sourceHash);
      reopened =
          VideoDownloadController(service, packageId: id, clipId: 'clip');
      await reopened.restore();
      expect(reopened.status, VideoDownloadStatus.complete);
      expect(reopened.file!.path, first.file!.path);

      final client = HttpClient();
      try {
        final request =
            await client.postUrl(base.resolve('/admin/packages/$id/withdraw'));
        request.headers.set(
            HttpHeaders.authorizationHeader, 'Bearer ${config['adminToken']}');
        request.write(jsonEncode({'version': config['version']}));
        final response = await request.close();
        expect(response.statusCode, 200);
        await response.drain<void>();
      } finally {
        client.close(force: true);
      }
      expect(await gate.check(id, 'clip', token), DownloadAccess.unavailable);
      await expectLater(
          service.download(packageId: id, clipId: 'clip', sessionToken: token),
          throwsA(isA<HttpException>()));
      expect(await first.file!.exists(),
          true); // Withdrawal cannot erase an existing local copy.
    } finally {
      first?.dispose();
      reopened?.dispose();
      await process.stdin.close();
      try {
        await process.exitCode.timeout(const Duration(seconds: 10));
      } on Object {
        process.kill();
        await process.exitCode;
      }
      await cache.delete(recursive: true);
    }
  },
      skip: Platform.environment['HILDORS_APP_E2E'] != '1',
      timeout: const Timeout(Duration(minutes: 3)));
}
