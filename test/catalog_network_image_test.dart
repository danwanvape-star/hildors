import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/catalog_network_image.dart';

class _RealHttp extends HttpOverrides {
  HttpClient client() => super.createHttpClient(null);
}

void main() {
  testWidgets(
      'failed image retries same URL and displays the successful response',
      (tester) async {
    final client = _RealHttp().client();
    debugNetworkImageHttpClientProvider = () => client;
    final server = await tester
        .runAsync(() => HttpServer.bind(InternetAddress.loopbackIPv4, 0));
    final paths = <String>[];
    final release = Completer<void>();
    server!.listen((request) async {
      paths.add(request.uri.toString());
      if (paths.length == 1) {
        await release.future;
        request.response.statusCode = 503;
      } else {
        request.response.headers.contentType = ContentType('image', 'png');
        request.response.add(base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg=='));
      }
      await request.response.close();
    });
    addTearDown(() async {
      debugNetworkImageHttpClientProvider = null;
      client.close(force: true);
      await server.close(force: true);
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 90,
                height: 90,
                child: CatalogNetworkImage(
                    url: 'http://127.0.0.1:${server.port}/cover/thumbnail')))));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byTooltip('图片加载失败，点击重试'), findsNothing);
    release.complete();
    Future<void> waitFor(bool Function() done) async {
      for (var i = 0; i < 100 && !done(); i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
      expect(done(), isTrue);
    }

    await waitFor(() => find.byTooltip('图片加载失败，点击重试').evaluate().isNotEmpty);
    expect(paths, ['/cover/thumbnail']);
    await tester.tap(find.byTooltip('图片加载失败，点击重试'));
    await tester.pump();
    await waitFor(() => tester
        .widgetList<RawImage>(find.byType(RawImage))
        .any((image) => image.image != null));
    expect(paths, ['/cover/thumbnail', '/cover/thumbnail']);
    expect(find.byTooltip('图片加载失败，点击重试'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    client.close(force: true);
    debugNetworkImageHttpClientProvider = null;
  });
}
