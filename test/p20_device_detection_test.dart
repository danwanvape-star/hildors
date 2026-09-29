import 'dart:async';
import 'dart:io';
import 'package:hildors_cockpit/src/protocol/p20_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/device/p20_device_profile.dart';
import 'package:hildors_cockpit/src/device/p20_single_connection.dart';

void main() {
  test('single playlist read logs raw query and invalid reply before parsing',
      () async {
    final server = await ServerSocket.bind('127.0.0.1', 0);
    final client = P20DeviceClient(preference: P20DevicePreference.single);
    server.listen((socket) {
      socket.listen((bytes) {
        if (bytes[5] == 4) {
          socket.add([0x55, 0, 0, 0, 2, 4, 60, 0x42, 0x5a]);
        } else {
          socket.add([0x55, 0, 0, 0, 3, 0x36, 0, 0, 0xff, 0x5a]);
          socket.close();
        }
      });
    });
    try {
      await client.connect(host: '127.0.0.1', port: server.port);
      await expectLater(client.requestFrame(P20Command.queryVideoList, [0]),
          throwsA(anything));
      expect(client.wireLog.text, contains('aa 00 00 00 02 36 00 02 a5'));
      expect(client.wireLog.text, contains('55 00 00 00 03 36 00 00 ff 5a'));
    } finally {
      await client.dispose();
      await server.close();
    }
  });
  test('single accepts captured additive brightness response and next query',
      () async {
    final server = await ServerSocket.bind('127.0.0.1', 0);
    final client = P20DeviceClient(preference: P20DevicePreference.single);
    server.listen((socket) {
      socket.listen((bytes) {
        expect(bytes, [0xaa, 0, 0, 0, 2, 4, 0, 2, 0xa5]);
        socket.add([0x55, 0, 0, 0, 2, 4, 0x3c, 0x42, 0x5a]);
      });
    });
    try {
      await client.connect(host: '127.0.0.1', port: server.port);
      expect(client.profile.kind, P20DeviceKind.single);
      final reply = await client.requestFrame(P20Command.queryBrightness, [0]);
      expect(reply.data, [60]);
    } finally {
      await client.dispose();
      await server.close();
    }
  });
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
      expect(client.wireLog.text, contains('stage=tcp_connected'));
      expect(client.wireLog.text, contains('aa 00 00 00 02 04 00 02 a5'));
      expect(client.wireLog.text, contains('55 00 00 00 02 04 32 02 5a'));
      expect(client.wireLog.text, contains('stage=verified'));
    } finally {
      await client.dispose();
      await server.close();
    }
  });
  test('socket refusal is distinguished from protocol failure', () async {
    final server = await ServerSocket.bind('127.0.0.1', 0);
    final port = server.port;
    await server.close();
    final client = P20DeviceClient(preference: P20DevicePreference.single);
    try {
      await expectLater(
          client.connect(host: '127.0.0.1', port: port), throwsA(anything));
      expect(client.wireLog.text, contains('stage=tcp_failed'));
      expect(client.wireLog.text, isNot(contains('stage=tcp_connected')));
    } finally {
      await client.dispose();
    }
  });
  test('connection tracing stops before later commands', () async {
    final server = await ServerSocket.bind('127.0.0.1', 0);
    final client = P20DeviceClient(preference: P20DevicePreference.single);
    server.listen((socket) {
      socket.listen((_) => socket.add([0x55, 0, 0, 0, 2, 4, 50, 2, 0x5a]));
    });
    try {
      await client.connect(host: '127.0.0.1', port: server.port);
      final log = client.wireLog.text;
      await client.requestFrame(P20Command.queryBrightness);
      expect(client.wireLog.text, log);
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
        expect(client.wireLog.text, contains('stage=probe_failed'));
        if (reply.isNotEmpty) {
          expect(client.wireLog.text, contains('RX bytes= 9'));
        }
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
