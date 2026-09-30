import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../device/p20_upload_name.dart';

/// Local labels only. Never used as proof that a device contains a video.
class UploadDisplayNames {
  static Future<void> _writes = Future<void>.value();
  static Future<File> _file() async {
    final root = await getApplicationSupportDirectory();
    await root.create(recursive: true);
    return File('${root.path}/upload_display_names.json');
  }

  static Future<Map<String, String>> _read() async {
    final file = await _file();
    if (!await file.exists()) return {};
    final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return data.map((key, value) => MapEntry(key, value as String));
  }

  static Future<Map<String, String>> load() async {
    await _writes;
    return _read();
  }

  static Future<String> reserve(String label) {
    final operation = _writes.then((_) async {
      final names = await _read();
      var base = createP20UploadBaseName();
      while (names.containsKey('$base.mp4')) {
        base = createP20UploadBaseName();
      }
      names['$base.mp4'] = label.trim();
      final file = await _file();
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(jsonEncode(names), flush: true);
      await temporary.rename(file.path);
      return base;
    });
    _writes =
        operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }
}
