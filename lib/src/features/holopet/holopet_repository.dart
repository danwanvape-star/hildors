import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'holopet_state.dart';

class HoloPetSnapshot {
  const HoloPetSnapshot({required this.pet, required this.updatedAt});

  final HoloPetState pet;
  final DateTime updatedAt;

  factory HoloPetSnapshot.fromJson(Map<String, dynamic> json) =>
      HoloPetSnapshot(
        pet: HoloPetState.fromJson(
            Map<String, dynamic>.from(json['pet'] as Map? ?? const {})),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'pet': pet.toJson(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

abstract interface class HoloPetStore {
  Future<HoloPetSnapshot?> load(String profileId);
  Future<void> save(String profileId, HoloPetSnapshot snapshot);
}

class FileHoloPetStore implements HoloPetStore {
  Future<File> _file(String profileId) async {
    final directory = await getApplicationSupportDirectory();
    final safeId = profileId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return File(
        '${directory.path}${Platform.pathSeparator}holopet_$safeId.json');
  }

  @override
  Future<HoloPetSnapshot?> load(String profileId) async {
    try {
      final file = await _file(profileId);
      if (!await file.exists()) return null;
      final value = jsonDecode(await file.readAsString());
      if (value is! Map) return null;
      return HoloPetSnapshot.fromJson(Map<String, dynamic>.from(value));
    } on Object {
      return null;
    }
  }

  @override
  Future<void> save(String profileId, HoloPetSnapshot snapshot) async {
    final file = await _file(profileId);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(snapshot.toJson()), flush: true);
  }
}
