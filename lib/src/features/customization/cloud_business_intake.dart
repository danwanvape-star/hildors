import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class CloudBusinessResponse {
  const CloudBusinessResponse(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;
}

class CloudSessionRecoveryRequired extends HttpException {
  const CloudSessionRecoveryRequired(super.message);
}

class CloudBusinessIntake {
  CloudBusinessIntake({String? baseUrl, File? sessionFile})
      : _configuredBaseUrl = baseUrl ?? _baseUrl,
        _sessionFile = sessionFile;

  static final CloudBusinessIntake instance = CloudBusinessIntake();
  static const _baseUrl = String.fromEnvironment('HILDORS_API_BASE_URL');
  static const _tokenFileName = 'cloud_business_session.json';
  final String _configuredBaseUrl;
  final File? _sessionFile;
  Future<String>? _sessionFlight;

  bool get isConfigured => _baseUri != null;

  Uri? get _baseUri {
    if (_configuredBaseUrl.isEmpty) return null;
    final uri = Uri.tryParse(_configuredBaseUrl);
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
    if (_sessionFile != null) return _sessionFile;
    final root = await getApplicationSupportDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}character_gate',
    );
    await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}$_tokenFileName');
  }

  bool _validToken(dynamic token) =>
      token is String && RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token);

  Future<Map<String, dynamic>?> _storedSession() async {
    try {
      final file = await _tokenFile();
      if (!await file.exists()) {
        if (await File('${file.path}.pending').exists()) {
          throw const CloudSessionRecoveryRequired('会话保存未完成，请联系平台恢复账户');
        }
        return null;
      }
      final value = jsonDecode(await file.readAsString());
      if (value is! Map<String, dynamic> ||
          !_validToken(value['token']) ||
          (value['refreshToken'] != null &&
              !_validToken(value['refreshToken']))) {
        throw const CloudSessionRecoveryRequired('云端会话凭据损坏，请联系平台恢复账户');
      }
      return value;
    } catch (_) {
      throw const CloudSessionRecoveryRequired('无法读取原账户会话，请联系平台恢复账户');
    }
  }

  Future<void> _saveSession(Map<String, dynamic> value) async {
    final file = await _tokenFile();
    final pending = File('${file.path}.pending');
    await pending.writeAsString(jsonEncode(value), flush: true);
    await pending.rename(file.path);
  }

  Future<String> _session(HttpClient client, Uri baseUri,
      {String? rejectedToken}) async {
    final flight = _sessionFlight;
    if (flight != null) return flight;
    final next = _resolveSession(client, baseUri, rejectedToken: rejectedToken);
    _sessionFlight = next;
    try {
      return await next;
    } finally {
      if (identical(_sessionFlight, next)) _sessionFlight = null;
    }
  }

  Future<String> _resolveSession(HttpClient client, Uri baseUri,
      {String? rejectedToken}) async {
    final existing = await _storedSession();
    final token = existing?['token'] as String?;
    final refresh = existing?['refreshToken'] as String?;
    final expiry = existing?['expiresAt'];
    if (token != null &&
        refresh != null &&
        rejectedToken != token &&
        expiry is num &&
        expiry > DateTime.now().millisecondsSinceEpoch + 60000) {
      return token;
    }
    final path = existing == null
        ? '/v1/device-session'
        : refresh != null
            ? '/v1/session-refresh'
            : '/v1/me/session/renew';
    final request = await client.postUrl(baseUri.resolve(path));
    request.followRedirects = false;
    if (refresh != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'refreshToken': refresh}));
    } else if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    final response = await request.close();
    final value = await _readJson(response);
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const CloudSessionRecoveryRequired('原账户会话已失效，无法自动续期，请联系平台恢复账户');
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        !_validToken(value['token']) ||
        !_validToken(value['refreshToken']) ||
        value['expiresIn'] is! num ||
        (value['expiresIn'] as num) <= 0) {
      throw const HttpException('云端会话续期失败，请稍后重试');
    }
    await _saveSession({
      ...value,
      'expiresAt': DateTime.now().millisecondsSinceEpoch +
          ((value['expiresIn'] as num) * 1000).toInt()
    });
    return value['token'] as String;
  }

  Future<Map<String, dynamic>> _readJson(HttpClientResponse response,
      {int maxBytes = 128 * 1024}) async {
    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > maxBytes) {
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
    if (baseUri == null) return false;
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
          await _session(client, baseUri, rejectedToken: token);
        }
        return false;
      })()
          .timeout(const Duration(seconds: 15));
    } on CloudSessionRecoveryRequired {
      rethrow;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>?> loadCreatorProfile() async {
    final baseUri = _baseUri;
    if (baseUri == null) return null;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      return await (() async {
        for (var attempt = 0; attempt < 2; attempt++) {
          final token = await _session(client, baseUri);
          final request = await client.getUrl(
            baseUri.resolve('/v1/me/creator-profile'),
          );
          request.followRedirects = false;
          request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
          final response = await request.close();
          final value = await _readJson(response);
          if (response.statusCode == HttpStatus.ok) return value;
          if (response.statusCode == HttpStatus.notFound) return null;
          if (response.statusCode != HttpStatus.unauthorized || attempt > 0) {
            return null;
          }
          await _session(client, baseUri, rejectedToken: token);
        }
        return null;
      })()
          .timeout(const Duration(seconds: 15));
    } on CloudSessionRecoveryRequired {
      rethrow;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<Uint8List> _orderBytes(String method, String path,
      {Map<String, dynamic>? document,
      Uint8List? bytes,
      String? contentType}) async {
    final baseUri = _baseUri;
    if (baseUri == null) throw const HttpException('尚未配置云端服务');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      return await (() async {
        for (var attempt = 0; attempt < 2; attempt++) {
          final token = await _session(client, baseUri);
          final request = await client.openUrl(method, baseUri.resolve(path));
          request.followRedirects = false;
          request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
          if (bytes != null) {
            request.headers.contentType = ContentType.parse(contentType!);
            request.add(bytes);
          } else if (document != null) {
            request.headers.contentType = ContentType.json;
            request.write(jsonEncode(document));
          }
          final response = await request.close();
          final result = BytesBuilder();
          await for (final chunk in response) {
            if (result.length + chunk.length > 9 * 1024 * 1024) {
              throw const FormatException('响应过大');
            }
            result.add(chunk);
          }
          if (response.statusCode == 401 && attempt == 0) {
            await _session(client, baseUri, rejectedToken: token);
            continue;
          }
          if (response.statusCode < 200 || response.statusCode >= 300) {
            throw HttpException(switch (response.statusCode) {
              401 => '云端会话已失效，请联系平台恢复账户',
              403 => '暂无权限，请确认创作者认证和接单资格',
              409 => '订单已更新，请刷新后重试',
              413 => '素材超过大小限制',
              _ => '请求失败（${response.statusCode}），请检查填写内容后重试',
            });
          }
          return result.takeBytes();
        }
        throw const HttpException('原账户会话已失效，请联系平台恢复账户');
      })()
          .timeout(const Duration(seconds: 60));
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> orderRequest(String method, String path,
      {Map<String, dynamic>? document,
      Uint8List? bytes,
      String? contentType}) async {
    final raw = await _orderBytes(method, path,
        document: document, bytes: bytes, contentType: contentType);
    final value = jsonDecode(utf8.decode(raw));
    if (value is! Map<String, dynamic>) throw const FormatException('订单响应无效');
    return value;
  }

  Future<Uint8List> orderMaterial(String path) => _orderBytes('GET', path);

  Future<CloudBusinessResponse> contentRequest(
    String method,
    String path, {
    Map<String, dynamic>? document,
    String? filePath,
    String? contentType,
    int? ifMatch,
  }) async {
    final baseUri = _baseUri;
    if (baseUri == null) throw const HttpException('尚未配置云端服务');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      return await (() async {
        for (var attempt = 0; attempt < 2; attempt++) {
          final token = await _session(client, baseUri);
          final request = await client.openUrl(method, baseUri.resolve(path));
          request.followRedirects = false;
          request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
          if (ifMatch != null) {
            request.headers.set(HttpHeaders.ifMatchHeader, ifMatch);
          }
          if (filePath != null) {
            final file = File(filePath);
            request.headers.contentType = ContentType.parse(contentType!);
            request.contentLength = await file.length();
            await request.addStream(file.openRead());
          } else if (document != null) {
            request.headers.contentType = ContentType.json;
            request.write(jsonEncode(document));
          }
          final response = await request.close();
          final value = await _readJson(response, maxBytes: 4 * 1024 * 1024);
          if (response.statusCode == 401 && attempt == 0) {
            await _session(client, baseUri, rejectedToken: token);
            continue;
          }
          return CloudBusinessResponse(response.statusCode, value);
        }
        throw const HttpException('原账户会话已失效，请联系平台恢复账户');
      })()
          .timeout(const Duration(minutes: 10));
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
    required String email,
    required String portfolioUrl,
    required String agreementVersion,
    required List<String> skillTags,
    required String marketRegion,
  }) =>
      _post('/v1/me/creator-profile', {
        'displayName': displayName,
        'email': email.trim().toLowerCase(),
        'portfolioUrl': portfolioUrl,
        'agreementVersion': agreementVersion,
        'skillTags': skillTags,
        'marketRegion': marketRegion,
      });
}
