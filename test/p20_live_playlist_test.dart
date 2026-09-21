import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/device/p20_command_session.dart';
import 'package:hildors_cockpit/src/features/video/p20_live_playlist.dart';

class LiveClient extends P20DeviceClient {
  final states = StreamController<DeviceConnectionState>.broadcast();
  bool online = false;
  @override
  bool get isConnected => online;
  @override
  Stream<DeviceConnectionState> get connectionStates => states.stream;
  void setOnline(bool value) {
    online = value;
    states.add(value
        ? DeviceConnectionState.connected
        : DeviceConnectionState.disconnected);
  }

  @override
  Future<void> dispose() async {
    await states.close();
    await super.dispose();
  }
}

class LiveSession extends P20CommandSession {
  LiveSession(super.client);
  final files = {
    0: ['a.mp4', 'b.mp4'],
    1: ['bluetooth.mp4']
  };
  final calls = <String>[];
  Completer<List<P20VideoEntry>>? delayed;
  bool reject = false;
  P20PlayMode mode = P20PlayMode.sequenceLoop;
  @override
  Future<List<P20VideoEntry>> queryVideos({int listId = 0}) async {
    calls.add('read:$listId');
    if (delayed != null) return delayed!.future;
    return [
      for (var i = 0; i < files[listId]!.length; i++)
        P20VideoEntry(
            total: files[listId]!.length,
            index: i,
            fileName: files[listId]![i],
            listId: listId)
    ];
  }

  @override
  Future<P20PlayMode> queryPlayMode() async => mode;
  @override
  Future<void> setPlayMode(P20PlayMode value) async {
    calls.add('mode:${value.name}');
    if (reject) throw StateError('rejected');
    mode = value;
  }

  @override
  Future<void> reorderVideos(
      {required int total,
      required int from,
      required int to,
      int listId = 0}) async {
    calls.add('move:$listId:$total:$from:$to');
    if (reject) throw StateError('rejected');
    final file = files[listId]!.removeAt(from);
    files[listId]!.insert(to, file);
  }
}

void main() {
  late LiveClient client;
  late LiveSession session;
  late P20LivePlaylist model;
  setUp(() {
    client = LiveClient();
    session = LiveSession(client);
    model = P20LivePlaylist(client, session);
  });
  tearDown(() async {
    model.dispose();
    await session.dispose();
    await client.dispose();
  });
  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test(
      'only connected device contents appear; reconnect and B selection reload',
      () async {
    expect(model.videos, isEmpty);
    expect(session.calls, isEmpty);
    client.setOnline(true);
    await settle();
    expect(model.videos.map((e) => e.fileName), ['a.mp4', 'b.mp4']);
    await model.selectList(1);
    expect(model.videos.single.fileName, 'bluetooth.mp4');
    client.setOnline(false);
    await settle();
    expect(model.videos, isEmpty);
    expect(model.canEdit, false);
    session.files[1] = ['new-device.mp4'];
    client.setOnline(true);
    await settle();
    expect(model.videos.single.fileName, 'new-device.mp4');
  });
  test('late list response after disconnect cannot restore stale files',
      () async {
    session.delayed = Completer<List<P20VideoEntry>>();
    client.setOnline(true);
    await settle();
    client.setOnline(false);
    await settle();
    session.delayed!.complete(
        [const P20VideoEntry(total: 1, index: 0, fileName: 'stale.mp4')]);
    await settle();
    expect(model.videos, isEmpty);
    expect(model.loaded, false);
  });
  test(
      'reorder sends device command then reads confirmed order; rejection not optimistic',
      () async {
    client.setOnline(true);
    await settle();
    await model.move(0, 1);
    expect(session.calls, contains('move:0:2:0:1'));
    expect(model.videos.map((e) => e.fileName), ['b.mp4', 'a.mp4']);
    session.reject = true;
    await model.move(0, 1);
    expect(model.videos.map((e) => e.fileName), ['b.mp4', 'a.mp4']);
    expect(model.error, isNotNull);
  });
  test('mode uses device setting and rejection preserves confirmed mode',
      () async {
    client.setOnline(true);
    await settle();
    await model.setMode(P20PlayMode.randomLoop);
    expect(model.mode, P20PlayMode.randomLoop);
    session.reject = true;
    await model.setMode(P20PlayMode.singleOnce);
    expect(model.mode, P20PlayMode.randomLoop);
  });
}
