import 'dart:convert';
import 'dart:io';

Future<String> fetchCatalogJson(Uri uri) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    return await (() async {
      final request = await client.getUrl(uri);
      request.followRedirects = false;
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('目录请求失败', uri: uri);
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        if (bytes.length + chunk.length > 2 * 1024 * 1024) {
          throw const FormatException('目录响应过大');
        }
        bytes.addAll(chunk);
      }
      return utf8.decode(bytes);
    })()
        .timeout(const Duration(seconds: 15));
  } finally {
    client.close(force: true);
  }
}
