import 'package:hildors_cockpit/src/device/p20_wire_log.dart';
import 'package:hildors_cockpit/src/device/p20_v2_connection.dart';
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
  late P20WireLog wireLog;
  Future<File> sample(int count) =>
      File('${dir.path}/sample.bin').writeAsBytes(List.filled(count, 0x19));
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('p20-single-test');
    server = await ServerSocket.bind('127.0.0.1', 0);
    final incoming = server.first;
    final socket = await Socket.connect('127.0.0.1', server.port);
    peer = Peer(await incoming);
    wireLog = P20WireLog();
    transport = P20SingleConnection(socket, onClosed: () {}, wireLog: wireLog);
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
    final upload = transport.upload(await sample(65543), 'x.mp4'.codeUnits,
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
      0,
      7,
      120,
      46,
      109,
      112,
      52,
      0xfa,
      0xa5
    ]);
    peer.reply([0]);
    expect((await peer.take(32768)).every((b) => b == 0x19), isTrue);
    await expectLater(transport.request(4, [0]), throwsA(isA<StateError>()));
    peer.reply([1, 0, 0, 0, 2]);
    expect((await peer.take(32768)).length, 32768);
    peer.reply([1, 0, 0, 0, 2]);
    expect(await peer.take(7), List.filled(7, 0x19));
    peer.reply([2, 0xff, 0xff, 0xff, 0xff]);
    await upload;
    expect(progress.last, 65543);
  });
  for (final size in [0]) {
    test('rejects unverified file length $size', () async {
      await expectLater(transport.upload(await sample(size), 'x.mp4'.codeUnits),
          throwsArgumentError);
    });
  }
  for (final name in ['x.bin', '中.bin', '${'x' * 29}.bin', '../x.bin']) {
    test('rejects unsafe or invalid name $name', () async {
      await expectLater(transport.upload(await sample(32768), name.codeUnits),
          throwsArgumentError);
    });
  }
  for (final status in [2, 0x80, 0x81, 0x82, 0x83, 0x84, 0x85]) {
    test('header rejection $status cannot succeed', () async {
      final upload = transport.upload(await sample(32768), 'x.mp4'.codeUnits);
      final check = expectLater(upload, throwsA(anything));
      await peer.take(17);
      peer.reply([status]);
      await check;
      await expectLater(transport.request(4, [0]), throwsA(anything));
    });
  }
  for (final data in [
    [1],
    [1, 0, 0, 0],
    [3, 0, 0, 0, 2],
    [2]
  ]) {
    test('malformed ACK or premature completion $data closes', () async {
      final upload = transport.upload(await sample(98304), 'x.mp4'.codeUnits);
      final check = expectLater(upload, throwsA(isA<FormatException>()));
      await peer.take(17);
      peer.reply([0]);
      await peer.take(32768);
      peer.reply(data);
      await check;
    });
  }
  test('vendor 01NZ single upload request matches raw fixture', () async {
    final file = await sample(0);
    final handle = await file.open(mode: FileMode.write);
    await handle.truncate(0x01324f9c);
    await handle.close();
    final upload = transport.upload(file, '01NZ.mp4'.codeUnits);
    final check = expectLater(upload, throwsA(anything));
    final expected = 'aa0000000d3101324f9c30314e5a2e6d7034a4a5';
    expect(
        (await peer.take(20))
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join(),
        expected);
    peer.reply([0x82]);
    await check;
  });
  for (final split in [false, true]) {
    test('raw 0x87 reply is preserved before decoding, split=$split', () async {
      final upload = transport.upload(await sample(32768), 'x.mp4'.codeUnits);
      final check = expectLater(
          upload,
          throwsA(isA<P20DeviceUploadRejected>()
              .having((e) => e.status, 'wire status', 0x87)));
      await peer.take(17);
      const raw = [0x55, 0, 0, 0, 2, 0x31, 0x87, 0xba, 0x5a];
      if (split) {
        peer.socket.add(raw.sublist(0, 6));
        await peer.socket.flush();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        peer.socket.add(raw.sublist(6));
      } else {
        peer.socket.add(raw);
      }
      await check;
      final received = wireLog.text
          .split('\n')
          .where((line) => line.contains(' RX bytes= '))
          .map((line) =>
              line.split(' RX bytes= ').last.split(' ').skip(1).join(' '))
          .join(' ');
      expect(received, '55 00 00 00 02 31 87 ba 5a');
      expect(wireLog.text, isNot(contains('[media omitted]')));
      expect(await peer.input.moveNext(), isFalse);
    });
  }
  test('silent peer causes timeout, never synthesized 0x87', () async {
    final upload = transport.upload(await sample(32768), 'x.mp4'.codeUnits,
        timeout: const Duration(milliseconds: 80));
    final check = expectLater(upload, throwsA(isA<TimeoutException>()));
    await peer.take(17);
    await check;
    expect(wireLog.text, isNot(contains(' RX bytes= ')));
    expect(wireLog.text, isNot(contains('[media omitted]')));
  });
  test('cancel closes active upload', () async {
    final upload = transport.upload(await sample(32768), 'x.mp4'.codeUnits);
    final check = expectLater(upload, throwsA(anything));
    await peer.take(17);
    await transport.close();
    await check;
  });
  test('coalesced final progress and completion are both consumed', () async {
    final upload = transport.upload(await sample(32768), 'x.mp4'.codeUnits,
        timeout: const Duration(milliseconds: 100));
    await peer.take(17);
    peer.reply([0]);
    await peer.take(32768);
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
    final upload = transport.upload(await sample(65543), 'x.mp4'.codeUnits,
        timeout: const Duration(milliseconds: 100));
    final check = expectLater(upload, throwsA(isA<FormatException>()));
    await peer.take(17);
    peer.reply([0]);
    await peer.take(32768);
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
    final upload = transport.upload(await sample(32768), 'x.mp4'.codeUnits,
        timeout: const Duration(milliseconds: 50));
    final check = expectLater(upload, throwsA(isA<TimeoutException>()));
    await peer.take(17);
    peer.reply([0]);
    await peer.take(32768);
    peer.reply([1, 0, 0, 0, 1]);
    await check;
  });
  test('public client blocks disconnected single upload', () async {
    final client = P20DeviceClient(preference: P20DevicePreference.single);
    try {
      await expectLater(
          client.uploadFile(await sample(32768), 0, 'x.mp4'.codeUnits),
          throwsA(anything));
    } finally {
      await client.dispose();
    }
  });
}
