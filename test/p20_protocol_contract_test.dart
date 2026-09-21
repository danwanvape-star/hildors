import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_command_session.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/protocol/p20_protocol.dart';

class ContractClient extends P20DeviceClient {
  ContractClient() : super(modernProtocol: true);
  List<int> reply = [];
  List<int>? sent;
  int? command;
  @override
  Future<P20Frame> requestFrame(P20Command cmd,
      [List<int> data = const []]) async {
    command = cmd.code;
    sent = data;
    return P20Frame(command: cmd.code, data: Uint8List.fromList(reply));
  }
}

void main() {
  late ContractClient client;
  late P20CommandSession session;
  setUp(() {
    client = ContractClient();
    session = P20CommandSession(client);
  });
  tearDown(() async {
    await session.dispose();
    await client.dispose();
  });
  test('E8 requires exactly three length-prefixed fields, empty audio is valid',
      () async {
    for (final bad in <List<int>>[
      [],
      [1, 65],
      [1, 65, 0],
      [1, 65, 1, 66, 2, 67],
      [1, 65, 1, 66, 0, 99]
    ]) {
      client.reply = bad;
      await expectLater(
          session.queryVersionSummary(), throwsA(isA<P20CommandException>()));
    }
    client.reply = [1, 65, 1, 66, 0];
    expect(await session.queryVersionSummary(), 'A\nB');
  });
  test(
      '37 preserves all six documented player states and rejects invalid list/status',
      () async {
    for (var state = 0; state <= 5; state++) {
      client.reply = [1, 0, state];
      final dynamic current = await session.queryCurrentVideo();
      expect(current.playerStatus, state);
      expect(current.playing, state == 1);
      expect(current.listId, 1);
    }
    for (final bad in [
      [2, 0, 1],
      [0, 0, 6],
      [0, 0, 1, 1]
    ]) {
      client.reply = bad;
      await expectLater(
          session.queryCurrentVideo(), throwsA(isA<P20CommandException>()));
    }
  });
  test('0F rejects malformed status and retains raw player status', () async {
    client.reply = [1, 4, 0, 0, 0, 1, 0, 1];
    expect((await session.queryDeviceStatus()).playerStatus, 4);
    for (final bad in <List<int>>[
      [1, 1, 101, 0, 0, 1, 0, 0],
      [1, 1, 50, 0, 0, 1, 0, 2],
      [1, 1, 50, 0, 0, 1, 0, 0, 0],
    ]) {
      client.reply = bad;
      await expectLater(
          session.queryDeviceStatus(), throwsA(isA<P20CommandException>()));
    }
  });
  test('09 rejects wrong mode echo even with success result', () async {
    client.reply = [3, 1];
    await expectLater(session.setPlayMode(P20PlayMode.singleLoop),
        throwsA(isA<P20CommandException>()));
  });
  test('33 supports explicit all-lists and rejects mismatched echo', () async {
    client.reply = [255, 1];
    await session.deleteAllVideos(listId: 255);
    expect(client.sent, [255]);
    client.reply = [1, 1];
    await expectLater(session.deleteAllVideos(listId: 0),
        throwsA(isA<P20CommandException>()));
  });
  test('control setters validate RESULT, echoed values and zero brightness',
      () async {
    final dynamic api = session;
    client.reply = [3, 2];
    await expectLater(
        api.setPlaying(true), throwsA(isA<P20CommandException>()));
    client.reply = [2, 1];
    await api.setPlaying(false);
    expect(client.sent, [2]);
    client.reply = [2, 1];
    await expectLater(api.changeTrack(3), throwsA(isA<P20CommandException>()));
    client.reply = [3, 1];
    await api.changeTrack(3);
    expect(client.sent, [3]);
    client.reply = [0, 1];
    expect(await api.setBrightness(0), 0);
    expect(client.sent, [0]);
    client.reply = [1, 44, 1];
    expect(await api.setAngle(300), 300);
    expect(client.sent, [1, 44]);
  });
  test('10 switches a valid list and validates the echoed list', () async {
    final dynamic api = session;
    client.reply = [1, 1];
    await api.switchPlaylist(1);
    expect(client.command, 16);
    expect(client.sent, [1]);
    client.reply = [0, 1];
    await expectLater(
        api.switchPlaylist(1), throwsA(isA<P20CommandException>()));
  });
}
