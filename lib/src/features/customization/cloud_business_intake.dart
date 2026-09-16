import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class CloudBusinessIntake {
  CloudBusinessIntake._();

  static final CloudBusinessIntake instance = CloudBusinessIntake._();
  static const _baseUrl = String.fromEnvironment('HILDORS_API_BASE_URL');
  static const _tokenFileName = 'cloud_business_session.json';

  Uri? get _baseUri {
    if (_baseUrl.isEmpty) return null;
    final uri = Uri.tryParse(_baseUrl);
    if (uri == null || uri.host.isEmpty) return null;
    final local = const {'localhost', '127.0.0.1', '::1'}.contains(uri.host);
    if (uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !const ['', '/'].contains(uri.path) ||
        (uri.scheme != 'https' && !(local && uri.scheme == 'http'))) {
      return null;
    }
    return uri;
  }

  Future<File> _tokenFile() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}character_gate',
    );
    await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}$_tokenFileName');
  }

  Future<String?> _storedToken() async {
    try {
      final file = await _tokenFile();
      if (!await file.exists()) return null;
      final value = jsonDecode(await file.readAsString());
      final token = value is Map<String, dynamic> ? value['token'] : null;
      return token is String && RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token)
          ? token
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearToken() async {
    try {
      final file = await _tokenFile();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<String> _session(HttpClient client, Uri baseUri) async {
    final existing = await _storedToken();
    if (existing != null) return existing;
    final request = await client.postUrl(baseUri.resolve('/v1/device-session'));
    request.followRedirects = false;
    final response = await request.close();
    final value = await _readJson(response);
    final token = value['token'];
    if (response.statusCode != HttpStatus.created ||
        token is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token)) {
      throw const HttpException('无法建立云端会话');
    }
    final file = await _tokenFile();
    await file.writeAsString(jsonEncode({'token': token}), flush: true);
    return token;
  }

  Future<Map<String, dynamic>> _readJson(HttpClientResponse response) async {
    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > 128 * 1024) {
        throw const FormatException('云端响应过大');
      }
      bytes.addAll(chunk);
    }
    final value = jsonDecode(utf8.decode(bytes));
    if (value is! Map<String, dynamic>) {
      throw const FormatException('云端响应无效');
    }
    return value;
  }

  Future<bool> _post(String path, Map<String, dynamic> document) async {
    final baseUri = _baseUri;
    if (baseUri == null) return true;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      return await (() async {
        for (var attempt = 0; attempt < 2; attempt++) {
          final token = await _session(client, baseUri);
          final request = await client.postUrl(baseUri.resolve(path));
          request.followRedirects = false;
          request.headers
            ..set(HttpHeaders.authorizationHeader, 'Bearer $token')
            ..contentType = ContentType.json;
          request.write(jsonEncode(document));
          final response = await request.close();
          await _readJson(response);
          if (response.statusCode >= 200 && response.statusCode < 300) {
            return true;
          }
          if (response.statusCode != HttpStatus.unauthorized || attempt > 0) {
            return false;
          }
          await _clearToken();
        }
        return false;
      })()
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<bool> submitCustomizationOrder({
    required String characterName,
    required String sourceType,
    required List<String> requestedFeatures,
    required String privacyConsentVersion,
    required int materialCount,
    required String marketRegion,
  }) =>
      _post('/v1/me/customization-orders', {
        'characterName': characterName,
        'sourceType': sourceType,
        'requestedFeatures': requestedFeatures,
        'privacyConsentVersion': privacyConsentVersion,
        'materialCount': materialCount,
        'marketRegion': marketRegion,
      });

  Future<bool> submitCreatorProfile({
    required String displayName,
    required String portfolioUrl,
    required String agreementVersion,
    required List<String> skillTags,
    required String marketRegion,
  }) =>
      _post('/v1/me/creator-profile', {
        'displayName': displayName,
        'portfolioUrl': portfolioUrl,
        'agreementVersion': agreementVersion,
        'skillTags': skillTags,
        'marketRegion': marketRegion,
      });
}
