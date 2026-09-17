import 'dart:math';
import 'dart:typed_data';
import 'cloud_business_intake.dart';

typedef CloudOrderRequest = Future<Map<String, dynamic>> Function(
    String method, String path,
    {Map<String, dynamic>? document, Uint8List? bytes, String? contentType});

String _uuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class CloudOrderMaterial {
  CloudOrderMaterial({required this.name, required this.bytes})
      : slot = _uuid();
  final String name, slot;
  final Uint8List bytes;
  String get contentType => switch (name.split('.').last.toLowerCase()) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'heic' => 'image/heic',
        'heif' => 'image/heif',
        _ => throw const FormatException('仅支持 JPG、PNG、WebP、HEIC、HEIF 图片'),
      };
  void validate() {
    if (bytes.isEmpty || bytes.length > 8 * 1024 * 1024) {
      throw FormatException('$name：图片不能为空且每张不能超过 8 MB');
    }
    contentType;
  }
}

/// Retains request identity and successfully uploaded slots during a retry.
class CloudOrderSubmission {
  CloudOrderSubmission({CloudOrderRequest? request})
      : request = request ?? CloudBusinessIntake.instance.orderRequest;
  final CloudOrderRequest request;
  final String clientRequestId = _uuid();
  String? orderId;
  final _uploaded = <String>{};
  Map<String, dynamic>? _document;
  List<CloudOrderMaterial>? _materials;
  bool get started => _document != null;

  Future<void> submit(
      Map<String, dynamic> document, List<CloudOrderMaterial> materials) async {
    final name = document['characterName'];
    if (name is! String || name.trim().isEmpty || name.length > 120) {
      throw const FormatException('角色名称须为 1 至 120 字');
    }
    final requirements = document['requirements'];
    if (requirements != null &&
        (requirements is! String || requirements.length > 10000)) {
      throw const FormatException('定制要求不能超过 10000 字');
    }
    if (materials.length > 8) throw const FormatException('最多上传 8 张素材');
    for (final material in materials) {
      material.validate();
    }
    _document ??= {...document, 'clientRequestId': clientRequestId};
    _materials ??= List.of(materials);
    if (orderId == null) {
      final response = await request('POST', '/v1/me/customization-orders',
          document: _document);
      final id = response['id'];
      if (id is! String || id.isEmpty) throw const FormatException('订单响应缺少编号');
      orderId = id;
    }
    for (final material in _materials!) {
      if (_uploaded.contains(material.slot)) continue;
      final query =
          Uri(queryParameters: {'name': material.name, 'slot': material.slot})
              .query;
      await request(
          'POST', '/v1/me/customization-orders/$orderId/materials?$query',
          bytes: material.bytes, contentType: material.contentType);
      _uploaded.add(material.slot);
    }
  }
}
