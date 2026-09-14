import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract interface class CharacterEntitlementRepository {
  Future<Set<String>> loadClaimedCharacterIds();

  Future<Set<String>> loadDeviceCharacterIds();

  Future<void> claim(String characterId);

  Future<void> revoke(String characterId);

  Future<void> sendToDevice(String characterId);
}

class LocalCharacterEntitlementRepository
    implements CharacterEntitlementRepository {
  const LocalCharacterEntitlementRepository();

  Future<File> _file() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final directory = Directory(
      '${supportDirectory.path}${Platform.pathSeparator}character_gate',
    );
    await directory.create(recursive: true);
    return File(
      '${directory.path}${Platform.pathSeparator}claimed_characters.json',
    );
  }

  Future<({Set<String> claimed, Set<String> onDevice})> _loadData() async {
    try {
      final file = await _file();
      if (!await file.exists()) {
        return (claimed: <String>{}, onDevice: <String>{});
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is List) {
        return (
          claimed: decoded.whereType<String>().toSet(),
          onDevice: <String>{},
        );
      }
      if (decoded is Map<String, dynamic>) {
        return (
          claimed: (decoded['claimed'] as List? ?? const [])
              .whereType<String>()
              .toSet(),
          onDevice: (decoded['onDevice'] as List? ?? const [])
              .whereType<String>()
              .toSet(),
        );
      }
    } catch (_) {
      // A damaged local cache is treated as empty until cloud sync is added.
    }
    return (claimed: <String>{}, onDevice: <String>{});
  }

  Future<void> _save(Set<String> claimed, Set<String> onDevice) async {
    final file = await _file();
    await file.writeAsString(
      jsonEncode({
        'claimed': claimed.toList()..sort(),
        'onDevice': onDevice.toList()..sort(),
      }),
      flush: true,
    );
  }

  @override
  Future<Set<String>> loadClaimedCharacterIds() async =>
      (await _loadData()).claimed;

  @override
  Future<Set<String>> loadDeviceCharacterIds() async =>
      (await _loadData()).onDevice;

  @override
  Future<void> claim(String characterId) async {
    final data = await _loadData();
    await _save(data.claimed..add(characterId), data.onDevice);
  }

  @override
  Future<void> revoke(String characterId) async {
    final data = await _loadData();
    await _save(
      data.claimed..remove(characterId),
      data.onDevice..remove(characterId),
    );
  }

  @override
  Future<void> sendToDevice(String characterId) async {
    final data = await _loadData();
    if (!data.claimed.contains(characterId)) return;
    await _save(data.claimed, data.onDevice..add(characterId));
  }
}

class MemoryCharacterEntitlementRepository
    implements CharacterEntitlementRepository {
  MemoryCharacterEntitlementRepository([Iterable<String> initialIds = const []])
      : _ids = initialIds.toSet();

  final Set<String> _ids;
  final Set<String> _deviceIds = {};

  @override
  Future<Set<String>> loadClaimedCharacterIds() async => Set.of(_ids);

  @override
  Future<Set<String>> loadDeviceCharacterIds() async => Set.of(_deviceIds);

  @override
  Future<void> claim(String characterId) async {
    _ids.add(characterId);
  }

  @override
  Future<void> revoke(String characterId) async {
    _ids.remove(characterId);
    _deviceIds.remove(characterId);
  }

  @override
  Future<void> sendToDevice(String characterId) async {
    if (_ids.contains(characterId)) _deviceIds.add(characterId);
  }
}
