import 'dart:async';
import 'package:hildors_cockpit/src/localization/localization.dart';
import 'dart:io';
import 'package:hildors_cockpit/src/media/preview_video_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/creator_content_media.dart';
import 'package:hildors_cockpit/src/features/community/creator_content_repository.dart';
import 'package:video_player/video_player.dart';
// The native player is replaced at its platform boundary for this widget test.
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:hildors_cockpit/src/features/community/content_preview_player.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_repository.dart';
import 'package:hildors_cockpit/src/features/community/remote_package_detail_page.dart';

class _CreatorMediaRepository implements CreatorContentMediaRepository {
  @override
  Future<CreatorContentMediaAccess> mediaAccess(
          CreatorContent item, CreatorContentClip clip,
          {bool refreshIdentity = false}) async =>
      CreatorContentMediaAccess(
        thumbnail: Uri.parse('https://example.test/private/thumbnail'),
        preview: Uri.parse('https://example.test/private/preview'),
        headers: const {'Authorization': 'Bearer owner-token'},
      );
}

class _PreviewPlatform extends VideoPlayerPlatform {
  bool initializeImmediately = true;
  bool failCachedFile = false;
  final sources = <String?>[];
  final headers = <Map<String, String>>[];
  final events = <int, StreamController<VideoEvent>>{};
  final played = <int>[];
  final disposed = <int>[];
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    sources.add(options.dataSource.uri);
    headers.add(options.dataSource.httpHeaders);
    final id = sources.length;
    events[id] = StreamController<VideoEvent>();
    if (failCachedFile &&
        options.dataSource.sourceType == DataSourceType.file) {
      events[id]!.addError(PlatformException(
          code: 'invalid_video', message: 'invalid cached video'));
    } else if (initializeImmediately) {
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

class _InvalidPreviewCache extends PreviewVideoCache {
  _InvalidPreviewCache()
      : super(origin: Uri(), directory: () async => Directory.systemTemp);
  bool discarded = false;
  @override
  Future<File?> validatedFile(Uri uri, {Future<void>? cancel}) async =>
      discarded ? null : File('${Directory.systemTemp.path}/corrupt.mp4');
  @override
  Future<void> discard(Uri uri) async {
    discarded = true;
  }
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
  testWidgets('English stalled playback offers localized retry', (tester) async {
    platform.initializeImmediately = false;
    await tester.pumpWidget(MaterialApp(locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ContentPreviewPlayer(assetPath: null, networkUrl: 'https://example.test/slow.mp4')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('重试'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async { await Future<void>.delayed(Duration.zero); });
  });

  testWidgets(
      'creator thumbnail does not load video until tapped and opens authenticated player',
      (tester) async {
    const clip = CreatorContentClip(
        id: 'clip',
        title: '我的视频',
        hasMedia: true,
        inspectionStatus: 'checked',
        mediaId: 'media');
    const item = CreatorContent(
        id: 'owned',
        title: '作品',
        format: 'single',
        status: 'draft',
        submissionStatus: 'draft',
        version: 1,
        description: '介绍',
        tags: [],
        clips: [clip]);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 300,
                child: CreatorContentThumbnail(
                    item: item,
                    clip: clip,
                    repository: _CreatorMediaRepository())))));
    await tester.pumpAndSettle();
    expect(platform.sources, isEmpty);
    final image = tester.widget<Image>(find.byType(Image));
    final networkImage =
        (image.image as ResizeImage).imageProvider as NetworkImage;
    expect(networkImage.url, 'https://example.test/private/thumbnail');
    expect(networkImage.headers?['Authorization'], 'Bearer owner-token');
    final onTap = tester
        .widget<InkWell>(find.descendant(
            of: find.byType(CreatorContentThumbnail),
            matching: find.byType(InkWell)))
        .onTap!;
    onTap();
    onTap();
    await tester.pumpAndSettle();
    expect(platform.sources, ['https://example.test/private/preview']);
    expect(platform.headers.single['Authorization'], 'Bearer owner-token');
    expect(platform.played, [1]);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    expect(platform.disposed, [1]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'private preview streams with auth and bypasses public file cache',
      (tester) async {
    final cache = _InvalidPreviewCache();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ContentPreviewPlayer(
                assetPath: null,
                networkUrl: 'https://example.test/private-preview',
                httpHeaders: const {'Authorization': 'Bearer private-token'},
                previewCache: cache,
                autoPlay: true))));
    await tester.pumpAndSettle();
    expect(platform.sources.single, 'https://example.test/private-preview');
    expect(platform.headers.single['Authorization'], 'Bearer private-token');
    expect(platform.played, [1]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('private preview retry obtains fresh auth headers',
      (tester) async {
    platform.initializeImmediately = false;
    var refreshes = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ContentPreviewPlayer(
                assetPath: null,
                networkUrl: 'https://example.test/private',
                httpHeaders: const {'Authorization': 'Bearer old'},
                refreshHttpHeaders: () async {
                  refreshes++;
                  return {'Authorization': 'Bearer new'};
                }))));
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    platform.initializeImmediately = true;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(refreshes, 1);
    expect(platform.headers.last['Authorization'], 'Bearer new');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('invalid cached video falls back to streaming and evicts cache',
      (tester) async {
    platform.failCachedFile = true;
    final cache = _InvalidPreviewCache();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ContentPreviewPlayer(
                assetPath: null,
                networkUrl: 'https://example.test/preview.mp4',
                previewCache: cache,
                autoPlay: true))));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
    expect(cache.discarded, isTrue);
    expect(platform.sources.last, 'https://example.test/preview.mp4');
    expect(platform.played, [2]);
    expect(find.text('视频加载失败，请重试'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('slow initial loading explains buffering and offers retry',
      (tester) async {
    platform.initializeImmediately = false;
    await tester.pumpWidget(const MaterialApp(
        home: ContentPreviewPlayer(
            assetPath: null, networkUrl: 'https://example.test/slow.mp4')));
    await tester.pump();
    expect(find.text('视频正在缓冲，请稍候'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('加载较慢，请检查网络或重试'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    await tester.pump(const Duration(seconds: 21));
    expect(find.text('视频加载超时，请重试'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
  });

  testWidgets('buffering during playback is visible and clears on recovery',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: ContentPreviewPlayer(
                assetPath: null,
                networkUrl: 'https://example.test/play.mp4',
                autoPlay: true))));
    await tester.pumpAndSettle();
    platform.events[1]!
        .add(VideoEvent(eventType: VideoEventType.bufferingStart));
    await tester.pump();
    await tester.pump();
    expect(find.text('视频正在缓冲，请稍候'), findsOneWidget);
    platform.events[1]!.add(VideoEvent(eventType: VideoEventType.bufferingEnd));
    await tester.pumpAndSettle();
    expect(find.text('视频正在缓冲，请稍候'), findsNothing);
    expect(find.byType(VideoPlayer), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
  });

  testWidgets('missing source is empty rather than an endless spinner',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: ContentPreviewPlayer(assetPath: null)));
    expect(find.text('暂无可播放视频'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('retry while initializing releases old player and recovers',
      (tester) async {
    platform.initializeImmediately = false;
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: ContentPreviewPlayer(
                assetPath: null,
                networkUrl: 'https://example.test/retry.mp4'))));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    platform.initializeImmediately = true;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.byType(VideoPlayer), findsOneWidget);
    expect(find.text('视频正在缓冲，请稍候'), findsNothing);
    expect(platform.sources.length, 2);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    expect(platform.disposed, [1, 2]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving a stalled bundled preview releases its native player',
      (tester) async {
    platform.initializeImmediately = false;
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: ContentPreviewPlayer(
                assetPath: 'assets/videos/showcase/showcase_02.mp4'))));
    await tester.pump();
    expect(find.text('视频正在加载，请稍候'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    expect(platform.disposed, [1]);
    expect(tester.takeException(), isNull);
  });

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
