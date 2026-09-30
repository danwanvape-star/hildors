import 'dart:async';
import 'package:hildors_cockpit/src/features/video/p20_upload_page.dart';
import 'package:hildors_cockpit/src/device/device_access.dart';
import 'package:hildors_cockpit/src/device/p20_device_profile.dart';
import 'package:hildors_cockpit/src/features/video/character_package_page.dart';
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
  Completer<void>? pauseGate;

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
  Future<void> pause(int playerId) async {
    await pauseGate?.future;
  }

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

class UploadClient extends P20DeviceClient {
  UploadClient(this.kind);
  final P20DeviceKind kind;
  @override
  bool get isConnected => true;
  @override
  P20DeviceProfile get profile => P20DeviceProfile.forKind(kind);
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

  testWidgets('upload cannot be submitted twice while preview pause is pending',
      (tester) async {
    var opened = 0;
    await tester.pumpWidget(MaterialApp(
        home: FanFramingPage(
            source: 'https://example.test/video.mp4',
            asset: false,
            onUpload: (_, frame) async {
              opened++;
            })));
    await pumpUi(tester);
    videoPlatform.pauseGate = Completer<void>();
    final upload = find.widgetWithIcon(FilledButton, Icons.upload);
    await tester.scrollUntilVisible(upload, 200);
    await tester.tap(upload);
    await pumpUi(tester);
    await tester.tap(upload);
    await pumpUi(tester);
    videoPlatform.pauseGate!.complete();
    await pumpUi(tester);
    expect(opened, 1);
  });

  testWidgets(
      'explicit return after upload failure reaches playlist and keeps pending video',
      (tester) async {
    await tester
        .runAsync(() => PendingPlaylistStore.save(DevicePlaylistKind.startup, {
              'test': (
                title: 'Pending test',
                source: 'https://example.test/video.mp4',
                asset: false
              )
            }));
    final client = UploadClient(P20DeviceKind.single);
    final session = LiveSession(client);
    addTearDown(client.dispose);
    addTearDown(session.dispose);
    await tester.pumpWidget(MaterialApp(
        home: PlaylistManagementPage(client: client, session: session)));
    await pumpUi(tester);
    final adjust = find.widgetWithText(TextButton, '调整画面');
    await tester.scrollUntilVisible(adjust, 200,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .last);
    await tester.tap(adjust);
    await pumpUi(tester);
    final upload = find.widgetWithIcon(FilledButton, Icons.upload);
    await tester.scrollUntilVisible(upload, 200);
    await tester.tap(upload);
    await pumpUi(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(find.byType(TextField), '测试名称');
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
    await pumpUi(tester);
    expect(find.byType(P20UploadPage), findsOneWidget);
    expect(tester.widget<P20UploadPage>(find.byType(P20UploadPage)).displayName,
        '测试名称');
    final close = find.text('返回列表');
    await tester.ensureVisible(close);
    await tester.tap(close);
    await pumpUi(tester);
    expect(find.byType(FanFramingPage), findsNothing);
    expect(find.byType(PlaylistManagementPage), findsOneWidget);
    expect(find.text('Pending test'), findsOneWidget);
  });

  for (final kind in [P20DeviceKind.single, P20DeviceKind.dual]) {
    testWidgets('My characters opens direct upload for $kind', (tester) async {
      final client = UploadClient(kind);
      final session = P20CommandSession(client);
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) =>
            DeviceAccess(client: client, session: session, child: child!),
        home: CharacterPackagePage(
            package: CharacterVideoPackage(id: 'test', title: 'Test', videos: [
          PackageVideo(
              id: 'clip',
              title: 'Clip',
              source: '/test.mp4',
              asset: false,
              durationSeconds: 1)
        ])),
      ));
      await tester.tap(find.byIcon(Icons.upload));
      await pumpUi(tester);
      if (kind == P20DeviceKind.dual) {
        expect(find.byType(FanFramingPage), findsNothing);
        await tester.tap(find.text('日常展示'));
      }
      await pumpUi(tester);
      expect(find.byType(FanFramingPage), findsOneWidget);
      expect(
          tester.widget<FanFramingPage>(find.byType(FanFramingPage)).onUpload,
          isNotNull);
      expect(find.text('保存展示范围'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await session.dispose();
      await client.dispose();
    });
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

    await tester.tap(find.widgetWithText(FilledButton, '添加视频'));
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

  testWidgets('device-only video no longer exposes framing', (tester) async {
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
      matching: find.byTooltip('调整画面'),
    );
    expect(adjust, findsNothing);
    expect(find.byType(FanFramingPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
