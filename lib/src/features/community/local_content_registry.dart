import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Persists content downloaded into the app's private storage.
class LocalContentRegistry {
  const LocalContentRegistry();

  Future<File> _registryFile() async {
    final directory = await getApplicationSupportDirectory();
    final contentDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}hildors_content',
    );
    await contentDirectory.create(recursive: true);
    return File(
      '${contentDirectory.path}${Platform.pathSeparator}downloads.json',
    );
  }

  Future<Set<String>> load() async {
    try {
      final file = await _registryFile();
      if (!await file.exists()) return <String>{};
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return <String>{};
      return decoded.whereType<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<List<File>> importedFiles() async {
    final registry = await _registryFile();
    final directory = registry.parent;
    final entries = await directory
        .list()
        .where((entry) => entry is File)
        .cast<File>()
        .toList();
    entries.removeWhere((file) => file.path == registry.path);
    entries
        .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return entries;
  }

  Future<File> importFile(String sourcePath, String originalName) async {
    final registry = await _registryFile();
    final safeName = originalName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    var destination =
        File('${registry.parent.path}${Platform.pathSeparator}$safeName');
    if (await destination.exists()) {
      final dot = safeName.lastIndexOf('.');
      final base = dot > 0 ? safeName.substring(0, dot) : safeName;
      final extension = dot > 0 ? safeName.substring(dot) : '';
      destination = File(
          '${registry.parent.path}${Platform.pathSeparator}${base}_${DateTime.now().millisecondsSinceEpoch}$extension');
    }
    return File(sourcePath).copy(destination.path);
  }

  Future<void> add(String contentId) async {
    final ids = await load()
      ..add(contentId);
    final file = await _registryFile();
    await file.writeAsString(jsonEncode(ids.toList()..sort()), flush: true);
  }
}
