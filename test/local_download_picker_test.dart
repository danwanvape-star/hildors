import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:hildors_cockpit/src/features/community/downloaded_character_store.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_entitlement_repository.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';
import 'package:hildors_cockpit/src/features/video/character_package_picker.dart';
import 'package:hildors_cockpit/src/features/video/character_video_package.dart';
import 'package:hildors_cockpit/src/features/video/pending_playlist_store.dart';

void main() {
  testWidgets('deletion confirmation removes only managed local files',
      (tester) async {
    late DownloadedCharacterStore store;
    late Directory root;
    late File video;
    late List<CharacterVideoPackage> loaded;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('local-picker-');
      final dir = await Directory('${root.path}/download-a').create();
      video = await File('${dir.path}/video.mp4').writeAsBytes([1]);
      await File('${dir.path}/record.json').writeAsString(jsonEncode({
        'schema': 1,
        'origin': 'https://example.com',
        'packageId': 'p',
        'clipId': 'a',
        'bytes': 1,
        'sha256': sha256.convert([1]).toString()
      }));
      store = _RealIoStore(root, 'https://example.com', tester);
      const clip = RemoteCatalogClip('a', '离线视频', 1);
      await store.save(
          const RemoteCatalogPackage(
              id: 'p',
              title: '下载角色',
              source: 'hildors',
              format: 'single',
              tags: [],
              clips: [clip]),
          clip,
          video);
      loaded = await store.load();
    });
    addTearDown(() => root.delete(recursive: true));
    await tester.pumpWidget(MaterialApp(
        home: CharacterPackagePicker(
            downloadedStore: store,
            loadDownloaded: () async => loaded,
            repository: MemoryCharacterEntitlementRepository([]),
            orderRepository: MemoryCustomizationOrderRepository())));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('下载角色'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('删除本地下载'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(await tester.runAsync(() => video.exists()), isTrue);
    await tester.tap(find.byTooltip('删除本地下载'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pump();
    await (store as _RealIoStore).removal;
    await tester.pumpAndSettle();
    expect(await tester.runAsync(() => video.exists()), isFalse);
    expect(find.text('删除本地下载？'), findsNothing);
  });
  testWidgets(
      'downloaded role coexists with claimed demo and keeps file identity in playlist',
      (tester) async {
    final demo = officialVideoPackages.first;
    final local = CharacterVideoPackage(
        id: demo.id,
        title: '离线角色',
        downloaded: true,
        totalVideos: 3,
        description: '本地介绍',
        credit: '本地作者',
        videos: const [
          PackageVideo(
              id: 'local-clip',
              title: '本地视频',
              source: '/private/download-1/video.mp4',
              durationSeconds: 3,
              asset: false)
        ]);
    Map<String, PendingVideo>? saved;
    await tester.pumpWidget(MaterialApp(
        home: CharacterPackagePicker(
            picking: false,
            repository: MemoryCharacterEntitlementRepository([demo.id]),
            orderRepository: MemoryCustomizationOrderRepository(),
            loadDownloaded: () async => [local],
            saveToPlaylist: (_, videos) async {
              saved = videos;
            })));
    await tester.pumpAndSettle();
    expect(find.text(demo.title), findsOneWidget);
    expect(find.text('已下载 1/3 个视频'), findsOneWidget);
    await tester.tap(find.text('离线角色'));
    await tester.pumpAndSettle();
    expect(find.text('本地介绍'), findsOneWidget);
    expect(find.text('本地作者'), findsOneWidget);
    expect(find.byTooltip('预览本地视频'), findsOneWidget);
    await tester.tap(find.text('本地视频'));
    await tester.pump();
    await tester.tap(find.text('添加 1 个视频到待处理区'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('日常展示'));
    await tester.pumpAndSettle();
    expect(saved!.values.single.asset, isFalse);
    expect(saved!.values.single.source, '/private/download-1/video.mp4');
    expect(saved!.keys.single, startsWith('local/'));
    expect(tester.takeException(), isNull);
  });
}

class _RealIoStore extends DownloadedCharacterStore {
  _RealIoStore(super.directory, super.origin, this.tester);
  final WidgetTester tester;
  Future<void>? removal;
  @override
  Future<void> remove(String packageId) =>
      removal = tester.runAsync(() => super.remove(packageId)).then((_) {});
}
