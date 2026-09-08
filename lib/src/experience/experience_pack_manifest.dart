import 'dart:convert';

import 'package:flutter/services.dart';

class ExperiencePackFile {
  const ExperiencePackFile({
    required this.role,
    required this.path,
    this.resultId,
  });

  factory ExperiencePackFile.fromJson(Map<String, Object?> json) {
    return ExperiencePackFile(
      role: json['role']! as String,
      path: json['path']! as String,
      resultId: json['resultId'] as String?,
    );
  }

  final String role;
  final String path;
  final String? resultId;
}

class ExperiencePackManifest {
  const ExperiencePackManifest({
    required this.schemaVersion,
    required this.id,
    required this.title,
    required this.version,
    required this.supportedModels,
    required this.minimumSizeMb,
    required this.maximumSizeMb,
    required this.files,
  });

  factory ExperiencePackManifest.fromJson(Map<String, Object?> json) {
    final size = json['estimatedSizeMb']! as Map<String, Object?>;
    return ExperiencePackManifest(
      schemaVersion: json['schemaVersion']! as int,
      id: json['id']! as String,
      title: json['title']! as String,
      version: json['version']! as String,
      supportedModels:
          (json['supportedModels']! as List<Object?>).cast<String>(),
      minimumSizeMb: size['min']! as int,
      maximumSizeMb: size['max']! as int,
      files: (json['files']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(ExperiencePackFile.fromJson)
          .toList(growable: false),
    );
  }

  final int schemaVersion;
  final String id;
  final String title;
  final String version;
  final List<String> supportedModels;
  final int minimumSizeMb;
  final int maximumSizeMb;
  final List<ExperiencePackFile> files;

  List<String> missingFiles(Iterable<String> deviceFiles) {
    final available =
        deviceFiles.map((name) => name.trim().toLowerCase()).toSet();
    return files
        .map((file) => file.path)
        .where((path) => !available.contains(path.toLowerCase()))
        .toList(growable: false);
  }
}

class ExperiencePackRepository {
  static const tarotMajorManifestAsset =
      'assets/packs/tarot_major_v1/manifest.json';
  static const chaosPartyManifestAsset =
      'assets/packs/chaos_party_v1/manifest.json';

  Future<ExperiencePackManifest> loadTarotMajor() async {
    return load(tarotMajorManifestAsset);
  }

  Future<ExperiencePackManifest> loadChaosParty() async {
    return load(chaosPartyManifestAsset);
  }

  Future<ExperiencePackManifest> load(String assetPath) async {
    final source = await rootBundle.loadString(assetPath);
    final json = jsonDecode(source) as Map<String, Object?>;
    return ExperiencePackManifest.fromJson(json);
  }
}
