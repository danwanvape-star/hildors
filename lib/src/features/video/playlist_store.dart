import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'device_playlist_draft.dart';

class PlaylistStore {
  static Future<File> _file(DevicePlaylistKind kind) async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return File('${directory.path}/playlist_${kind.name}.json');
  }

  static Future<DevicePlaylistDraft> load(DevicePlaylistDraft fallback) async {
    final file = await _file(fallback.kind);
    if (!await file.exists()) return fallback;
    final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return fallback.copyWith(
      videoNames: (data['names'] as List).cast<String>(),
      loopMode: PlaylistLoopMode.values.byName(data['loop'] as String),
    );
  }

  static Future<void> save(DevicePlaylistDraft draft) async {
    final file = await _file(draft.kind);
    await file.writeAsString(
        jsonEncode({
          'names': draft.videoNames,
          'loop': draft.loopMode.name,
        }),
        flush: true);
  }

  static Future<void> add(DevicePlaylistKind kind, String name) async {
    final current = await load(DevicePlaylistDraft(
      kind: kind,
      enabled: true,
      loopMode: PlaylistLoopMode.listLoop,
      videoNames: kind == DevicePlaylistKind.startup
          ? ['showcase_01.mp4', 'showcase_02.mp4']
          : ['showcase_03.mp4', 'showcase_04.mp4'],
    ));
    await save(current.add(name));
  }
}
