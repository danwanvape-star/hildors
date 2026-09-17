import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/downloaded_character_store.dart';
import 'package:hildors_cockpit/src/features/community/owned_package_download.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_repository.dart';
import 'package:hildors_cockpit/src/features/customization/cloud_business_intake.dart';

void main() {
  test(
      'real owned content downloads into account library and withdrawal blocks new transfer',
      () async {
    final root = await Directory.systemTemp.createTemp('owned-app-e2e-');
    final process =
        await Process.start('node', ['backend/fixtures/app-download-e2e.mjs']);
    process.stderr.drain<void>();
    OwnedPackageDownloadController? task;
    try {
      final line = await process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 90));
      // Ephemeral credentials stay inside this fixture, never in logs.
      final config = jsonDecode(line) as Map<String, dynamic>;
      final base = Uri.parse(config['base'] as String);
      final session = File('${root.path}/session.json');
      await session.writeAsString(jsonEncode({'token': config['token']}));
      final cloud =
          CloudBusinessIntake(baseUrl: base.toString(), sessionFile: session);
      final package =
          (await RemoteCatalogRepository(base.toString()).load()).single;
      final store = DownloadedCharacterStore(
          Directory('${root.path}/media'), base.origin);
      task = OwnedPackageDownloadController(
          package: package,
          baseUri: base,
          identity: cloud.downloadIdentity,
          storeForAccount: (_, __) async => store);
      await task.prepare();
      expect(task.allowed, {package.clips.single.id});
      await task.download(package.clips);
      expect(task.completed, {package.clips.single.id});
      final saved = (await store.load()).single;
      expect(saved.title, package.title);
      expect(saved.videos.single.asset, isFalse);
      expect(await File(saved.videos.single.source).length(), greaterThan(0));
      expect(await cloud.cachedDownloadAccountId(), isNotNull);

      final client = HttpClient();
      try {
        final request = await client
            .postUrl(base.resolve('/admin/packages/${package.id}/withdraw'));
        request.headers.set('authorization', 'Bearer ${config['adminToken']}');
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode({'version': config['version']}));
        final response = await request.close();
        await response.drain<void>();
        expect(response.statusCode, 200);
      } finally {
        client.close(force: true);
      }
      await store.remove(package.id);
      await task.prepare();
      await task.download(package.clips);
      expect(await store.load(), isEmpty);
      expect(task.completed, isEmpty);
    } finally {
      task?.dispose();
      await process.stdin.close();
      try {
        await process.exitCode.timeout(const Duration(seconds: 10));
      } on Object {
        process.kill();
        await process.exitCode;
      }
      await root.delete(recursive: true);
    }
  }, skip: Platform.environment['HILDORS_APP_E2E'] != '1');
}
