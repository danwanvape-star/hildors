import '../customization/cloud_business_intake.dart';

class CreatorContentTag {
  const CreatorContentTag({
    required this.id,
    required this.name,
    required this.active,
  });

  final String id;
  final String name;
  final bool active;

  factory CreatorContentTag.fromJson(Map<String, dynamic> value) {
    final id = value['id'];
    final name = value['name'];
    final active = value['active'];
    if (id is! String ||
        id.isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        active is! bool) {
      throw const FormatException('内容标签响应无效');
    }
    return CreatorContentTag(id: id, name: name.trim(), active: active);
  }
}

class CreatorContentClipDraft {
  const CreatorContentClipDraft({required this.id, required this.title});

  final String id;
  final String title;

  Map<String, dynamic> toJson() => {'id': id, 'title': title};
}

class CreatorContentClip {
  const CreatorContentClip({
    required this.id,
    required this.title,
    required this.hasMedia,
    required this.inspectionStatus,
  });

  final String id;
  final String title;
  final bool hasMedia;
  final String? inspectionStatus;

  bool get inspectionPassed => inspectionStatus == 'checked';

  factory CreatorContentClip.fromJson(Map<String, dynamic> value) {
    final id = value['id'];
    final title = value['title'];
    if (id is! String || id.isEmpty || title is! String || title.isEmpty) {
      throw const FormatException('投稿视频响应无效');
    }
    final media = value['media'];
    final mediaMap = media is Map<String, dynamic> ? media : null;
    final inspection = mediaMap?['inspection'];
    final inspectionMap =
        inspection is Map<String, dynamic> ? inspection : null;
    return CreatorContentClip(
      id: id,
      title: title,
      hasMedia: mediaMap != null,
      inspectionStatus: inspectionMap?['status'] as String?,
    );
  }
}

class CreatorContent {
  const CreatorContent({
    required this.id,
    required this.title,
    required this.format,
    required this.status,
    required this.submissionStatus,
    required this.version,
    required this.description,
    required this.tags,
    required this.clips,
    this.hasCover = false,
    this.reviewNote,
  });

  final String id;
  final String title;
  final String format;
  final String status;
  final String submissionStatus;
  final int version;
  final String description;
  final List<String> tags;
  final List<CreatorContentClip> clips;
  final bool hasCover;
  final String? reviewNote;

  bool get editable =>
      status == 'draft' &&
      (submissionStatus == 'draft' || submissionStatus == 'rejected');

  factory CreatorContent.fromJson(Map<String, dynamic> value) {
    String text(String key) {
      final result = value[key];
      if (result is! String || result.trim().isEmpty) {
        throw FormatException('投稿字段缺失：$key');
      }
      return result.trim();
    }

    final version = value['version'];
    final rawTags = value['tags'];
    final rawClips = value['clips'];
    if (version is! int ||
        version < 1 ||
        rawTags is! List ||
        rawClips is! List ||
        rawClips.isEmpty) {
      throw const FormatException('投稿响应无效');
    }
    final review = value['review'];
    final reviewMap = review is Map<String, dynamic> ? review : null;
    final rawDescription = value['description'];
    return CreatorContent(
      id: text('id'),
      title: text('title'),
      format: text('format'),
      status: text('status'),
      submissionStatus: text('submissionStatus'),
      version: version,
      description: rawDescription is String ? rawDescription.trim() : '',
      tags: rawTags.map((tag) {
        if (tag is! String) throw const FormatException('投稿标签响应无效');
        return tag;
      }).toList(growable: false),
      clips: rawClips.map((clip) {
        if (clip is! Map<String, dynamic>) {
          throw const FormatException('投稿视频响应无效');
        }
        return CreatorContentClip.fromJson(clip);
      }).toList(growable: false),
      hasCover: value['cover'] is Map<String, dynamic>,
      reviewNote: reviewMap?['note'] as String?,
    );
  }
}

class CreatorContentResponse {
  const CreatorContentResponse(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;
}

abstract interface class CreatorContentTransport {
  Future<CreatorContentResponse> request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    String? filePath,
    String? contentType,
    int? ifMatch,
  });
}

class CloudCreatorContentTransport implements CreatorContentTransport {
  CloudCreatorContentTransport([CloudBusinessIntake? intake])
      : intake = intake ?? CloudBusinessIntake.instance;

  final CloudBusinessIntake intake;

  @override
  Future<CreatorContentResponse> request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    String? filePath,
    String? contentType,
    int? ifMatch,
  }) async {
    final response = await intake.contentRequest(
      method,
      path,
      document: body,
      filePath: filePath,
      contentType: contentType,
      ifMatch: ifMatch,
    );
    return CreatorContentResponse(response.statusCode, response.body);
  }
}

class CreatorContentException implements Exception {
  const CreatorContentException({
    required this.message,
    this.code,
    this.statusCode,
    this.sessionExpired = false,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final bool sessionExpired;

  @override
  String toString() => message;
}

abstract interface class CreatorContentRepository {
  Future<List<CreatorContentTag>> loadTags();
  Future<List<CreatorContent>> loadOwned();
  Future<CreatorContent> create({
    required String title,
    required String format,
    required List<String> tags,
    required String description,
    required List<CreatorContentClipDraft> clips,
  });
  Future<CreatorContent> updateMetadata(
    CreatorContent item, {
    required String title,
    required List<String> tags,
    required String description,
  });
  Future<CreatorContent> uploadClip(
    CreatorContent item, {
    required String clipId,
    required String filePath,
  });
  Future<CreatorContent> uploadCover(
    CreatorContent item, {
    required String filePath,
    required String contentType,
  });
  Future<CreatorContent> inspect(CreatorContent item, String clipId);
  Future<CreatorContent> submit(CreatorContent item);
}

class RemoteCreatorContentRepository implements CreatorContentRepository {
  const RemoteCreatorContentRepository(this.transport);

  final CreatorContentTransport transport;

  @override
  Future<List<CreatorContentTag>> loadTags() async {
    final body = await _request(method: 'GET', path: '/v1/content-tags');
    final items = body['items'];
    if (items is! List) throw const FormatException('内容标签响应无效');
    return items.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('内容标签响应无效');
      }
      return CreatorContentTag.fromJson(item);
    }).toList(growable: false);
  }

  @override
  Future<List<CreatorContent>> loadOwned() async {
    final result = <CreatorContent>[];
    final ids = <String>{}, cursors = <String>{};
    String? cursor;
    for (var page = 0; page < 250; page++) {
      final suffix =
          cursor == null ? '' : '&cursor=${Uri.encodeQueryComponent(cursor)}';
      final body =
          await _request(method: 'GET', path: '/v1/me/content?limit=20$suffix');
      final items = body['items'];
      if (items is! List) throw const FormatException('投稿列表响应无效');
      for (final raw in items) {
        if (raw is! Map<String, dynamic>) {
          throw const FormatException('投稿列表响应无效');
        }
        final item = CreatorContent.fromJson(raw);
        if (!ids.add(item.id)) throw const FormatException('投稿分页发生变化，请刷新');
        result.add(item);
      }
      final next = body['nextCursor'];
      if (next == null) return result;
      if (next is! String || next.isEmpty || !cursors.add(next)) {
        throw const FormatException('投稿分页无效');
      }
      cursor = next;
    }
    throw const FormatException('投稿数量过大，请联系运营协助管理');
  }

  @override
  Future<CreatorContent> create({
    required String title,
    required String format,
    required List<String> tags,
    required String description,
    required List<CreatorContentClipDraft> clips,
  }) async =>
      CreatorContent.fromJson(await _request(
        method: 'POST',
        path: '/v1/me/content',
        body: {
          'title': title,
          'format': format,
          'tags': tags,
          'description': description,
          'clips': clips.map((clip) => clip.toJson()).toList(growable: false),
        },
      ));

  @override
  Future<CreatorContent> updateMetadata(
    CreatorContent item, {
    required String title,
    required List<String> tags,
    required String description,
  }) async =>
      CreatorContent.fromJson(await _request(
        method: 'POST',
        path: '/v1/me/content/${Uri.encodeComponent(item.id)}/metadata',
        body: {
          'version': item.version,
          'title': title,
          'tags': tags,
          'description': description,
        },
      ));

  @override
  Future<CreatorContent> uploadClip(
    CreatorContent item, {
    required String clipId,
    required String filePath,
  }) async =>
      CreatorContent.fromJson(await _request(
        method: 'PUT',
        path:
            '/v1/me/content/${Uri.encodeComponent(item.id)}/clips/${Uri.encodeComponent(clipId)}/media',
        filePath: filePath,
        contentType: 'video/mp4',
        ifMatch: item.version,
      ));

  @override
  Future<CreatorContent> uploadCover(
    CreatorContent item, {
    required String filePath,
    required String contentType,
  }) async =>
      CreatorContent.fromJson(await _request(
        method: 'PUT',
        path: '/v1/me/content/${Uri.encodeComponent(item.id)}/cover',
        filePath: filePath,
        contentType: contentType,
        ifMatch: item.version,
      ));

  @override
  Future<CreatorContent> inspect(CreatorContent item, String clipId) async =>
      CreatorContent.fromJson(await _request(
        method: 'POST',
        path:
            '/v1/me/content/${Uri.encodeComponent(item.id)}/clips/${Uri.encodeComponent(clipId)}/inspect',
        body: {'version': item.version},
      ));

  @override
  Future<CreatorContent> submit(CreatorContent item) async =>
      CreatorContent.fromJson(await _request(
        method: 'POST',
        path: '/v1/me/content/${Uri.encodeComponent(item.id)}/submit',
        body: {'version': item.version},
      ));

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    String? filePath,
    String? contentType,
    int? ifMatch,
  }) async {
    final response = await transport.request(
      method: method,
      path: path,
      body: body,
      filePath: filePath,
      contentType: contentType,
      ifMatch: ifMatch,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body;
    }
    final code = response.body['code'] as String?;
    if (response.statusCode == 401) {
      throw CreatorContentException(
        message: '登录已失效，请重新认证创作者身份',
        code: code,
        statusCode: response.statusCode,
        sessionExpired: true,
      );
    }
    throw CreatorContentException(
      message: _messageFor(code, response.statusCode),
      code: code,
      statusCode: response.statusCode,
    );
  }

  String _messageFor(String? code, int statusCode) => switch (code) {
        'CREATOR_APPROVAL_REQUIRED' => '仅已认证且具备投稿权限的创作者可以使用此功能',
        'VERSION_OR_STATE_CONFLICT' => '投稿状态已经变化，请刷新后重试',
        'MEDIA_REVIEW_REQUIRED' => '请先上传并检查全部视频',
        'PACKAGE_COVER_REQUIRED' => '内容包需要先上传封面',
        'INVALID_CONTENT_TAGS' => '所选标签已失效，请刷新后重新选择',
        _ => statusCode >= 500 ? '服务暂时不可用，请稍后重试' : '操作未完成，请检查内容后重试',
      };
}
