import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'device_playlist_draft.dart';

typedef PendingVideo = ({String title, String source, bool asset});

/// Only stores references. It never copies media or marks a file as uploaded.
class PendingPlaylistStore {
  static Future<void> _writes = Future<void>.value();

  static Future<File> _file(DevicePlaylistKind kind) async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return File('${directory.path}/pending_playlist_${kind.name}.json');
  }

  static Future<Map<String, PendingVideo>> load(DevicePlaylistKind kind) async {
    await _writes;
    return _read(kind);
  }

  static Future<Map<String, PendingVideo>> _read(
      DevicePlaylistKind kind) async {
    final file = await _file(kind);
    if (!await file.exists()) return {};
    final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    if (data['version'] != 1) {
      throw const FormatException('Unsupported pending playlist');
    }
    final entries = data['entries'] as Map<String, dynamic>;
    return entries.map((key, raw) {
      final value = raw as Map<String, dynamic>;
      return MapEntry(key, (
        title: value['title'] as String,
        source: value['source'] as String,
        asset: value['asset'] as bool
      ));
    });
  }

  static Future<void> merge(
      DevicePlaylistKind kind, Map<String, PendingVideo> additions) {
    final snapshot = Map<String, PendingVideo>.of(additions);
    final operation = _writes.then((_) async {
      final current = await _read(kind);
      current.addAll(snapshot);
      final file = await _file(kind);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
          jsonEncode({
            'version': 1,
            'entries': current.map((key, value) => MapEntry(key, {
                  'title': value.title,
                  'source': value.source,
                  'asset': value.asset
                }))
          }),
          flush: true);
      await temporary.rename(file.path);
    });
    _writes =
        operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }

  static Future<void> save(
      DevicePlaylistKind kind, Map<String, PendingVideo> entries) {
    // Snapshot before awaiting; serialize writes so rapid remove/add cannot
    // restore older state after the latest change.
    final encoded = jsonEncode({
      'version': 1,
      'entries': entries.map((key, value) => MapEntry(key,
          {'title': value.title, 'source': value.source, 'asset': value.asset}))
    });
    final operation = _writes.then((_) async {
      final file = await _file(kind);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(encoded, flush: true);
      await temporary.rename(file.path);
    });
    _writes =
        operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }
}
