import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/cloud_order_submission.dart';

void main() {
  test('invalid order name stays editable before any cloud request', () async {
    final draft = CloudOrderSubmission(
        request: (method, path, {document, bytes, contentType}) async =>
            {'id': 'one'});
    await expectLater(
        draft.submit({'characterName': 'A' * 121}, []), throwsFormatException);
    expect(draft.started, isFalse);
  });
  test('material retry preserves order identity and uploads actual bytes',
      () async {
    final calls = <Map<String, dynamic>>[];
    var fail = true;
    final draft = CloudOrderSubmission(
        request: (method, path, {document, bytes, contentType}) async {
      calls.add({'path': path, 'document': document, 'bytes': bytes});
      if (path.contains('/materials')) {
        if (fail) {
          fail = false;
          throw Exception('offline');
        }
        return {'id': 'order-one', 'version': 2};
      }
      return {'id': 'order-one', 'version': 1};
    });
    final material =
        CloudOrderMaterial(name: 'a.png', bytes: Uint8List.fromList([1, 2, 3]));
    await expectLater(
        draft.submit({'characterName': 'A'}, [material]), throwsException);
    await draft.submit({'characterName': 'A'}, [material]);
    expect(
        calls.where((c) => c['path'] == '/v1/me/customization-orders').length,
        1);
    expect(calls[0]['document']['clientRequestId'],
        matches(RegExp(r'^[a-f0-9-]{36}$')));
    expect(calls[1]['path'], calls[2]['path']);
    expect(calls[2]['bytes'], [1, 2, 3]);
  });
  test('rejects oversized material before creating cloud order', () async {
    var requests = 0;
    final draft = CloudOrderSubmission(
        request: (method, path, {document, bytes, contentType}) async {
      requests++;
      return {'id': 'unexpected'};
    });
    await expectLater(
        draft.submit({'characterName': 'A'}, [
          CloudOrderMaterial(
              name: 'a.jpg', bytes: Uint8List(8 * 1024 * 1024 + 1))
        ]),
        throwsFormatException);
    expect(requests, 0);
  });
}
