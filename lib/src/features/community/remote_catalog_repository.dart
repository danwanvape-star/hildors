import 'dart:convert';
import 'remote_catalog_transport_stub.dart'
    if (dart.library.io) 'remote_catalog_transport_io.dart' as transport;

class RemoteCatalogClip {
  const RemoteCatalogClip(this.id, this.title, this.durationSeconds,
      {this.previewUrl, this.thumbnailUrl});
  final String id, title;
  final double? durationSeconds;
  final String? previewUrl, thumbnailUrl;
}

class RemoteCatalogPackage {
  const RemoteCatalogPackage(
      {required this.id,
      required this.title,
      required this.source,
      required this.format,
      required this.tags,
      this.coverUrl,
      this.description = '',
      this.creatorId,
      this.creatorName,
      this.anonymous = false,
      required this.clips});
  final String id, title, source, format;
  final String? coverUrl;
  final String description;
  final String? creatorId, creatorName;
  final bool anonymous;
  bool get hasPublicCreator =>
      source == 'creator' &&
      !anonymous &&
      creatorId?.trim().isNotEmpty == true &&
      creatorName?.trim().isNotEmpty == true;
  String get credit => source == 'hildors'
      ? 'HILDORS 出品'
      : hasPublicCreator
          ? creatorName!.trim()
          : '匿名创作者';
  final List<String> tags;
  final List<RemoteCatalogClip> clips;

  factory RemoteCatalogPackage.fromJson(Map<String, dynamic> value) {
    String requiredText(Map<String, dynamic> object, String key) {
      final text = object[key];
      if (text is! String || text.trim().isEmpty) {
        throw FormatException('目录字段缺失：$key');
      }
      return text;
    }

    if (value['status'] != 'published' ||
        !['hildors', 'creator'].contains(value['source']) ||
        !['single', 'package'].contains(value['format']) ||
        value['tags'] is! List ||
        value['clips'] is! List ||
        (value['clips'] as List).isEmpty) {
      throw const FormatException('目录格式无效');
    }
    final clips = (value['clips'] as List).map((raw) {
      if (raw is! Map<String, dynamic>) throw const FormatException('视频格式无效');
      final duration = raw['durationSeconds'];
      if (duration != null &&
          (duration is! num || !duration.isFinite || duration < 0)) {
        throw const FormatException('视频时长无效');
      }
      return RemoteCatalogClip(requiredText(raw, 'id'),
          requiredText(raw, 'title'), (duration as num?)?.toDouble(),
          previewUrl: raw['previewPath'] as String?,
          thumbnailUrl: raw['thumbnailPath'] as String?);
    }).toList(growable: false);
    if (clips.map((c) => c.id).toSet().length != clips.length ||
        (value['format'] == 'single' && clips.length != 1)) {
      throw const FormatException('视频清单无效');
    }
    final rawCreator = value['creator'];
    final creator = rawCreator is Map<String, dynamic>
        ? rawCreator
        : const <String, dynamic>{};
    final anonymous = creator['anonymous'] != false;
    String? creatorText(String key) => !anonymous && creator[key] is String
        ? (creator[key] as String).trim()
        : null;
    return RemoteCatalogPackage(
        description: value['description'] is String
            ? (value['description'] as String).trim()
            : '',
        creatorId: creatorText('id'),
        creatorName: creatorText('name'),
        anonymous: anonymous,
        id: requiredText(value, 'id'),
        title: requiredText(value, 'title'),
        source: value['source'] as String,
        format: value['format'] as String,
        coverUrl: value['coverPath'] as String?,
        tags: (value['tags'] as List).map((t) {
          if (t is! String) throw const FormatException('标签格式无效');
          return t;
        }).toList(growable: false),
        clips: clips);
  }
}

class RemoteCatalogRepository {
  RemoteCatalogRepository(String baseUrl, {Future<String> Function(Uri)? fetch})
      : baseUri = Uri.parse(baseUrl),
        _fetch = fetch ?? transport.fetchCatalogJson {
    if (!['http', 'https'].contains(baseUri.scheme) ||
        baseUri.host.isEmpty ||
        baseUri.userInfo.isNotEmpty ||
        baseUri.hasQuery ||
        baseUri.hasFragment ||
        (baseUri.path.isNotEmpty && baseUri.path != '/')) {
      throw ArgumentError('后台地址必须是HTTP(S)服务根地址');
    }
  }
  final Uri baseUri;
  final Future<String> Function(Uri) _fetch;

  Future<List<RemoteCatalogPackage>> load() async {
    final result = <RemoteCatalogPackage>[];
    final seenIds = <String>{}, seenCursors = <String>{};
    String? cursor;
    for (var page = 0; page < 50; page++) {
      final uri = baseUri.replace(path: '/v1/catalog', queryParameters: {
        'limit': '100',
        if (cursor != null) 'cursor': cursor,
      });
      final data = jsonDecode(await _fetch(uri));
      if (data is! Map<String, dynamic> || data['items'] is! List) {
        throw const FormatException('目录响应无效');
      }
      for (final raw in data['items'] as List) {
        if (raw is! Map<String, dynamic>) throw const FormatException('目录条目无效');
        final item = _withAbsoluteUrls(RemoteCatalogPackage.fromJson(raw));
        if (!seenIds.add(item.id)) throw const FormatException('目录分页发生变化，请刷新');
        result.add(item);
      }
      final next = data['nextCursor'];
      if (next == null) return result;
      if (next is! String || next.isEmpty || !seenCursors.add(next)) {
        throw const FormatException('目录分页无效');
      }
      cursor = next;
    }
    throw const FormatException('目录过大，请缩小查询范围');
  }

  RemoteCatalogPackage _withAbsoluteUrls(RemoteCatalogPackage package) {
    String? absolute(String? value) => value == null || value.isEmpty
        ? null
        : baseUri.resolve(value).toString();
    return RemoteCatalogPackage(
      id: package.id,
      title: package.title,
      source: package.source,
      format: package.format,
      coverUrl: absolute(package.coverUrl),
      description: package.description,
      creatorId: package.creatorId,
      creatorName: package.creatorName,
      anonymous: package.anonymous,
      tags: package.tags,
      clips: package.clips
          .map((clip) => RemoteCatalogClip(
                clip.id,
                clip.title,
                clip.durationSeconds,
                previewUrl: absolute(clip.previewUrl),
                thumbnailUrl: absolute(clip.thumbnailUrl),
              ))
          .toList(growable: false),
    );
  }
}
