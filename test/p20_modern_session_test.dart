import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_command_session.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/protocol/p20_protocol.dart';

class TestClient extends P20DeviceClient {
  TestClient() : super(modernProtocol: true);
  final calls = <(P20Command, List<int>)>[];
  List<int> reply = [];
  @override
  Future<P20Frame> requestFrame(P20Command command,
      [List<int> data = const []]) async {
    calls.add((command, data));
    return P20Frame(command: command.code, data: Uint8List.fromList(reply));
  }
}

void main() {
  late TestClient client;
  late P20CommandSession session;
  setUp(() {
    client = TestClient();
    session = P20CommandSession(client);
  });
  tearDown(() async {
    await session.dispose();
    await client.dispose();
  });
  test('B list uses LIST_ID and GBK filenames for query and playback',
      () async {
    client.reply = [1, 1, 0, 0xd6, 0xd0, 0xce, 0xc4, ...'.mp4'.codeUnits];
    final entry = await session.queryVideo(0, listId: 1);
    expect(entry?.fileName, '中文.mp4');
    expect(client.calls.last.$2, [1, 0]);
    client.reply = [1];
    await session.playVideo(entry!.fileName, listId: 1);
    expect(
        client.calls.last.$2, [1, 0xd6, 0xd0, 0xce, 0xc4, ...'.mp4'.codeUnits]);
  });
  test('status query has no payload and current video includes list', () async {
    client.reply = [1, 4, 2];
    final current = await session.queryCurrentVideo();
    expect(client.calls.last.$2, isEmpty);
    expect(current.listId, 1);
    expect(current.index, 4);
    expect(current.playing, false);
  });
  test('wrong list reply is rejected rather than mixed into visible list',
      () async {
    client.reply = [0, 1, 0, ...'demo.mp4'.codeUnits];
    await expectLater(
        session.queryVideo(0, listId: 1), throwsA(isA<P20CommandException>()));
  });
  test('list-scoped delete and reorder use correct acknowledgement field',
      () async {
    client.reply = [1, 1];
    await session.reorderVideos(total: 2, from: 0, to: 1, listId: 1);
    expect(client.calls.last.$2, [1, 2, 0, 1]);
    await session.deleteAllVideos(listId: 1);
    expect(client.calls.last.$2, [1]);
  });
}
