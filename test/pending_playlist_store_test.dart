import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/video/device_playlist_draft.dart';
import 'package:hildors_cockpit/src/features/video/pending_playlist_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('pending_playlist_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => directory.path);
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await directory.delete(recursive: true);
  });
  const clip = (title: '角色 · 舞蹈', source: 'assets/demo.mp4', asset: true);
  test('从我的角色添加只合并所选视频，重复添加去重且保留原内容', () async {
    await PendingPlaylistStore.save(
        DevicePlaylistKind.bluetooth, {'existing': clip});
    await Future.wait([
      PendingPlaylistStore.merge(
          DevicePlaylistKind.bluetooth, {'role/idle': clip}),
      PendingPlaylistStore.merge(
          DevicePlaylistKind.bluetooth, {'role/dance': clip}),
      PendingPlaylistStore.merge(
          DevicePlaylistKind.bluetooth, {'role/dance': clip}),
    ]);
    expect((await PendingPlaylistStore.load(DevicePlaylistKind.bluetooth)).keys,
        unorderedEquals(['existing', 'role/idle', 'role/dance']));
    expect(
        await PendingPlaylistStore.load(DevicePlaylistKind.startup), isEmpty);
  });
  test('恢复包内单视频引用，两个列表独立，不复制媒体', () async {
    await PendingPlaylistStore.save(
        DevicePlaylistKind.startup, {'role/dance': clip});
    expect(await PendingPlaylistStore.load(DevicePlaylistKind.startup),
        {'role/dance': clip});
    expect(
        await PendingPlaylistStore.load(DevicePlaylistKind.bluetooth), isEmpty);
    expect(
        directory
            .listSync()
            .whereType<File>()
            .map((file) => file.path.split(Platform.pathSeparator).last),
        ['pending_playlist_startup.json']);
  });
  test('连续写入按序执行，保存调用时拍快照', () async {
    final entries = <String, PendingVideo>{'role/dance': clip};
    final first =
        PendingPlaylistStore.save(DevicePlaylistKind.startup, entries);
    entries.clear();
    await first;
    expect(await PendingPlaylistStore.load(DevicePlaylistKind.startup),
        isNotEmpty);
    await Future.wait([
      PendingPlaylistStore.save(
          DevicePlaylistKind.startup, {'role/dance': clip}),
      PendingPlaylistStore.save(DevicePlaylistKind.startup, {}),
    ]);
    expect(
        await PendingPlaylistStore.load(DevicePlaylistKind.startup), isEmpty);
  });
  test('源文件缺失仍保留引用供重新选择，不标记为设备文件', () async {
    const missing = (title: '手机视频', source: '/missing/phone.mp4', asset: false);
    await PendingPlaylistStore.save(
        DevicePlaylistKind.bluetooth, {'phone': missing});
    expect(
        (await PendingPlaylistStore.load(
            DevicePlaylistKind.bluetooth))['phone'],
        missing);
  });
  test('损坏记录报错而非静默清空', () async {
    await File('${directory.path}/pending_playlist_startup.json')
        .writeAsString('{bad');
    await expectLater(PendingPlaylistStore.load(DevicePlaylistKind.startup),
        throwsFormatException);
  });
}
