import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// The caller must provide an app-private, per-account root directory.
/// A cache record is not an entitlement and never grants device playback rights.
class VerifiedVideoCache {
  const VerifiedVideoCache(this.directory, this.origin);
  final Directory directory;
  final String origin;

  Future<File?> find(String packageId, String clipId) async {
    if (!await directory.exists()) return null;
    await for (final entry in directory.list(followLinks: false)) {
      if (entry is! Directory ||
          !entry.uri.pathSegments
              .where((s) => s.isNotEmpty)
              .last
              .startsWith('download-')) {
        continue;
      }
      final record = File('${entry.path}/record.json');
      final video = File('${entry.path}/video.mp4');
      try {
        if (await FileSystemEntity.type(record.path, followLinks: false) !=
                FileSystemEntityType.file ||
            await FileSystemEntity.type(video.path, followLinks: false) !=
                FileSystemEntityType.file ||
            await record.length() > 16384) {
          continue;
        }
        final data = jsonDecode(await record.readAsString());
        if (data is! Map<String, dynamic> ||
            data['schema'] != 1 ||
            data['origin'] != origin ||
            data['packageId'] != packageId ||
            data['clipId'] != clipId ||
            data['bytes'] is! int ||
            data['bytes'] <= 0 ||
            data['bytes'] > 256 * 1024 * 1024 ||
            data['sha256'] is! String ||
            !RegExp(r'^[a-f0-9]{64}$').hasMatch(data['sha256'] as String)) {
          continue;
        }
        if (await video.length() != data['bytes']) continue;
        if ((await sha256.bind(video.openRead()).first).toString() ==
            data['sha256']) {
          return video;
        }
      } on FormatException {
        // An incomplete/corrupt record is not a completed download.
      } on FileSystemException {
        // A concurrently removed file must not break the rest of the cache.
      }
    }
    return null;
  }
}
