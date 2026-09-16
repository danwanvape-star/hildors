import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class CreatorProfile {
  const CreatorProfile({
    required this.displayName,
    required this.portfolioUrl,
    required this.status,
    required this.agreementVersion,
    required this.submittedAt,
    this.skillTags = const [],
    this.marketRegion = 'other',
    this.settlementCurrency,
    this.marketRegionVerifiedAt,
    this.payoutAccountStatus = '待提交',
    this.payoutAccountReference,
    this.taxFormType,
    this.payoutSubmittedAt,
    this.payoutVerifiedAt,
    this.reviewedAt,
  });

  final String displayName;
  final String portfolioUrl;
  final String status;
  final String agreementVersion;
  final String submittedAt;
  final List<String> skillTags;
  final String marketRegion;
  final String? settlementCurrency;
  final String? marketRegionVerifiedAt;
  final String payoutAccountStatus;
  final String? payoutAccountReference;
  final String? taxFormType;
  final String? payoutSubmittedAt;
  final String? payoutVerifiedAt;
  final String? reviewedAt;

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'portfolioUrl': portfolioUrl,
        'status': status,
        'agreementVersion': agreementVersion,
        'submittedAt': submittedAt,
        'skillTags': skillTags,
        'marketRegion': marketRegion,
        'settlementCurrency': settlementCurrency,
        'marketRegionVerifiedAt': marketRegionVerifiedAt,
        'payoutAccountStatus': payoutAccountStatus,
        'payoutAccountReference': payoutAccountReference,
        'taxFormType': taxFormType,
        'payoutSubmittedAt': payoutSubmittedAt,
        'payoutVerifiedAt': payoutVerifiedAt,
        'reviewedAt': reviewedAt,
      };

  static CreatorProfile? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final displayName = value['displayName'];
    final portfolioUrl = value['portfolioUrl'];
    final status = value['status'];
    final agreementVersion = value['agreementVersion'];
    final submittedAt = value['submittedAt'];
    if (displayName is! String ||
        portfolioUrl is! String ||
        status is! String ||
        agreementVersion is! String ||
        submittedAt is! String) {
      return null;
    }
    return CreatorProfile(
      displayName: displayName,
      portfolioUrl: portfolioUrl,
      status: status,
      agreementVersion: agreementVersion,
      submittedAt: submittedAt,
      skillTags: (value['skillTags'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      marketRegion: value['marketRegion'] as String? ?? 'other',
      settlementCurrency: value['settlementCurrency'] as String?,
      marketRegionVerifiedAt: value['marketRegionVerifiedAt'] as String?,
      payoutAccountStatus: value['payoutAccountStatus'] as String? ?? '待提交',
      payoutAccountReference: value['payoutAccountReference'] as String?,
      taxFormType: value['taxFormType'] as String?,
      payoutSubmittedAt: value['payoutSubmittedAt'] as String?,
      payoutVerifiedAt: value['payoutVerifiedAt'] as String?,
      reviewedAt: value['reviewedAt'] as String?,
    );
  }
}

abstract interface class CreatorProfileRepository {
  Future<CreatorProfile?> loadProfile();

  Future<void> submitApplication({
    required String displayName,
    required String portfolioUrl,
    required String agreementVersion,
    required List<String> skillTags,
    required String marketRegion,
  });

  Future<void> approveApplication();

  Future<void> submitPayoutAccount({
    required String payoutAccountReference,
    required String taxFormType,
  });

  Future<void> approvePayoutAccount();
}

class LocalCreatorProfileRepository implements CreatorProfileRepository {
  const LocalCreatorProfileRepository();

  Future<File> _file() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final directory = Directory(
      '${supportDirectory.path}${Platform.pathSeparator}character_gate',
    );
    await directory.create(recursive: true);
    return File(
        '${directory.path}${Platform.pathSeparator}creator_profile.json');
  }

  @override
  Future<CreatorProfile?> loadProfile() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      return CreatorProfile.fromJson(jsonDecode(await file.readAsString()));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> submitApplication({
    required String displayName,
    required String portfolioUrl,
    required String agreementVersion,
    required List<String> skillTags,
    required String marketRegion,
  }) async {
    final file = await _file();
    final profile = CreatorProfile(
      displayName: displayName,
      portfolioUrl: portfolioUrl,
      status: '审核中',
      agreementVersion: agreementVersion,
      submittedAt: DateTime.now().toUtc().toIso8601String(),
      skillTags: List.of(skillTags),
      marketRegion: marketRegion,
    );
    await file.writeAsString(jsonEncode(profile.toJson()), flush: true);
  }

  @override
  Future<void> approveApplication() async {
    final profile = await loadProfile();
    if (profile == null || profile.status != '审核中') return;
    final reviewedAt = DateTime.now().toUtc().toIso8601String();
    final approved = CreatorProfile(
      displayName: profile.displayName,
      portfolioUrl: profile.portfolioUrl,
      status: '已认证',
      agreementVersion: profile.agreementVersion,
      submittedAt: profile.submittedAt,
      skillTags: profile.skillTags,
      marketRegion: profile.marketRegion,
      settlementCurrency: profile.marketRegion == 'cn_mainland' ? 'CNY' : 'USD',
      marketRegionVerifiedAt: reviewedAt,
      payoutAccountStatus: profile.payoutAccountStatus,
      payoutAccountReference: profile.payoutAccountReference,
      taxFormType: profile.taxFormType,
      payoutSubmittedAt: profile.payoutSubmittedAt,
      payoutVerifiedAt: profile.payoutVerifiedAt,
      reviewedAt: reviewedAt,
    );
    final file = await _file();
    await file.writeAsString(jsonEncode(approved.toJson()), flush: true);
  }

  @override
  Future<void> submitPayoutAccount({
    required String payoutAccountReference,
    required String taxFormType,
  }) async {
    final profile = await loadProfile();
    final reference = payoutAccountReference.trim();
    if (profile == null ||
        profile.status != '已认证' ||
        reference.isEmpty ||
        taxFormType.trim().isEmpty) {
      return;
    }
    final updated = _copyCreatorProfile(
      profile,
      payoutAccountStatus: '审核中',
      payoutAccountReference: reference,
      taxFormType: taxFormType.trim(),
      payoutSubmittedAt: DateTime.now().toUtc().toIso8601String(),
    );
    final file = await _file();
    await file.writeAsString(jsonEncode(updated.toJson()), flush: true);
  }

  @override
  Future<void> approvePayoutAccount() async {
    final profile = await loadProfile();
    if (profile == null || profile.payoutAccountStatus != '审核中') return;
    final updated = _copyCreatorProfile(
      profile,
      payoutAccountStatus: '已核验',
      payoutVerifiedAt: DateTime.now().toUtc().toIso8601String(),
    );
    final file = await _file();
    await file.writeAsString(jsonEncode(updated.toJson()), flush: true);
  }
}

class MemoryCreatorProfileRepository implements CreatorProfileRepository {
  MemoryCreatorProfileRepository([this.profile]);

  CreatorProfile? profile;

  @override
  Future<CreatorProfile?> loadProfile() async => profile;

  @override
  Future<void> submitApplication({
    required String displayName,
    required String portfolioUrl,
    required String agreementVersion,
    required List<String> skillTags,
    required String marketRegion,
  }) async {
    profile = CreatorProfile(
      displayName: displayName,
      portfolioUrl: portfolioUrl,
      status: '审核中',
      agreementVersion: agreementVersion,
      submittedAt: DateTime.now().toUtc().toIso8601String(),
      skillTags: List.of(skillTags),
      marketRegion: marketRegion,
    );
  }

  @override
  Future<void> approveApplication() async {
    final current = profile;
    if (current == null || current.status != '审核中') return;
    final reviewedAt = DateTime.now().toUtc().toIso8601String();
    profile = CreatorProfile(
      displayName: current.displayName,
      portfolioUrl: current.portfolioUrl,
      status: '已认证',
      agreementVersion: current.agreementVersion,
      submittedAt: current.submittedAt,
      skillTags: current.skillTags,
      marketRegion: current.marketRegion,
      settlementCurrency: current.marketRegion == 'cn_mainland' ? 'CNY' : 'USD',
      marketRegionVerifiedAt: reviewedAt,
      payoutAccountStatus: current.payoutAccountStatus,
      payoutAccountReference: current.payoutAccountReference,
      taxFormType: current.taxFormType,
      payoutSubmittedAt: current.payoutSubmittedAt,
      payoutVerifiedAt: current.payoutVerifiedAt,
      reviewedAt: reviewedAt,
    );
  }

  @override
  Future<void> submitPayoutAccount({
    required String payoutAccountReference,
    required String taxFormType,
  }) async {
    final current = profile;
    final reference = payoutAccountReference.trim();
    if (current == null ||
        current.status != '已认证' ||
        reference.isEmpty ||
        taxFormType.trim().isEmpty) {
      return;
    }
    profile = _copyCreatorProfile(
      current,
      payoutAccountStatus: '审核中',
      payoutAccountReference: reference,
      taxFormType: taxFormType.trim(),
      payoutSubmittedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> approvePayoutAccount() async {
    final current = profile;
    if (current == null || current.payoutAccountStatus != '审核中') return;
    profile = _copyCreatorProfile(
      current,
      payoutAccountStatus: '已核验',
      payoutVerifiedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }
}

CreatorProfile creatorProfileWithCloudReview(
  CreatorProfile profile, {
  required String status,
  String? reviewedAt,
}) {
  const labels = {
    'pending': '审核中',
    'approved': '已认证',
    'rejected': '未通过',
    'suspended': '已停用',
  };
  return CreatorProfile(
    displayName: profile.displayName,
    portfolioUrl: profile.portfolioUrl,
    status: labels[status] ?? profile.status,
    agreementVersion: profile.agreementVersion,
    submittedAt: profile.submittedAt,
    skillTags: profile.skillTags,
    marketRegion: profile.marketRegion,
    settlementCurrency: status == 'approved'
        ? (profile.marketRegion == 'cn_mainland' ? 'CNY' : 'USD')
        : profile.settlementCurrency,
    marketRegionVerifiedAt: status == 'approved'
        ? (reviewedAt ?? profile.marketRegionVerifiedAt)
        : profile.marketRegionVerifiedAt,
    payoutAccountStatus: profile.payoutAccountStatus,
    payoutAccountReference: profile.payoutAccountReference,
    taxFormType: profile.taxFormType,
    payoutSubmittedAt: profile.payoutSubmittedAt,
    payoutVerifiedAt: profile.payoutVerifiedAt,
    reviewedAt: reviewedAt ?? profile.reviewedAt,
  );
}

CreatorProfile _copyCreatorProfile(
  CreatorProfile profile, {
  required String payoutAccountStatus,
  String? payoutAccountReference,
  String? taxFormType,
  String? payoutSubmittedAt,
  String? payoutVerifiedAt,
}) =>
    CreatorProfile(
      displayName: profile.displayName,
      portfolioUrl: profile.portfolioUrl,
      status: profile.status,
      agreementVersion: profile.agreementVersion,
      submittedAt: profile.submittedAt,
      skillTags: profile.skillTags,
      marketRegion: profile.marketRegion,
      settlementCurrency: profile.settlementCurrency,
      marketRegionVerifiedAt: profile.marketRegionVerifiedAt,
      payoutAccountStatus: payoutAccountStatus,
      payoutAccountReference:
          payoutAccountReference ?? profile.payoutAccountReference,
      taxFormType: taxFormType ?? profile.taxFormType,
      payoutSubmittedAt: payoutSubmittedAt ?? profile.payoutSubmittedAt,
      payoutVerifiedAt: payoutVerifiedAt ?? profile.payoutVerifiedAt,
      reviewedAt: profile.reviewedAt,
    );
