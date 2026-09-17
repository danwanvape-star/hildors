import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
// The native player is replaced at its platform boundary for this widget test.
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:hildors_cockpit/src/features/community/content_preview_player.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_repository.dart';
import 'package:hildors_cockpit/src/features/community/remote_package_detail_page.dart';

class _PreviewPlatform extends VideoPlayerPlatform {
  bool initializeImmediately = true;
  final sources = <String?>[];
  final events = <int, StreamController<VideoEvent>>{};
  final played = <int>[];
  final disposed = <int>[];
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    sources.add(options.dataSource.uri);
    final id = sources.length;
    events[id] = StreamController<VideoEvent>();
    if (initializeImmediately) {
      events[id]!.add(VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 30),
          size: const Size(1920, 1080)));
    }
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => events[playerId]!.stream;
  @override
  Future<void> dispose(int playerId) async {
    disposed.add(playerId);
    await events[playerId]!.close();
  }

  @override
  Future<void> play(int playerId) async => played.add(playerId);
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
  late _PreviewPlatform platform;
  late VideoPlayerPlatform previousPlatform;
  setUp(() {
    previousPlatform = VideoPlayerPlatform.instance;
    platform = _PreviewPlatform();
    VideoPlayerPlatform.instance = platform;
  });
  tearDown(() => VideoPlayerPlatform.instance = previousPlatform);

  testWidgets(
      'thumbnail opens and plays only selected preview, back disposes it',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const item = RemoteCatalogPackage(
        id: 'character',
        title: 'Character',
        source: 'hildors',
        format: 'package',
        tags: [],
        clips: [
          RemoteCatalogClip('idle', 'Idle', 30,
              previewUrl: 'https://example.test/idle.mp4'),
          RemoteCatalogClip('dance', 'Dance', 30,
              previewUrl: 'https://example.test/dance.mp4'),
        ]);
    await tester.pumpWidget(const MaterialApp(
        home: RemotePackageDetailPage(item: item, catalog: [item])));
    await tester.pumpAndSettle();
    expect(platform.sources, isEmpty);
    expect(find.byType(VideoPlayer), findsNothing);
    await tester
        .ensureVisible(find.byKey(const ValueKey('clip-character-dance')));
    await tester.tap(find.byKey(const ValueKey('clip-character-dance')));
    await tester.pumpAndSettle();
    expect(platform.sources, ['https://example.test/dance.mp4']);
    expect(
        tester
            .widget<VideoPlayer>(find.byType(VideoPlayer))
            .controller
            .value
            .isPlaying,
        isTrue);
    expect(platform.played, [1]);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    expect(platform.disposed, [1]);
    expect(find.byType(VideoPlayer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing preview entries stay paused until requested',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: ContentPreviewPlayer(
                assetPath: null,
                networkUrl: 'https://example.test/idle.mp4'))));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<VideoPlayer>(find.byType(VideoPlayer))
            .controller
            .value
            .isPlaying,
        isFalse);
    expect(platform.played, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    expect(platform.disposed, [1]);
  });
  testWidgets('preview pauses when a route or sheet covers it', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(
            body: ContentPreviewPlayer(
                assetPath: null,
                networkUrl: 'https://example.test/idle.mp4',
                autoPlay: true))));
    await tester.pumpAndSettle();
    final controller =
        tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller;
    expect(controller.value.isPlaying, isTrue);
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Framing route'))));
    await tester.pumpAndSettle();
    expect(controller.value.isPlaying, isFalse);
    expect(platform.disposed, isEmpty);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(controller.value.isPlaying, isFalse);
    await tester.tap(find.byTooltip('播放预览'));
    await tester.pumpAndSettle();
    expect(controller.value.isPlaying, isTrue);
    showModalBottomSheet<void>(
        context: tester.element(find.byType(ContentPreviewPlayer)),
        builder: (_) =>
            const SizedBox(height: 80, child: Text('Playlist choices')));
    await tester.pumpAndSettle();
    expect(controller.value.isPlaying, isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    expect(platform.disposed, [1]);
  });

  testWidgets(
      'preview finishing initialization under another route stays paused',
      (tester) async {
    platform.initializeImmediately = false;
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(
            body: ContentPreviewPlayer(
                assetPath: null,
                networkUrl: 'https://example.test/idle.mp4',
                autoPlay: true))));
    await tester.pump();
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Framing route'))));
    await tester.pumpAndSettle();
    platform.events[1]!.add(VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 30),
        size: const Size(1920, 1080)));
    await tester.pumpAndSettle();
    expect(platform.played, isEmpty);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<VideoPlayer>(find.byType(VideoPlayer))
            .controller
            .value
            .isPlaying,
        isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    expect(platform.disposed, [1]);
  });
}
