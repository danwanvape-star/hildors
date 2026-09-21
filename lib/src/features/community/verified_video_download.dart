import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

class DownloadCancelled implements Exception {}

class DownloadCancellation {
  bool _cancelled = false;
  final Set<void Function()> _listeners = {};
  void cancel() {
    _cancelled = true;
    for (final listener in _listeners.toList()) {
      listener();
    }
  }

  void check() {
    if (_cancelled) throw DownloadCancelled();
  }
}

/// IO-only download primitive. Not wired to production login or playlist UI yet.
class VerifiedVideoDownload {
  VerifiedVideoDownload(this.baseUri, this.cacheDirectory) {
    final local = ['127.0.0.1', 'localhost', '::1'].contains(baseUri.host);
    if (baseUri.host.isEmpty ||
        (baseUri.scheme != 'https' && !(baseUri.scheme == 'http' && local)) ||
        baseUri.userInfo.isNotEmpty ||
        baseUri.hasQuery ||
        baseUri.hasFragment ||
        !['', '/'].contains(baseUri.path)) {
      throw ArgumentError('需要HTTPS服务地址（本机联调除外）');
    }
  }
  final Uri baseUri;
  final Directory cacheDirectory;

  Future<File> download(
      {required String packageId,
      required String clipId,
      required String sessionToken,
      String? customOrderId,
      DownloadCancellation? cancellation,
      void Function()? onVerifying,
      void Function(int received, int total)? onProgress}) async {
    if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(sessionToken)) {
      throw ArgumentError('会话无效');
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    Directory? staging;
    void abort() => client.close(force: true);
    cancellation?._listeners.add(abort);
    try {
      cancellation?.check();
      if (customOrderId != null &&
          (packageId != 'custom-order-$customOrderId' ||
              !RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(customOrderId))) {
        throw const FormatException('Invalid custom order');
      }
      final prefix = customOrderId != null
          ? '/v1/me/customization-orders/$customOrderId'
          : '/v1/me/packages/${Uri.encodeComponent(packageId)}/clips/${Uri.encodeComponent(clipId)}';
      Future<HttpClientResponse> get(String path) async {
        final request = await client.getUrl(baseUri.resolve(path));
        request.followRedirects = false;
        request.headers
            .set(HttpHeaders.authorizationHeader, 'Bearer $sessionToken');
        final response = await request.close();
        if (response.statusCode != 200) {
          throw const HttpException('下载服务暂不可用或无访问权限');
        }
        return response;
      }

      final response =
          await get('$prefix/manifest').timeout(const Duration(seconds: 20));
      final raw = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 20))) {
        if (raw.length + chunk.length > 65536) {
          throw const FormatException('下载清单过大');
        }
        raw.addAll(chunk);
      }
      final manifest = jsonDecode(utf8.decode(raw));
      if (manifest is! Map<String, dynamic> ||
          manifest['packageId'] != packageId ||
          manifest['clipId'] != clipId ||
          manifest['bytes'] is! int ||
          manifest['bytes'] <= 0 ||
          manifest['bytes'] > 256 * 1024 * 1024 ||
          manifest['sha256'] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(manifest['sha256'] as String) ||
          manifest['contentType'] != 'video/mp4' ||
          manifest['authorizationRequired'] != true ||
          manifest['downloadPath'] != '$prefix/download') {
        throw const FormatException('下载清单无效');
      }
      final expectedBytes = manifest['bytes'] as int;
      await cacheDirectory.create(recursive: true);
      cancellation?.check();
      // Unique directory avoids overwriting another download or an existing valid cache.
      staging = await cacheDirectory.createTemp('download-');
      final temporary = File('${staging.path}/video.part');
      final media =
          await get('$prefix/download').timeout(const Duration(seconds: 20));
      final sink = temporary.openWrite();
      var received = 0;
      try {
        await for (final chunk in media.timeout(const Duration(seconds: 30))) {
          cancellation?.check();
          received += chunk.length;
          if (received > expectedBytes) throw const FormatException('视频大小不符');
          sink.add(chunk);
          await sink.flush();
          onProgress?.call(received, expectedBytes);
        }
      } finally {
        await sink.close();
      }
      cancellation?.check();
      onVerifying?.call();
      if (received != expectedBytes ||
          (await sha256.bind(temporary.openRead()).first).toString() !=
              manifest['sha256']) {
        throw const FormatException('视频完整性校验失败');
      }
      cancellation?.check();
      final result = await temporary.rename('${staging.path}/video.mp4');
      cancellation?.check();
      final record = File('${staging.path}/record.part');
      await record.writeAsString(
          jsonEncode({
            'schema': 1,
            'origin': baseUri.origin,
            'packageId': packageId,
            'clipId': clipId,
            'bytes': expectedBytes,
            'sha256': manifest['sha256'],
          }),
          flush: true);
      cancellation?.check();
      await record.rename('${staging.path}/record.json');
      cancellation?.check();
      staging = null;
      return result;
    } catch (_) {
      cancellation?.check();
      rethrow;
    } finally {
      cancellation?._listeners.remove(abort);
      client.close(force: true);
      if (staging != null && await staging.exists()) {
        await staging.delete(recursive: true);
      }
    }
  }
}
