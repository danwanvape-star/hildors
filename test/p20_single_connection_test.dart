import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_single_connection.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/device/p20_device_profile.dart';

class Peer {
  Peer(this.socket) : input = StreamIterator(socket);
  final Socket socket;
  final StreamIterator<List<int>> input;
  final buffer = <int>[];
  Future<List<int>> take(int count) async {
    while (buffer.length < count) {
      if (!await input.moveNext()) throw StateError('closed');
      buffer.addAll(input.current);
    }
    final result = buffer.sublist(0, count);
    buffer.removeRange(0, count);
    return result;
  }

  void reply(List<int> data) =>
      socket.add([0x55, 0, 0, 0, data.length + 1, 0x31, ...data, 2, 0x5a]);
}

void main() {
  late ServerSocket server;
  late Peer peer;
  late P20SingleConnection transport;
  late Directory dir;
  Future<File> sample(int count) =>
      File('${dir.path}/sample.bin').writeAsBytes(List.filled(count, 0x19));
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('p20-single-test');
    server = await ServerSocket.bind('127.0.0.1', 0);
    final incoming = server.first;
    final socket = await Socket.connect('127.0.0.1', server.port);
    peer = Peer(await incoming);
    transport = P20SingleConnection(socket, onClosed: () {});
  });
  tearDown(() async {
    await transport.close();
    peer.socket.destroy();
    await peer.input.cancel();
    await server.close();
    await dir.delete(recursive: true);
  });
  test('single upload exact header and stop-and-wait chunks', () async {
    final progress = <int>[];
    final upload = transport.upload(await sample(71400), 'x.bin'.codeUnits,
        onProgress: (n, _) => progress.add(n));
    expect(await peer.take(17), [
      0xaa,
      0,
      0,
      0,
      10,
      0x31,
      0,
      1,
      0x16,
      0xe8,
      120,
      46,
      98,
      105,
      110,
      2,
      0xa5
    ]);
    peer.reply([0]);
    expect((await peer.take(35700)).every((b) => b == 0x19), isTrue);
    await expectLater(transport.request(4, [0]), throwsA(isA<StateError>()));
    peer.reply([1, 0, 0, 0, 1]);
    expect((await peer.take(35700)).length, 35700);
    peer.reply([2]);
    await upload;
    expect(progress.last, 71400);
  });
  for (final size in [0, 35701]) {
    test('rejects unverified file length $size', () async {
      await expectLater(transport.upload(await sample(size), 'x.bin'.codeUnits),
          throwsArgumentError);
    });
  }
  for (final name in ['x.mp4', '中.bin', '${'x' * 29}.bin', '../x.bin']) {
    test('rejects unsafe or invalid name $name', () async {
      await expectLater(transport.upload(await sample(35700), name.codeUnits),
          throwsArgumentError);
    });
  }
  for (final status in [2, 0x80, 0x81, 0x82, 0x83, 0x84, 0x85]) {
    test('header rejection $status cannot succeed', () async {
      final upload = transport.upload(await sample(35700), 'x.bin'.codeUnits);
      final check = expectLater(upload, throwsA(anything));
      await peer.take(17);
      peer.reply([status]);
      await check;
      await expectLater(transport.request(4, [0]), throwsA(anything));
    });
  }
  for (final sequence in [1, 0, 3]) {
    test('ambiguous second sequence $sequence stops upload', () async {
      final upload = transport.upload(await sample(107100), 'x.bin'.codeUnits);
      final check = expectLater(upload, throwsA(isA<FormatException>()));
      await peer.take(17);
      peer.reply([0]);
      await peer.take(35700);
      peer.reply([1, 0, 0, 0, 1]);
      await peer.take(35700);
      peer.reply([1, 0, 0, 0, sequence]);
      await check;
    });
  }
  test('cancel closes active upload', () async {
    final upload = transport.upload(await sample(35700), 'x.bin'.codeUnits);
    final check = expectLater(upload, throwsA(anything));
    await peer.take(17);
    await transport.close();
    await check;
  });
  test('coalesced final progress and completion are both consumed', () async {
    final upload = transport.upload(await sample(35700), 'x.bin'.codeUnits,
        timeout: const Duration(milliseconds: 100));
    await peer.take(17);
    peer.reply([0]);
    await peer.take(35700);
    peer.socket.add([
      0x55,
      0,
      0,
      0,
      6,
      0x31,
      1,
      0,
      0,
      0,
      1,
      2,
      0x5a,
      0x55,
      0,
      0,
      0,
      2,
      0x31,
      2,
      2,
      0x5a
    ]);
    await upload;
  });
  test('coalesced early duplicate ACK cannot advance another packet', () async {
    final upload = transport.upload(await sample(71400), 'x.bin'.codeUnits,
        timeout: const Duration(milliseconds: 100));
    final check = expectLater(upload, throwsA(isA<FormatException>()));
    await peer.take(17);
    peer.reply([0]);
    await peer.take(35700);
    peer.socket.add([
      0x55,
      0,
      0,
      0,
      6,
      0x31,
      1,
      0,
      0,
      0,
      1,
      2,
      0x5a,
      0x55,
      0,
      0,
      0,
      6,
      0x31,
      1,
      0,
      0,
      0,
      1,
      2,
      0x5a
    ]);
    await check;
  });
  test('missing completion times out and closes', () async {
    final upload = transport.upload(await sample(35700), 'x.bin'.codeUnits,
        timeout: const Duration(milliseconds: 50));
    final check = expectLater(upload, throwsA(isA<TimeoutException>()));
    await peer.take(17);
    peer.reply([0]);
    await peer.take(35700);
    peer.reply([1, 0, 0, 0, 1]);
    await check;
  });
  test('public client blocks unvalidated single upload', () async {
    final client = P20DeviceClient(preference: P20DevicePreference.single);
    try {
      await expectLater(
          client.uploadFile(await sample(35700), 0, 'x.bin'.codeUnits),
          throwsA(anything));
    } finally {
      await client.dispose();
    }
  });
}
