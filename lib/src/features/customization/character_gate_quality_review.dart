const requiredCharacterQualityChecks = <String>{
  'media_integrity',
  'content_safety',
  'audio_sync',
  'transparent_background',
  'device_playback',
  'device_recovery',
};

enum CharacterQualityCheckResult { passed, failed, notTested }

class CharacterQualityReview {
  const CharacterQualityReview({
    this.results = const {},
    this.reviewerId,
    this.deviceModel,
    this.packageVersion,
    this.reviewedAt,
    this.failureNote,
  });

  final Map<String, CharacterQualityCheckResult> results;
  final String? reviewerId;
  final String? deviceModel;
  final String? packageVersion;
  final String? reviewedAt;
  final String? failureNote;

  Set<String> get missingChecks => requiredCharacterQualityChecks
      .where((check) => results[check] != CharacterQualityCheckResult.passed)
      .toSet();

  bool get hasFailure =>
      results.values.contains(CharacterQualityCheckResult.failed);

  bool get hasDeviceEvidence =>
      (deviceModel?.trim().isNotEmpty ?? false) &&
      (packageVersion?.trim().isNotEmpty ?? false);

  bool get canRelease =>
      missingChecks.isEmpty &&
      !hasFailure &&
      hasDeviceEvidence &&
      (reviewerId?.trim().isNotEmpty ?? false) &&
      DateTime.tryParse(reviewedAt ?? '') != null;

  Map<String, Object?> toJson() => {
        'results': results.map((key, value) => MapEntry(key, value.name)),
        'reviewerId': reviewerId,
        'deviceModel': deviceModel,
        'packageVersion': packageVersion,
        'reviewedAt': reviewedAt,
        'failureNote': failureNote,
      };

  static CharacterQualityReview fromJson(Object? value) {
    if (value is! Map) return const CharacterQualityReview();
    final rawResults = value['results'];
    final results = <String, CharacterQualityCheckResult>{};
    if (rawResults is Map) {
      for (final entry in rawResults.entries) {
        final key = entry.key;
        if (key is! String || !requiredCharacterQualityChecks.contains(key)) {
          continue;
        }
        results[key] = CharacterQualityCheckResult.values.firstWhere(
          (result) => result.name == entry.value,
          orElse: () => CharacterQualityCheckResult.notTested,
        );
      }
    }
    return CharacterQualityReview(
      results: results,
      reviewerId: _readText(value['reviewerId']),
      deviceModel: _readText(value['deviceModel']),
      packageVersion: _readText(value['packageVersion']),
      reviewedAt: _readText(value['reviewedAt']),
      failureNote: _readText(value['failureNote']),
    );
  }

  static String? _readText(Object? value) => value is String ? value : null;
}
