import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/cloud_business_intake.dart';
import 'package:hildors_cockpit/src/features/customization/custom_delivery_download.dart';
import 'package:hildors_cockpit/src/features/community/downloaded_character_store.dart';
import 'package:hildors_cockpit/src/features/community/verified_video_download.dart';

class _Service extends CloudBusinessIntake {
  _Service(this.base);
  final Uri base;
  int reads = 0;
  bool refunded = false;
  @override
  Uri get baseUri => base;
  @override
  Future<({String accountId, String token})> downloadIdentity() async =>
      (accountId: 'owner', token: 'a' * 43);
  @override
  Future<Map<String, dynamic>> orderRequest(String method, String path,
      {Map<String, dynamic>? document,
      Uint8List? bytes,
      String? contentType}) async {
    reads++;
    return {
      'id': 'order-1',
      'characterName': 'Private robot',
      'status': refunded && reads > 1 ? 'withdrawn' : 'delivered',
      'payment': {'status': refunded && reads > 1 ? 'refunded' : 'purchased'},
      'deliverable': {'id': 'clip-1', 'durationSeconds': 10}
    };
  }
}

void main() {
  for (final refund in [false, true]) {
    test(
        'private final delivery enters library only after permission recheck: refund=$refund',
        () async {
      final dir = await Directory.systemTemp.createTemp('custom-offline-');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async {
        await server.close(force: true);
        await dir.delete(recursive: true);
      });
      final bytes = Uint8List.fromList(List.generate(64, (i) => i));
      final base = Uri.parse('http://127.0.0.1:${server.port}');
      server.listen((req) async {
        expect(req.headers.value('authorization'), 'Bearer ${'a' * 43}');
        if (req.uri.path.endsWith('/manifest')) {
          req.response.headers.contentType = ContentType.json;
          req.response.write(jsonEncode({
            'packageId': 'custom-order-order-1',
            'clipId': 'clip-1',
            'bytes': bytes.length,
            'sha256': sha256.convert(bytes).toString(),
            'contentType': 'video/mp4',
            'authorizationRequired': true,
            'downloadPath': '/v1/me/customization-orders/order-1/download'
          }));
        } else {
          expect(req.uri.path, '/v1/me/customization-orders/order-1/download');
          req.response.add(bytes);
        }
        await req.response.close();
      });
      final store = DownloadedCharacterStore(dir, base.origin);
      final service = _Service(base)..refunded = refund;
      final operation = downloadCustomDelivery(
          service: service,
          orderId: 'order-1',
          cancellation: DownloadCancellation(),
          guard: () {},
          storeForAccount: (origin, account) async {
            expect(account, 'owner');
            return store;
          });
      if (refund) {
        await expectLater(operation, throwsA(isA<CloudApiException>()));
        expect(await store.load(), isEmpty);
      } else {
        await operation;
        final library = await store.load();
        expect(library.single.id, 'custom-order-order-1');
        expect(library.single.videos.single.id, 'clip-1');
      }
    });
  }
}
