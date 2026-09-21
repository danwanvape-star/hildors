import '../community/creator_content_repository.dart';

const creatorApplicationDirections = ['简单动作', '歌舞表演', '特效炫技', '角色成长'];

class CreatorApplication {
  CreatorApplication(this.data);
  final Map<String, dynamic> data;
  int get version => data['version'] as int? ?? 0;
  String get status => data['status'] as String? ?? 'draft';
  bool get editable =>
      status == 'draft' ||
      status == 'rejected' ||
      (status == 'pending' && data['applicationVersion'] != 2);
  String? get grade => const {
        'silver': '白银',
        'gold': '黄金',
        'diamond': '钻石',
        'master': '宗师',
        'legend': '大神'
      }[data['abilityLevel']];
  List<Map<String, dynamic>> get videos =>
      (data['applicationVideos'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
  String? get reason =>
      data['reviewNote'] as String? ?? data['reviewReason'] as String?;
}

class CreatorApplicationRepository {
  CreatorApplicationRepository({CreatorContentTransport? transport})
      : transport = transport ?? CloudCreatorContentTransport();
  final CreatorContentTransport transport;
  final Map<String, Map<String, String>> _tagLabels = {};
  String tagLabel(String legacyName, String language) {
    final labels = _tagLabels[legacyName];
    return labels?[language] ?? labels?['en'] ?? legacyName;
  }
  static const path = '/v1/me/creator-application';
  Future<List<String>> loadTags() async {
    final response =
        await transport.request(method: 'GET', path: '/v1/content-tags');
    final body = _checked(response);
    _tagLabels.clear();
    for (final raw in body['items'] as List) {
      if (raw is! Map || raw['name'] is! String) continue;
      final translations = raw['translations'];
      final labels = <String, String>{};
      for (final language in ['en', 'zh']) {
        final entry = translations is Map ? translations[language] : null;
        final label = entry is Map ? entry['name'] : null;
        if (label is String && label.trim().isNotEmpty) labels[language] = label;
      }
      labels.putIfAbsent('zh', () => raw['name'] as String);
      _tagLabels[raw['name'] as String] = labels;
    }
    return (body['items'] as List)
        .map((item) => CreatorContentTag.fromJson(item as Map<String, dynamic>))
        .where((tag) => tag.active)
        .map((tag) => tag.name)
        .toList();
  }

  Future<CreatorApplication?> load() async {
    final response = await transport.request(method: 'GET', path: path);
    if (response.statusCode == 404) return null;
    return CreatorApplication(_checked(response));
  }

  Future<CreatorApplication> save(Map<String, dynamic> data) async =>
      CreatorApplication(_checked(
          await transport.request(method: 'POST', path: path, body: data)));
  Future<CreatorApplication> upload(String file, int version) async {
    final name = file.replaceAll('\\', '/').split('/').last;
    return CreatorApplication(_checked(await transport.request(
        method: 'PUT',
        path: '$path/videos?name=${Uri.encodeComponent(name)}',
        filePath: file,
        contentType: 'video/mp4',
        ifMatch: version)));
  }

  Future<CreatorApplication> remove(String id, int version) async =>
      CreatorApplication(_checked(await transport.request(
          method: 'DELETE',
          path: '$path/videos/${Uri.encodeComponent(id)}?version=$version')));
  Future<CreatorApplication> submit(int version) async =>
      CreatorApplication(_checked(await transport.request(
          method: 'POST', path: '$path/submit', body: {'version': version})));
  Map<String, dynamic> _checked(CreatorContentResponse response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body;
    }
    final error = response.body['error'];
    final code =
        response.body['code'] ?? (error is Map ? error['code'] : error);
    final message = const {
      'EMAIL_IN_USE': '该邮箱已被其他创作者使用，请更换邮箱',
      'INVALID_CREATOR_APPLICATION': '请检查英文名称、角色、方向、邮箱及协议确认',
      'UPLOAD_TOO_LARGE': '单个视频不能超过 15 MB，请压缩后重新选择',
      'PROCESSOR_BUSY': '视频检查繁忙，请稍后重试',
      'CREATOR_APPLICATION_LOCKED': '申请已锁定，请刷新查看审核状态',
      'CREATOR_APPLICATION_VIDEO_LIMIT': '最多上传 10 个作品，请移除作品后重试',
      'CREATOR_APPLICATION_VIDEO_INVALID': '视频检查未通过，请选择可正常播放的 MP4 视频重试',
      'CREATOR_APPLICATION_VIDEO_REQUIRED': '请至少上传 1 个检查通过的视频作品',
    }[code];
    if (message != null) throw FormatException(message);
    if (response.statusCode == 409) throw const FormatException('申请已更新，请刷新后重试');
    throw FormatException(error is Map
        ? error['message']?.toString() ?? '操作失败，请重试'
        : response.body['message']?.toString() ?? '操作失败，请重试');
  }
}
