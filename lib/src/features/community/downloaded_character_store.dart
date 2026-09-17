import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../customization/cloud_business_intake.dart';
import '../video/character_video_package.dart';
import 'remote_catalog_repository.dart';
import 'verified_video_cache.dart';

/// Metadata for verified app-owned files. This never creates an entitlement.
class DownloadedCharacterStore {
  DownloadedCharacterStore(this.directory, this.origin);
  final Directory directory;
  final String origin;
  static final _writes = <String, Future<void>>{};
  static String _hash(String value) =>
      sha256.convert(utf8.encode(value)).toString();
  static Future<DownloadedCharacterStore> forAccount(
      Uri baseUri, String accountId) async {
    final root = await getApplicationSupportDirectory();
    final origin = baseUri.origin;
    return DownloadedCharacterStore(
        Directory('${root.path}/cloud_downloads/${_hash(jsonEncode([
              origin,
              accountId
            ]))}'),
        origin);
  }

  static Future<DownloadedCharacterStore?> current() async {
    final cloud = CloudBusinessIntake.instance;
    final uri = cloud.baseUri;
    if (uri == null) return null;
    final account = await cloud.cachedDownloadAccountId();
    return account == null ? null : forAccount(uri, account);
  }

  Future<void> _write(Future<void> Function() action) {
    final key = directory.absolute.path;
    final next = (_writes[key] ?? Future<void>.value()).then((_) => action());
    _writes[key] = next.catchError((Object _) {});
    return next;
  }

  File _metadata(String id) =>
      File('${directory.path}/package-${_hash(id)}.json');
  Future<Map<String, dynamic>?> _read(File file) async {
    try {
      if (await FileSystemEntity.type(file.path, followLinks: false) !=
              FileSystemEntityType.file ||
          await file.length() > 1024 * 1024) {
        return null;
      }
      final raw = jsonDecode(await file.readAsString());
      return raw is Map<String, dynamic> &&
              raw['origin'] == origin &&
              raw['schema'] == 1
          ? raw
          : null;
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<String?> _art(String? url) async {
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.origin != origin ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    final name = 'art-${_hash(url!)}.img';
    final file = File('${directory.path}/$name');
    if (await FileSystemEntity.type(file.path, followLinks: false) ==
        FileSystemEntityType.file) {
      return name;
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    final deadline =
        Timer(const Duration(seconds: 8), () => client.close(force: true));
    try {
      final request =
          await client.getUrl(uri).timeout(const Duration(seconds: 4));
      request.followRedirects = false;
      final response =
          await request.close().timeout(const Duration(seconds: 4));
      if (response.statusCode != 200 ||
          response.contentLength > 2 * 1024 * 1024 ||
          !(response.headers.contentType?.mimeType.startsWith('image/') ??
              false)) {
        return null;
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 4))) {
        bytes.addAll(chunk);
        if (bytes.length > 2 * 1024 * 1024) return null;
      }
      if (bytes.isEmpty) return null;
      await file.writeAsBytes(bytes, flush: true);
      return name;
    } catch (_) {
      return null;
    } finally {
      deadline.cancel();
      client.close(force: true);
    }
  }

  Future<void> save(
          RemoteCatalogPackage package, RemoteCatalogClip clip, File video) =>
      _write(() async {
        final verified = await VerifiedVideoCache(directory, origin)
            .find(package.id, clip.id);
        if (verified == null ||
            await verified.resolveSymbolicLinks() !=
                await video.resolveSymbolicLinks() ||
            !package.clips.any((c) => c.id == clip.id)) {
          throw StateError(
              'Only verified package downloads may enter the library');
        }
        final previous = await _read(_metadata(package.id));
        final clips = Map<String, dynamic>.from(
            previous?['clips'] is Map ? previous!['clips'] as Map : const {});
        clips[clip.id] = {
          'title': clip.title,
          'duration': clip.durationSeconds?.round() ?? 0,
          'thumbnail': await _art(clip.thumbnailUrl)
        };
        final data = {
          'schema': 1,
          'origin': origin,
          'id': package.id,
          'title': package.title,
          'description': package.description,
          'credit': package.credit,
          'totalVideos': package.clips.length,
          'cover': await _art(package.coverThumbnailUrl ?? package.coverUrl) ??
              previous?['cover'],
          'clips': clips
        };
        final target = _metadata(package.id);
        final temporary = File('${target.path}.tmp');
        await temporary.writeAsString(jsonEncode(data), flush: true);
        await temporary.rename(target.path);
      });
  Future<String?> _localArt(dynamic name) async {
    if (name is! String || !RegExp(r'^art-[a-f0-9]{64}\.img$').hasMatch(name)) {
      return null;
    }
    final file = File('${directory.path}/$name');
    return await FileSystemEntity.type(file.path, followLinks: false) ==
            FileSystemEntityType.file
        ? file.path
        : null;
  }

  Future<List<CharacterVideoPackage>> load() async {
    if (!await directory.exists()) return [];
    final result = <CharacterVideoPackage>[];
    await for (final entry in directory.list(followLinks: false)) {
      if (entry is! File ||
          !RegExp(r'package-[a-f0-9]{64}\.json$').hasMatch(entry.path)) {
        continue;
      }
      final data = await _read(entry);
      if (data == null ||
          data['id'] is! String ||
          data['title'] is! String ||
          data['clips'] is! Map) {
        continue;
      }
      final videos = <PackageVideo>[];
      for (final clip in (data['clips'] as Map).entries) {
        if (clip.key is! String || clip.value is! Map) continue;
        final meta = clip.value as Map;
        if (meta['title'] is! String || meta['duration'] is! int) continue;
        final file = await VerifiedVideoCache(directory, origin)
            .find(data['id'] as String, clip.key as String);
        if (file != null) {
          videos.add(PackageVideo(
              id: clip.key as String,
              title: meta['title'] as String,
              source: file.path,
              durationSeconds: meta['duration'] as int,
              asset: false,
              thumbnail: await _localArt(meta['thumbnail'])));
        }
      }
      if (videos.isNotEmpty) {
        result.add(CharacterVideoPackage(
            id: data['id'] as String,
            title: data['title'] as String,
            videos: videos,
            downloaded: true,
            description: data['description'] is String
                ? data['description'] as String
                : '',
            credit: data['credit'] is String ? data['credit'] as String : '',
            totalVideos: data['totalVideos'] is int
                ? data['totalVideos'] as int
                : videos.length,
            cover: await _localArt(data['cover'])));
      }
    }
    return result;
  }

  Future<void> remove(String packageId) => _write(() async {
        final metadata = _metadata(packageId);
        if (!await directory.exists()) return;
        await for (final entry in directory.list(followLinks: false)) {
          if (entry is! Directory ||
              !entry.uri.pathSegments
                  .where((s) => s.isNotEmpty)
                  .last
                  .startsWith('download-')) {
            continue;
          }
          final record = await _read(File('${entry.path}/record.json'));
          if (record?['packageId'] == packageId) {
            await entry.delete(recursive: true);
          }
        }
        if (await metadata.exists()) await metadata.delete();
      });
}
