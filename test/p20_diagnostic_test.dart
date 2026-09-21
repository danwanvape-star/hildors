import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_v2_connection.dart';
import 'package:hildors_cockpit/src/device/p20_v2_protocol.dart';

void main() {
  test(
      '21 received bytes distinguish previous status from current incomplete response',
      () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    Socket? peer;
    var requests = 0;
    final sub = server.listen((socket) {
      peer = socket;
      socket.listen((bytes) {
        if (requests++ == 0) {
          final status = P20V2Protocol.request(15, [1, 1, 50, 0, 0, 1, 0, 0]);
          status[0] = 0x55;
          status[status.length - 1] = 0x5a;
          socket.add(status);
        } else {
          socket.add([0x55, 0, 0, 0, 2]);
        }
      });
    });
    final client = P20V2Connection(
        await Socket.connect('127.0.0.1', server.port),
        timeout: const Duration(milliseconds: 200));
    try {
      await client.request(15);
      await expectLater(
          client.request(4),
          throwsA(isA<TimeoutException>()
              .having((e) => e.message, 'counters',
                  contains('rx=21 valid=1 rejected=0'))
              .having((e) => e.message, 'last reply', contains('last=0x0f'))
              .having((e) => e.message, 'current request bytes',
                  contains('deltaRx=5'))
              .having((e) => e.message, 'partial frame',
                  contains('pending=5 len=2'))));
    } finally {
      await client.close();
      peer?.destroy();
      await sub.cancel();
      await server.close();
    }
  });
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
