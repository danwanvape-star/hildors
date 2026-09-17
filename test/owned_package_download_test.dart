import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/downloaded_character_store.dart';
import 'package:hildors_cockpit/src/features/community/owned_package_download.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_repository.dart';
import 'package:hildors_cockpit/src/features/community/verified_video_download.dart';

void main() {
  late Directory directory;
  late HttpServer server;
  late Uri origin;
  late DownloadedCharacterStore store;
  var owned = false, corrupt = false;
  var transfers = 0;
  final token = List.filled(43, 'a').join();
  final bytes = utf8.encode('verified local video');
  const package = RemoteCatalogPackage(
      id: 'p',
      title: '角色',
      source: 'hildors',
      format: 'package',
      tags: [],
      description: '背景故事',
      clips: [
        RemoteCatalogClip('one', '待机', 3),
        RemoteCatalogClip('two', '舞蹈', 5)
      ]);
  setUp(() async {
    owned = false;
    corrupt = false;
    transfers = 0;
    directory = await Directory.systemTemp.createTemp('owned-download-test-');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    origin = Uri.parse('http://127.0.0.1:${server.port}');
    store = DownloadedCharacterStore(directory, origin.origin);
    server.listen((req) async {
      if (req.headers.value('authorization') != 'Bearer $token') {
        req.response.statusCode = 401;
      } else if (req.uri.path.endsWith('/access')) {
        req.response.write(jsonEncode({
          'canDownload': owned,
          'reason': owned ? 'ALLOWED' : 'CONTENT_UNAVAILABLE'
        }));
      } else if (!owned) {
        req.response.statusCode = 404;
      } else if (req.uri.path.endsWith('/manifest')) {
        final clip = req.uri.pathSegments[5];
        req.response.write(jsonEncode({
          'packageId': 'p',
          'clipId': clip,
          'bytes': bytes.length,
          'sha256': sha256.convert(bytes).toString(),
          'contentType': 'video/mp4',
          'authorizationRequired': true,
          'downloadPath': '/v1/me/packages/p/clips/$clip/download'
        }));
      } else {
        transfers++;
        req.response.add(corrupt ? List.filled(bytes.length, 0) : bytes);
      }
      await req.response.close();
    });
  });
  tearDown(() async {
    await server.close(force: true);
    await directory.delete(recursive: true);
  });
  OwnedPackageDownloadController controller() => OwnedPackageDownloadController(
      package: package,
      baseUri: origin,
      identity: () async => (accountId: 'account', token: token),
      storeForAccount: (_, __) async => store);

  test('unowned content never downloads or enters My Characters', () async {
    final task = controller();
    addTearDown(task.dispose);
    await task.prepare();
    await task.download(package.clips);
    expect(transfers, 0);
    expect(await store.load(), isEmpty);
    expect(task.completed, isEmpty);
    expect(task.message, contains('领取'));
  });
  test(
      'owned package merges verified clips, restores offline and avoids repeats',
      () async {
    owned = true;
    final task = controller();
    addTearDown(task.dispose);
    await task.prepare();
    await task.download([package.clips.first]);
    expect(task.completed, {'one'});
    var saved = await store.load();
    expect(saved.single.videos.length, 1);
    expect(saved.single.description, '背景故事');
    expect(saved.single.videos.single.asset, isFalse);
    await task.download(package.clips);
    expect(task.completed, {'one', 'two'});
    expect(transfers, 2);
    saved = await DownloadedCharacterStore(directory, origin.origin).load();
    expect(saved.single.videos.length, 2);
    expect(saved.single.totalVideos, 2);
    expect(await File(saved.single.videos.first.source).readAsBytes(), bytes);
  });
  test('failed verification never adds a role; retry rechecks ownership',
      () async {
    owned = true;
    corrupt = true;
    final task = controller();
    addTearDown(task.dispose);
    await task.download([package.clips.first]);
    expect(task.completed, isEmpty);
    expect(await store.load(), isEmpty);
    owned = false;
    corrupt = false;
    await task.download([package.clips.first]);
    expect(transfers, 1);
    expect(await store.load(), isEmpty);
  });
  test('cancel before transfer leaves no library entry', () async {
    owned = true;
    final task = controller();
    addTearDown(task.dispose);
    task.addListener(() {
      if (task.busy) task.cancel();
    });
    await task.download(package.clips);
    expect(task.completed, isEmpty);
    expect(await store.load(), isEmpty);
    expect(transfers, 0);
  });
  test(
      'cancelling a package after its first clip preserves that completed clip',
      () async {
    owned = true;
    final task = controller();
    addTearDown(task.dispose);
    task.addListener(() {
      if (task.completed.contains('one')) task.cancel();
    });
    await task.download(package.clips);
    expect(task.completed, {'one'});
    expect((await store.load()).single.videos.single.id, 'one');
    expect(transfers, 1);
  });
  test('account changes between clips stop without mixing account libraries',
      () async {
    owned = true;
    var attempt = 0;
    final task = OwnedPackageDownloadController(
        package: package,
        baseUri: origin,
        identity: () async =>
            (accountId: ++attempt == 1 ? 'first' : 'second', token: token),
        storeForAccount: (_, __) async => store);
    addTearDown(task.dispose);
    await task.download(package.clips);
    expect(task.completed, {'one'});
    expect(transfers, 1);
    expect((await store.load()).single.videos.length, 1);
  });
  test(
      'verified bytes without library metadata remain retryable and are repaired',
      () async {
    owned = true;
    await VerifiedVideoDownload(origin, directory)
        .download(packageId: 'p', clipId: 'one', sessionToken: token);
    final task = controller();
    addTearDown(task.dispose);
    await task.prepare();
    expect(task.completed, isEmpty);
    await task.download([package.clips.first]);
    expect(task.completed, {'one'});
    expect((await store.load()).single.videos.length, 1);
    expect(transfers, 1);
  });
}
