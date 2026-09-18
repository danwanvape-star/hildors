import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/media/preview_video_cache.dart';

void main() {
  late HttpServer server;
  late Directory directory;
  late PreviewVideoCache cache;
  late Uri uri;
  var revoked = false;
  var downloads = 0;
  setUp(() async {
    revoked = false;
    downloads = 0;
    directory = await Directory.systemTemp.createTemp('preview-test-');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final origin = Uri.parse('http://127.0.0.1:${server.port}');
    uri = origin
        .resolve('/v1/media/00000000-0000-0000-0000-000000000001/preview?v=1');
    cache = PreviewVideoCache(
        origin: origin,
        directory: () async => directory,
        maxBytes: 8,
        maxEntryBytes: 8);
    server.listen((request) async {
      if (revoked) {
        request.response.statusCode = 404;
      } else if (request.headers.value(HttpHeaders.ifNoneMatchHeader) ==
          '"one"') {
        request.response.statusCode = 304;
      } else {
        downloads++;
        request.response.headers.set(HttpHeaders.etagHeader, '"one"');
        request.response.add([1, 2, 3, 4]);
      }
      await request.response.close();
    });
  });
  tearDown(() async {
    await server.close(force: true);
    await directory.delete(recursive: true);
  });
  test('cache miss does not fetch or delay first streaming playback', () async {
    expect(await cache.validatedFile(uri), isNull);
    expect(downloads, 0);
  });
  test('cached preview is usable only while server confirms current ETag',
      () async {
    await cache.warm(uri);
    expect(await (await cache.validatedFile(uri))!.readAsBytes(), [1, 2, 3, 4]);
    revoked = true;
    expect(await cache.validatedFile(uri), isNull);
    expect(await directory.list().toList(), isEmpty);
  });
  test('untrusted hosts and original download routes are never cached',
      () async {
    await cache.warm(uri.replace(host: 'localhost'));
    await cache
        .warm(uri.replace(path: uri.path.replaceAll('/preview', '/download')));
    expect(downloads, 0);
    expect(await directory.list().toList(), isEmpty);
  });
  test('concurrent warm calls share one bounded transfer', () async {
    await Future.wait([cache.warm(uri), cache.warm(uri)]);
    expect(downloads, 1);
  });
  test('LRU eviction keeps total bytes within budget', () async {
    final second = uri.replace(path: uri.path.replaceAll('0001/', '0002/'));
    final third = uri.replace(path: uri.path.replaceAll('0001/', '0003/'));
    await cache.warm(uri);
    await cache.warm(second);
    expect(await cache.validatedFile(uri), isNotNull);
    await cache.warm(third);
    expect(await cache.validatedFile(second), isNull);
    expect(await cache.validatedFile(uri), isNotNull);
    expect(await cache.validatedFile(third), isNotNull);
  });
  test('expired entries are deleted instead of reused', () async {
    final expired = PreviewVideoCache(
        origin: uri, directory: () async => directory, maxAge: Duration.zero);
    await expired.warm(uri);
    expect(await expired.validatedFile(uri), isNull);
    expect(await directory.list().toList(), isEmpty);
  });
  test('oversized previews never leave partial files', () async {
    final small = PreviewVideoCache(
        origin: uri, directory: () async => directory, maxEntryBytes: 2);
    await small.warm(uri);
    expect(await small.validatedFile(uri), isNull);
    expect(await directory.list().toList(), isEmpty);
  });
  test('failed cache download can be retried after recovery', () async {
    revoked = true;
    await cache.warm(uri);
    revoked = false;
    await cache.warm(uri);
    expect(await cache.validatedFile(uri), isNotNull);
  });
  test('cancelled warm cannot publish a playable cached file', () async {
    await cache.warm(uri, cancel: Future<void>.value());
    expect(await cache.validatedFile(uri), isNull);
    expect(await directory.list().toList(), isEmpty);
  });
  test('externally truncated cached file is not replayed', () async {
    await cache.warm(uri);
    final file = await cache.validatedFile(uri);
    await file!.writeAsBytes([1]);
    expect(await cache.validatedFile(uri), isNull);
  });
  test('disk write failure stays optional and leaves no cached entry',
      () async {
    final broken = PreviewVideoCache(
        origin: uri,
        directory: () async => Directory('${directory.path}/missing/child'));
    await broken.warm(uri);
    expect(await broken.validatedFile(uri), isNull);
    expect(await directory.list().toList(), isEmpty);
  });
}
