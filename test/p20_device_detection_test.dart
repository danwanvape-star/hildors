import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/device/p20_device_profile.dart';
import 'package:hildors_cockpit/src/device/p20_single_connection.dart';

void main() {
  test('auto fallback probes single using a fresh socket', () async {
    final server = await ServerSocket.bind('127.0.0.1', 0);
    final client = P20DeviceClient(preference: P20DevicePreference.auto);
    var connections = 0;
    server.listen((s) {
      final number = ++connections;
      s.listen((bytes) {
        if (number == 1) {
          s.destroy();
          return;
        }
        expect(bytes, [0xaa, 0, 0, 0, 2, 4, 0, 2, 0xa5]);
        s.add([0x55, 0, 0, 0, 2, 4, 50, 2, 0x5a]);
      });
    });
    try {
      await client.connect(host: '127.0.0.1', port: server.port);
      expect(client.profile.kind, P20DeviceKind.single);
      expect(connections, 2);
    } finally {
      await client.dispose();
      await server.close();
    }
  });
  for (final reply in [
    [0x55, 0, 0, 0, 2, 4, 0, 2, 0x5a],
    [0x55, 0, 0, 0, 2, 4, 101, 2, 0x5a],
    [0x55, 0, 0, 0, 2, 4, 50, 0x20, 0x5a],
    <int>[],
  ]) {
    test('invalid single brightness reply $reply never connects', () async {
      final server = await ServerSocket.bind('127.0.0.1', 0);
      final client = P20DeviceClient(preference: P20DevicePreference.single);
      var count = 0;
      server.listen((s) {
        count++;
        s.listen((_) {
          s.add(reply);
        });
      });
      try {
        await expectLater(client.connect(host: '127.0.0.1', port: server.port),
            throwsA(anything));
        expect(client.isConnected, isFalse);
        expect(client.profile.kind, P20DeviceKind.unknown);
        expect(count, 1);
      } finally {
        await client.dispose();
        await server.close();
      }
    });
  }
  test('stale probe cannot publish connected after disconnect', () async {
    final server = await ServerSocket.bind('127.0.0.1', 0);
    final received = Completer<Socket>();
    server.listen((s) {
      s.listen((_) {
        if (!received.isCompleted) received.complete(s);
      });
    });
    final client = P20DeviceClient(preference: P20DevicePreference.single);
    final attempt =
        client.connect(host: '127.0.0.1', port: server.port).catchError((_) {});
    final peer = await received.future;
    final oldGeneration = client.generation;
    await client.disconnect();
    peer.add([0x55, 0, 0, 0, 2, 4, 50, 2, 0x5a]);
    await attempt;
    expect(client.generation, greaterThan(oldGeneration));
    expect(client.profile.kind, P20DeviceKind.unknown);
    expect(client.isConnected, isFalse);
    peer.destroy();
    await client.dispose();
    await server.close();
  });
  test('single timeout closes connection before a later request', () async {
    final server = await ServerSocket.bind('127.0.0.1', 0);
    var received = 0;
    server.listen((s) {
      s.listen((_) {
        received++;
      });
    });
    final socket = await Socket.connect('127.0.0.1', server.port);
    final transport = P20SingleConnection(socket, onClosed: () {});
    await expectLater(
        transport.request(4, [0], timeout: const Duration(milliseconds: 30)),
        throwsA(isA<TimeoutException>()));
    await expectLater(transport.request(4, [0]), throwsA(anything));
    expect(received, 1);
    await transport.close();
    await server.close();
  });
}
