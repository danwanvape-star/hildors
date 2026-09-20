import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_v2_connection.dart';
import 'package:hildors_cockpit/src/device/p20_v2_protocol.dart';

List<int> reply(int command, List<int> data) {
  final bytes = P20V2Protocol.request(command, data);
  bytes[0] = 0x55;
  bytes[bytes.length - 1] = 0x5a;
  return bytes;
}

void main() {
  test('idle remote disconnect notifies owner once', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final accepted = Completer<Socket>();
    final subscription = server.listen(accepted.complete);
    final closed = Completer<void>();
    var notifications = 0;
    final client = P20V2Connection(
      await Socket.connect('127.0.0.1', server.port),
      onClosed: () {
        notifications++;
        if (!closed.isCompleted) closed.complete();
      },
    );
    final peer = await accepted.future;
    try {
      peer.destroy();
      await closed.future.timeout(const Duration(seconds: 1));
      await expectLater(client.request(4), throwsStateError);
      await client.close();
      expect(notifications, 1);
    } finally {
      await client.close();
      peer.destroy();
      await subscription.cancel();
      await server.close();
    }
  });
  test('close interrupts waiting upload and queued command', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final directory = await Directory.systemTemp.createTemp('p20-cancel-');
    final file = await File('${directory.path}/file').writeAsBytes([1]);
    final ready = Completer<void>();
    Socket? peer;
    final subscription = server.listen((socket) {
      peer = socket;
      socket.listen((bytes) {
        if (!ready.isCompleted) ready.complete();
      });
    });
    final client =
        P20V2Connection(await Socket.connect('127.0.0.1', server.port));
    try {
      final upload = client.upload(file, 0, 'sample.mp4'.codeUnits);
      final query = client.request(4);
      final assertions = Future.wait([
        expectLater(upload, throwsA(isA<SocketException>())),
        expectLater(query, throwsStateError),
      ]);
      await ready.future;
      await client.close();
      await assertions.timeout(const Duration(seconds: 1));
    } finally {
      await client.close();
      peer?.destroy();
      await subscription.cancel();
      await server.close();
      await directory.delete(recursive: true);
    }
  });
  test('timeout invalidates queued requests without sending them', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    Socket? peer;
    var received = 0;
    final subscription = server.listen((socket) {
      peer = socket;
      socket.listen((bytes) => received += bytes.length);
    });
    final client = P20V2Connection(
        await Socket.connect('127.0.0.1', server.port),
        timeout: const Duration(milliseconds: 100));
    try {
      final first = client.request(4);
      final second = client.request(8);
      await Future.wait([
        expectLater(first, throwsA(isA<TimeoutException>())),
        expectLater(second, throwsStateError),
      ]);
      expect(received, 8);
    } finally {
      await client.close();
      peer?.destroy();
      await subscription.cancel();
      await server.close();
    }
  });
  for (final status in [0x80, 0x81, 0x82, 0x85, 0x8a]) {
    test('device rejection $status sends no file data', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final directory = await Directory.systemTemp.createTemp('p20-rejection-');
      final file = await File('${directory.path}/file').writeAsBytes([1, 2, 3]);
      var bytesReceived = 0;
      Socket? peer;
      final subscription = server.listen((socket) {
        peer = socket;
        socket.listen((bytes) {
          bytesReceived += bytes.length;
          socket.add(reply(0x31, [status]));
        });
      });
      final client =
          P20V2Connection(await Socket.connect('127.0.0.1', server.port));
      try {
        await expectLater(
            client.upload(file, 0, 'sample.mp4'.codeUnits),
            throwsA(isA<P20DeviceUploadRejected>()
                .having((e) => e.status, 'status', status)));
        expect(
            bytesReceived, 23); // Header only: 8 framing + 5 fields + 10 name.
        await expectLater(client.request(4), throwsStateError);
      } finally {
        await client.close();
        peer?.destroy();
        await subscription.cancel();
        await server.close();
        await directory.delete(recursive: true);
      }
    });
  }
  for (final size in [1, 32768, 32769, 65536]) {
    test('uploads $size bytes then allows next command', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final directory = await Directory.systemTemp.createTemp('p20-test-');
      final file = File('${directory.path}/test.bin');
      final payload = List.generate(size, (i) => i % 251);
      await file.writeAsBytes(payload);
      final received = <int>[];
      final commands = <int>[];
      Socket? peer;
      final subscription = server.listen((socket) {
        peer = socket;
        final buffer = <int>[];
        var uploading = false;
        var sequence = 0;
        socket.listen((bytes) {
          buffer.addAll(bytes);
          while (buffer.isNotEmpty) {
            if (uploading) {
              final count = (size - received.length).clamp(0, buffer.length);
              received.addAll(buffer.sublist(0, count));
              buffer.removeRange(0, count);
              while (received.length >= (sequence + 1) * 32768) {
                sequence++;
                socket.add(reply(0x31, [1, 0, 0, 0, sequence]));
              }
              if (received.length == size) {
                socket.add(reply(0x31, [2]));
                uploading = false;
              } else {
                break;
              }
            } else {
              if (buffer.length < 8) break;
              final length = (buffer[1] << 24) |
                  (buffer[2] << 16) |
                  (buffer[3] << 8) |
                  buffer[4];
              if (buffer.length < length + 7) break;
              final command = buffer[5];
              commands.add(command);
              buffer.removeRange(0, length + 7);
              if (command == 0x31) {
                uploading = true;
                socket.add(reply(command, [0]));
              } else {
                socket.add(reply(command, [60]));
              }
            }
          }
        });
      });
      final client =
          P20V2Connection(await Socket.connect('127.0.0.1', server.port));
      try {
        final upload = client.upload(file, 0, 'sample.mp4'.codeUnits);
        final query = client.request(4);
        await upload;
        expect((await query).data, [60]);
        expect(received, payload);
        expect(commands, [0x31, 4]);
      } finally {
        await client.close();
        peer?.destroy();
        await subscription.cancel();
        await server.close();
        await directory.delete(recursive: true);
      }
    });
  }
}
