import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/video/device_playlist_draft.dart';
import 'package:hildors_cockpit/src/features/video/playlist_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('本地视频加入后可重新读取，去重且两套列表独立', () async {
    final directory =
        await Directory.systemTemp.createTemp('hildors_playlist_test_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => directory.path);
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await directory.delete(recursive: true);
    });
    await PlaylistStore.add(DevicePlaylistKind.startup, 'local.mp4');
    await PlaylistStore.add(DevicePlaylistKind.startup, 'local.mp4');
    final startup = await PlaylistStore.load(const DevicePlaylistDraft(
      kind: DevicePlaylistKind.startup,
      enabled: true,
      loopMode: PlaylistLoopMode.listLoop,
      videoNames: [],
    ));
    expect(startup.videoNames.where((name) => name == 'local.mp4').length, 1);
    final bluetooth = await PlaylistStore.load(const DevicePlaylistDraft(
      kind: DevicePlaylistKind.bluetooth,
      enabled: true,
      loopMode: PlaylistLoopMode.listLoop,
      videoNames: [],
    ));
    expect(bluetooth.videoNames, isEmpty);
  });
}
