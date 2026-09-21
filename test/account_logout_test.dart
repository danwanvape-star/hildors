import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/cloud_business_intake.dart';

void main() {
  test('rotated refresh credentials survive a failed revocation for retry',
      () async {
    final dir = await Directory.systemTemp.createTemp('logout_refresh');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/session.json');
    await file.writeAsString(jsonEncode({
      'token': 'a' * 43,
      'refreshToken': 'b' * 43,
      'origin': 'https://example.test',
      'emailVerified': true
    }));
    var calls = 0;
    final service = CloudBusinessIntake(
        baseUrl: 'https://example.test',
        sessionFile: file,
        emailRequest: (method, path, {document, token}) async {
          calls++;
          if (calls == 1) return const CloudBusinessResponse(401, {});
          if (calls == 2) {
            return CloudBusinessResponse(200, {
              'token': 'c' * 43,
              'refreshToken': 'd' * 43,
              'expiresIn': 3600
            });
          }
          return const CloudBusinessResponse(503, {});
        });
    await expectLater(
        service.signOutAllDevices(), throwsA(isA<CloudApiException>()));
    final saved = jsonDecode(await file.readAsString());
    expect(saved['refreshToken'], 'd' * 43);
    expect(saved['emailVerified'], true);
  });
  for (final status in [200, 401, 503]) {
    test(
        'logout status $status clears credentials only after confirmed revocation',
        () async {
      final dir = await Directory.systemTemp.createTemp('logout_test');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/session.json');
      await file.writeAsString(jsonEncode({
        'token': 'a' * 43,
        'origin': 'https://example.test',
        'accountId': 'one',
        'email': 'test@example.com',
        'emailVerified': true,
      }));
      final before = await file.readAsString();
      final media = File('${dir.path}/offline.mp4');
      await media.writeAsString('test-media');
      final service = CloudBusinessIntake(
          baseUrl: 'https://example.test',
          sessionFile: file,
          emailRequest: (method, path, {document, token}) async {
            expect(method, 'DELETE');
            expect(path, '/v1/me/session');
            expect(await file.exists(), isTrue);
            return CloudBusinessResponse(status, {'signedOut': status == 200});
          });
      if (status == 200) {
        await service.signOutAllDevices();
        expect(await file.exists(), isFalse);
        expect((await service.accountSummary()).signedIn, isFalse);
      } else {
        await expectLater(
            service.signOutAllDevices(), throwsA(isA<CloudApiException>()));
        expect(await file.readAsString(), before);
      }
      expect(await media.readAsString(), 'test-media');
    });
  }
}
