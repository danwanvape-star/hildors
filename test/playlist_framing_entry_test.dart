import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_command_session.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/features/customization/character_entitlement_repository.dart';
import 'package:hildors_cockpit/src/features/video/character_video_package.dart';
import 'package:hildors_cockpit/src/features/video/device_playlist_draft.dart';
import 'package:hildors_cockpit/src/features/video/fan_framing_page.dart';
import 'package:hildors_cockpit/src/features/video/pending_playlist_store.dart';
import 'package:hildors_cockpit/src/features/video/playlist_management_page.dart';
import 'p20_live_playlist_test.dart' show LiveClient, LiveSession;
// The native player is replaced at its platform boundary for widget tests.
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class _FramingVideoPlatform extends VideoPlayerPlatform {
  final sources = <String?>[];

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    sources.add(options.dataSource.uri);
    return sources.length;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => Stream.value(VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 30),
        size: const Size(1920, 1080),
      ));

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  late Directory directory;
  late VideoPlayerPlatform previousVideoPlatform;
  late _FramingVideoPlatform videoPlatform;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('playlist_framing_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (_) async => directory.path);
    previousVideoPlatform = VideoPlayerPlatform.instance;
    videoPlatform = _FramingVideoPlatform();
    VideoPlayerPlatform.instance = videoPlatform;
  });

  tearDown(() async {
    VideoPlayerPlatform.instance = previousVideoPlatform;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, null);
    await directory.delete(recursive: true);
  });

  Future<void> pumpUi(WidgetTester tester) async {
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<({P20DeviceClient client, P20CommandSession session})> pumpPlaylist(
      WidgetTester tester) async {
    final client = P20DeviceClient();
    final session = P20CommandSession(client);
    addTearDown(() async {
      await session.dispose();
      await client.dispose();
    });
    await tester.pumpWidget(MaterialApp(
      home: PlaylistManagementPage(client: client, session: session),
    ));
    await pumpUi(tester);
    return (client: client, session: session);
  }

  testWidgets('HTTPS pending video has a labeled framing action and opens it',
      (tester) async {
    const source = 'https://example.test/cloud-preview.mp4';
    await tester.runAsync(() => PendingPlaylistStore.save(
          DevicePlaylistKind.startup,
          {
            'cloud:role:idle': (
              title: '云端角色 · 待机',
              source: source,
              asset: false
            ),
          },
        ));
    await pumpPlaylist(tester);

    final pendingTile = find.ancestor(
      of: find.text('云端角色 · 待机'),
      matching: find.byType(ListTile),
    );
    final adjust = find.descendant(
      of: pendingTile,
      matching: find.widgetWithText(TextButton, '调整画面'),
    );
    expect(adjust, findsOneWidget);
    await tester.ensureVisible(adjust);

    await tester.tap(adjust);
    await pumpUi(tester);
    expect(find.byType(FanFramingPage), findsOneWidget);
    expect(videoPlatform.sources, [source]);
  });

  test('saved framing is restored for the same source and asset identity',
      () async {
    const source = 'https://example.test/cloud-preview.mp4';
    const framing = FanFraming(scale: 1.8, x: 0.2, y: -0.1);
    await FanFramingDraftStore.save(
      source: source,
      asset: false,
      framing: framing,
      sourceSize: const Size(1920, 1080),
    );

    final restored =
        await FanFramingDraftStore.load(source: source, asset: false);
    expect(restored?.scale, framing.scale);
    expect(restored?.x, framing.x);
    expect(restored?.y, framing.y);
    expect(
        await FanFramingDraftStore.load(source: source, asset: true), isNull);
  });

  testWidgets(
      'single role-video selection opens framing after saving pending item',
      (tester) async {
    final package = officialVideoPackages.first;
    await tester.runAsync(
        () => const LocalCharacterEntitlementRepository().claim(package.id));
    await pumpPlaylist(tester);

    await tester.tap(find.byTooltip('添加视频'));
    await pumpUi(tester);
    await tester.tap(find.text('从我的角色选择'));
    await pumpUi(tester);
    await tester.tap(find.text(package.title));
    await pumpUi(tester);
    await tester.tap(find.text(package.videos.single.title));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '添加 1 个视频到待处理区'));
    await pumpUi(tester);

    expect(find.byType(FanFramingPage), findsOneWidget);
    final pending = await tester
        .runAsync(() => PendingPlaylistStore.load(DevicePlaylistKind.startup));
    expect(
        pending!.keys, contains('${package.id}/${package.videos.single.id}'));
  });

  testWidgets('device-only video asks for the original source before framing',
      (tester) async {
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = LiveClient()..online = true;
    final session = LiveSession(client);
    addTearDown(session.dispose);
    addTearDown(client.dispose);
    await tester.pumpWidget(MaterialApp(
        home: PlaylistManagementPage(client: client, session: session)));
    await pumpUi(tester);

    final deviceTile = find.ancestor(
      of: find.text('a.mp4'),
      matching: find.byType(Card),
    );
    final adjust = find.descendant(
      of: deviceTile,
      matching: find.widgetWithText(TextButton, '调整画面'),
    );
    expect(adjust, findsOneWidget);
    await tester.ensureVisible(adjust);
    tester.widget<TextButton>(adjust).onPressed!();
    await pumpUi(tester);

    expect(find.text('需要原始视频'), findsOneWidget);
    expect(find.textContaining('设备中的文件只有文件名'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '选择原始视频'), findsOneWidget);
    expect(find.byType(FanFramingPage), findsNothing);
    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await pumpUi(tester);
    expect(tester.takeException(), isNull);
  });
}
