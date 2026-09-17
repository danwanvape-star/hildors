import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:hildors_cockpit/src/features/community/downloaded_character_store.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('account and origin produce distinct stable library directories',
      () async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            channel, (_) async => Directory.systemTemp.path);
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final a = await DownloadedCharacterStore.forAccount(
        Uri.parse('https://example.com'), 'account-a');
    final same = await DownloadedCharacterStore.forAccount(
        Uri.parse('https://example.com/'), 'account-a');
    final b = await DownloadedCharacterStore.forAccount(
        Uri.parse('https://example.com'), 'account-b');
    final other = await DownloadedCharacterStore.forAccount(
        Uri.parse('https://other.example'), 'account-a');
    expect(a.directory.path, same.directory.path);
    expect(a.directory.path, isNot(b.directory.path));
    expect(a.directory.path, isNot(other.directory.path));
  });
  test(
      'verified files merge across store instances and corrupt files disappear',
      () async {
    final root = await Directory.systemTemp.createTemp('library-test-');
    addTearDown(() => root.delete(recursive: true));
    const origin = 'https://example.com';
    const clips = [
      RemoteCatalogClip('a', 'A', 2),
      RemoteCatalogClip('b', 'B', 3)
    ];
    const package = RemoteCatalogPackage(
        id: 'p',
        title: '角色',
        source: 'hildors',
        format: 'package',
        tags: [],
        description: '介绍',
        clips: clips);
    Future<File> video(String id) async {
      final dir = await Directory('${root.path}/download-$id').create();
      final file = await File('${dir.path}/video.mp4').writeAsBytes([1, 2, 3]);
      await File('${dir.path}/record.json').writeAsString(jsonEncode({
        'schema': 1,
        'origin': origin,
        'packageId': 'p',
        'clipId': id,
        'bytes': 3,
        'sha256': sha256.convert([1, 2, 3]).toString()
      }));
      return file;
    }

    final a = await video('a'), b = await video('b');
    final store = DownloadedCharacterStore(root, origin);
    await Future.wait([
      store.save(package, clips[0], a),
      DownloadedCharacterStore(root, origin).save(package, clips[1], b)
    ]);
    final loaded = (await store.load()).single;
    expect(loaded.videos.length, 2);
    expect(loaded.videos.every((v) => !v.asset), isTrue);
    expect(loaded.description, '介绍');
    expect(loaded.totalVideos, 2);
    expect(await DownloadedCharacterStore(root, 'https://other.example').load(),
        isEmpty);
    await a.writeAsBytes([0]);
    expect((await store.load()).single.videos.single.id, 'b');
    final original = await File(
            '${root.parent.path}/original-${root.uri.pathSegments.where((e) => e.isNotEmpty).last}.mp4')
        .writeAsBytes([1]);
    addTearDown(() => original.delete());
    await expectLater(
        store.save(package, clips[0], original), throwsStateError);
    await store.remove('p');
    expect(await store.load(), isEmpty);
    expect(await original.exists(), isTrue);
    expect(await b.exists(), isFalse);
  });
}
