import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Session metadata deliberately expires across restarts. A cached public
/// derivative still requires online authorization before every new playback.
class PreviewVideoCache {
  PreviewVideoCache({
    required this.origin,
    required this.directory,
    this.maxBytes = 64 * 1024 * 1024,
    this.maxEntryBytes = 12 * 1024 * 1024,
    this.maxAge = const Duration(hours: 24),
  });

  static final shared = PreviewVideoCache(
    origin:
        Uri.tryParse(const String.fromEnvironment('HILDORS_API_BASE_URL')) ??
            Uri(),
    directory: _sessionDirectory,
  );
  static Future<Directory>? _directory;
  static Future<Directory> _sessionDirectory() => _directory ??= () async {
        final temporary = await getTemporaryDirectory();
        final result = Directory('${temporary.path}/hildors_public_previews');
        if (await result.exists()) await result.delete(recursive: true);
        return result.create(recursive: true);
      }();

  final Uri origin;
  final Future<Directory> Function() directory;
  final int maxBytes;
  final int maxEntryBytes;
  final Duration maxAge;
  final _entries = <Uri, _Entry>{};
  Future<void>? _transfer;
  int _sequence = 0;

  bool _allowed(Uri uri) =>
      (origin.scheme == 'https' || origin.scheme == 'http') &&
      uri.scheme == origin.scheme &&
      uri.host == origin.host &&
      uri.port == origin.port &&
      uri.userInfo.isEmpty &&
      uri.fragment.isEmpty &&
      uri.query == 'v=1' &&
      RegExp(r'^/v1/media/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/preview$')
          .hasMatch(uri.path);

  Future<void> discard(Uri uri) => _remove(uri);

  Future<void> _remove(Uri uri) async {
    final entry = _entries.remove(uri);
    try {
      if (entry != null && await entry.file.exists()) await entry.file.delete();
    } on FileSystemException {
      // Temporary storage can be purged externally at any time.
    }
  }

  /// A miss does no network work; the native player can start streaming at once.
  Future<File?> validatedFile(Uri uri, {Future<void>? cancel}) async {
    if (!_allowed(uri)) return null;
    final entry = _entries[uri];
    if (entry == null) return null;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    var cancelled = false;
    cancel?.then((_) {
      cancelled = true;
      client.close(force: true);
    });
    try {
      if (DateTime.now().difference(entry.created) >= maxAge ||
          !await entry.file.exists() ||
          await entry.file.length() != entry.size) {
        await _remove(uri);
        return null;
      }
      final request =
          await client.getUrl(uri).timeout(const Duration(seconds: 2));
      request.followRedirects = false;
      request.headers.set(HttpHeaders.ifNoneMatchHeader, entry.etag);
      final response =
          await request.close().timeout(const Duration(seconds: 2));
      if (!cancelled &&
          response.statusCode == HttpStatus.notModified &&
          identical(_entries[uri], entry)) {
        _entries.remove(uri);
        _entries[uri] = entry;
        return entry.file;
      }
      await _remove(uri);
    } catch (_) {
      // Offline/error is never permission to replay a revoked preview.
      await _remove(uri);
    } finally {
      client.close(force: true);
    }
    return null;
  }

  /// Called after playback has completed its first pass. Only one speculative
  /// transfer runs globally; other previews keep using native streaming.
  Future<void> warm(Uri uri, {Future<void>? cancel}) {
    if (!_allowed(uri) || _entries.containsKey(uri)) return Future.value();
    if (_transfer != null) return _transfer!;
    final transfer = _download(uri, cancel);
    _transfer = transfer;
    return transfer.whenComplete(() {
      _transfer = null;
    });
  }

  Future<void> _download(Uri uri, Future<void>? cancel) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    var cancelled = false;
    File? file;
    RandomAccessFile? sink;
    cancel?.then((_) {
      cancelled = true;
      client.close(force: true);
    });
    final deadline = Timer(const Duration(seconds: 45), () {
      cancelled = true;
      client.close(force: true);
    });
    try {
      final request = await client.getUrl(uri);
      request.followRedirects = false;
      final response = await request.close();
      final etag = response.headers.value(HttpHeaders.etagHeader);
      final limit = maxEntryBytes < maxBytes ? maxEntryBytes : maxBytes;
      if (cancelled ||
          response.statusCode != 200 ||
          etag == null ||
          response.contentLength > limit) {
        return;
      }
      final folder = await directory();
      if (cancelled) return;
      file = File('${folder.path}/preview_${_sequence++}.mp4');
      sink = await file.open(mode: FileMode.write);
      var size = 0;
      await for (final chunk in response) {
        size += chunk.length;
        if (cancelled || size > limit) return;
        await sink.writeFrom(chunk);
      }
      await sink.flush();
      await sink.close();
      sink = null;
      if (cancelled ||
          size == 0 ||
          (response.contentLength >= 0 && size != response.contentLength)) {
        return;
      }
      for (final key in _entries.keys.toList()) {
        if (DateTime.now().difference(_entries[key]!.created) > maxAge) {
          await _remove(key);
        }
      }
      while (_entries.isNotEmpty &&
          _entries.values.fold<int>(0, (sum, entry) => sum + entry.size) +
                  size >
              maxBytes) {
        await _remove(_entries.keys.first);
      }
      if (cancelled) return;
      _entries[uri] = _Entry(file, etag, size, DateTime.now());
      file = null;
    } catch (_) {
      // Caching is optional. Playback and a later retry remain available.
    } finally {
      deadline.cancel();
      client.close(force: true);
      try {
        await sink?.close();
        if (file != null && await file.exists()) await file.delete();
      } on FileSystemException {
        // Cache cleanup must never turn into a playback error.
      }
    }
  }
}

class _Entry {
  _Entry(this.file, this.etag, this.size, this.created);
  final File file;
  final String etag;
  final int size;
  final DateTime created;
}
