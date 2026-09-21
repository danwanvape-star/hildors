import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_v2_connection.dart';
import 'package:hildors_cockpit/src/device/p20_v2_protocol.dart';

void main() {
  for (final corrupt in [false, true]) {
    test('timeout distinguishes silent socket from corrupt response: $corrupt',
        () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      Socket? peer;
      final sub = server.listen((s) {
        peer = s;
        s.listen((bytes) {
          if (corrupt) {
            final response = P20V2Protocol.request(4, [50]);
            response[0] = 0x55;
            response[response.length - 1] = 0x5a;
            response[response.length - 2] ^= 1;
            s.add(response);
          }
        });
      });
      final client = P20V2Connection(
          await Socket.connect('127.0.0.1', server.port),
          timeout: const Duration(milliseconds: 200));
      try {
        await expectLater(
            client.request(4),
            throwsA(isA<TimeoutException>().having(
                (e) => e.message,
                'diagnostic',
                contains(corrupt
                    ? 'rx=9 valid=0 rejected=1'
                    : 'rx=0 valid=0 rejected=0'))));
      } finally {
        await client.close();
        peer?.destroy();
        await sub.cancel();
        await server.close();
      }
    });
  }
}
