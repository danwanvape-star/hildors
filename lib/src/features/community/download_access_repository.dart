import 'dart:convert';
import 'dart:io';

enum DownloadAccess { allowed, signInRequired, disabled, unavailable }

class DownloadAccessRepository {
  DownloadAccessRepository(this.baseUri) {
    final local = ['127.0.0.1', 'localhost', '::1'].contains(baseUri.host);
    if (baseUri.host.isEmpty ||
        (baseUri.scheme != 'https' && !(baseUri.scheme == 'http' && local)) ||
        baseUri.userInfo.isNotEmpty ||
        baseUri.hasQuery ||
        baseUri.hasFragment ||
        !['', '/'].contains(baseUri.path)) {
      throw ArgumentError('需要HTTPS服务根地址（本机联调除外）');
    }
  }
  final Uri baseUri;

  Future<DownloadAccess> check(
      String packageId, String clipId, String? token) async {
    if (token == null || !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token)) {
      return DownloadAccess.signInRequired;
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      return await (() async {
        final uri = baseUri.replace(pathSegments: [
          '',
          'v1',
          'me',
          'packages',
          packageId,
          'clips',
          clipId,
          'access'
        ]);
        final request = await client.getUrl(uri);
        request.followRedirects = false;
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        final response = await request.close();
        if (response.statusCode == 401) return DownloadAccess.signInRequired;
        if (response.statusCode != 200) throw const HttpException('权限检查失败');
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > 8192) {
            throw const FormatException('权限响应过大');
          }
          bytes.addAll(chunk);
        }
        final data = jsonDecode(utf8.decode(bytes));
        if (data is! Map<String, dynamic>) {
          throw const FormatException('权限响应无效');
        }
        if (data['canDownload'] == true && data['reason'] == 'ALLOWED') {
          return DownloadAccess.allowed;
        }
        if (data['canDownload'] != false) throw const FormatException('权限响应无效');
        return switch (data['reason']) {
          'DOWNLOAD_NOT_ENABLED' => DownloadAccess.disabled,
          'CONTENT_UNAVAILABLE' => DownloadAccess.unavailable,
          _ => throw const FormatException('权限响应无效'),
        };
      })()
          .timeout(const Duration(seconds: 15));
    } finally {
      client.close(force: true);
    }
  }
}
