import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'character_gate_quality_review.dart';

enum DisputeResolution { resumeOrder, refundApproved }

enum EscalatedExtensionResolution {
  userAccepted,
  userDeclined,
  proposalWithdrawn,
}

enum CreatorCommunicationRiskResolution { contactRestored, performanceReview }

enum CreatorPerformanceReviewOutcome { retainCreator, openOrderDispute }

String creatorSettlementCurrencyForRegion(String region) =>
    region == 'cn_mainland' ? 'CNY' : 'USD';

const creatorPayoutHoldDuration = Duration(days: 7);
const creatorAssignmentResponseDuration = Duration(hours: 24);
const deliveryExtensionResponseDuration = Duration(hours: 48);
const deliveryExtensionReminderCooldown = Duration(hours: 24);
const maximumDeliveryExtensionReminders = 3;
const deliveryExtensionEscalationSla = Duration(hours: 48);
const creatorExtensionAcknowledgementSla = Duration(hours: 24);
const creatorExtensionReminderCooldown = Duration(hours: 24);
const maximumCreatorExtensionReminders = 2;
const operationsClaimDuration = Duration(hours: 4);

const customizationReviewReasonCodes = {
  'rights_unverified',
  'materials_incomplete',
  'prohibited_content',
  'device_incompatible',
  'scope_unsupported',
  'other',
};

const requiredCustomizationReviewChecks = {
  'rights_verified',
  'materials_safe',
  'content_allowed',
  'device_compatible',
};

const supportedCustomizationMarketRegions = {
  'us',
  'eea',
  'uk',
  'jp',
  'cn_mainland',
  'hk',
  'mo',
  'tw',
  'asia_other',
  'other',
};

const customizationQuoteTaxTreatments = {
  'tax_included',
  'calculated_at_checkout',
  'not_applicable',
};

String defaultCurrencyForMarketRegion(String region) => switch (region) {
      'jp' => 'JPY',
      'cn_mainland' => 'CNY',
      'hk' => 'HKD',
      'mo' => 'MOP',
      'tw' => 'TWD',
      'eea' => 'EUR',
      'uk' => 'GBP',
      _ => 'USD',
    };

String _materialDeletionDeadline() =>
    DateTime.now().toUtc().add(const Duration(days: 30)).toIso8601String();

Map<String, dynamic> _personalDataExport(CustomizationOrder order) => {
      'orderId': order.id,
      'characterName': order.characterName,
      'sourceType': order.sourceType,
      'status': order.status,
      'marketRegion': order.marketRegion,
      'requestedFeatures': List.of(order.requestedFeatures),
      'privacyConsentVersion': order.privacyConsentVersion,
      'privacyConsentAt': order.privacyConsentAt,
      'materialCount': order.materialCount,
      'reviewDecision': order.reviewDecision,
      'reviewReasonCode': order.reviewReasonCode,
      'reviewNote': order.reviewNote,
      'reviewPolicyVersion': order.reviewPolicyVersion,
      'reviewedAt': order.reviewedAt,
      'resubmissionOfOrderId': order.resubmissionOfOrderId,
      'materialDeletionScheduledAt': order.materialDeletionScheduledAt,
      'materialDeletionRequestedAt': order.materialDeletionRequestedAt,
      'materialDeletedAt': order.materialDeletedAt,
      'paidAt': order.paidAt,
      'deliveredAt': order.deliveredAt,
      'privacyCorrectionStatus': order.privacyCorrectionStatus,
      'privacyCorrectionNote': order.privacyCorrectionNote,
      'privacyCorrectionRequestedAt': order.privacyCorrectionRequestedAt,
      'privacyCorrectionDueAt': order.privacyCorrectionDueAt,
      'privacyCorrectionResolvedAt': order.privacyCorrectionResolvedAt,
      'privacyCorrectionResolutionNote': order.privacyCorrectionResolutionNote,
      'mediaIncluded': false,
      'mediaExclusionReason': '源照片、预览视频和设备内容包不包含在数据副本中',
    };

class CustomizationOrder {
  const CustomizationOrder({
    required this.id,
    required this.characterName,
    required this.sourceType,
    required this.status,
    this.marketRegion = 'unspecified',
    this.requestedFeatures = const [],
    this.privacyConsentVersion,
    this.privacyConsentAt,
    this.materialCount = 0,
    this.quoteAmountCents,
    this.quoteCurrency,
    this.quoteTaxTreatment,
    this.quoteCurrencyOverrideReason,
    this.includedRevisions,
    this.estimatedDeliveryDays,
    this.assignedCreatorId,
    this.creatorSuggestedAmountCents,
    this.creatorSuggestedCurrency,
    this.applicantCreatorIds = const [],
    this.withdrawnApplicantCreatorIds = const [],
    this.declinedAssignedCreatorIds = const [],
    this.lastCreatorDeclineReason,
    this.lastCreatorDeclinedAt,
    this.assignmentResponseDueAt,
    this.timedOutAssignedCreatorIds = const [],
    this.lastAssignmentTimedOutAt,
    this.paymentReference,
    this.paidAt,
    this.productionDueAt,
    this.previousProductionDueAt,
    this.deliveryExtensionReason,
    this.deliveryExtendedAt,
    this.deliveryExtendedBy,
    this.proposedProductionDueAt,
    this.deliveryExtensionStatus,
    this.deliveryExtensionRespondedAt,
    this.deliveryExtensionNotifiedAt,
    this.deliveryExtensionResponseDueAt,
    this.deliveryExtensionReminderCount = 0,
    this.lastDeliveryExtensionReminderAt,
    this.deliveryExtensionEscalatedAt,
    this.deliveryExtensionEscalatedBy,
    this.deliveryExtensionEscalationDueAt,
    this.deliveryExtensionResolutionEvidence,
    this.deliveryExtensionResolvedBy,
    this.deliveryExtensionVersion = 0,
    this.creatorExtensionAcknowledgedVersion = 0,
    this.creatorExtensionAcknowledgedAt,
    this.creatorExtensionAcknowledgementDueAt,
    this.creatorExtensionReminderCount = 0,
    this.lastCreatorExtensionReminderAt,
    this.creatorCommunicationRiskStatus,
    this.creatorCommunicationRiskFlaggedAt,
    this.creatorCommunicationRiskFlaggedBy,
    this.creatorCommunicationRiskResolution,
    this.creatorCommunicationRiskResolutionNote,
    this.creatorCommunicationRiskResolvedAt,
    this.creatorCommunicationRiskResolvedBy,
    this.creatorPerformanceReviewOutcome,
    this.creatorPerformanceReviewNote,
    this.creatorPerformanceReviewResolvedAt,
    this.creatorPerformanceReviewResolvedBy,
    this.operationsAssigneeId,
    this.operationsAssignedAt,
    this.operationsAssignmentExpiresAt,
    this.operationsAuditTrail = const [],
    this.previewReference,
    this.qualityReview = const CharacterQualityReview(),
    this.previewVersion = 0,
    this.revisionsUsed = 0,
    this.revisionNotes = const [],
    this.deliveredAt,
    this.creatorPayoutCents,
    this.creatorPayoutCurrency,
    this.settlementStatus,
    this.payoutEligibleAt,
    this.payoutReference,
    this.payoutAccountVerificationReference,
    this.payoutAttemptCount = 0,
    this.lastPayoutFailureCode,
    this.lastPayoutFailedAt,
    this.settledAt,
    this.disputePriorStatus,
    this.disputeReason,
    this.disputeOpenedAt,
    this.disputeResolution,
    this.refundReference,
    this.refundedAt,
    this.reviewDecision,
    this.reviewReasonCode,
    this.reviewNote,
    this.reviewChecks = const [],
    this.reviewerId,
    this.reviewPolicyVersion,
    this.reviewedAt,
    this.resubmissionOfOrderId,
    this.resubmissionReason,
    this.materialDeletionScheduledAt,
    this.materialDeletionRequestedAt,
    this.materialDeletedAt,
    this.privacyCorrectionStatus,
    this.privacyCorrectionNote,
    this.privacyCorrectionRequestedAt,
    this.privacyCorrectionDueAt,
    this.privacyCorrectionResolvedAt,
    this.privacyCorrectionResolutionNote,
    this.privacyCorrectionResolverId,
  });

  final String id;
  final String characterName;
  final String sourceType;
  final String status;
  final String marketRegion;
  final List<String> requestedFeatures;
  final String? privacyConsentVersion;
  final String? privacyConsentAt;
  final int materialCount;
  final int? quoteAmountCents;
  final String? quoteCurrency;
  final String? quoteTaxTreatment;
  final String? quoteCurrencyOverrideReason;
  final int? includedRevisions;
  final int? estimatedDeliveryDays;
  final String? assignedCreatorId;
  final int? creatorSuggestedAmountCents;
  final String? creatorSuggestedCurrency;
  final List<String> applicantCreatorIds;
  final List<String> withdrawnApplicantCreatorIds;
  final List<String> declinedAssignedCreatorIds;
  final String? lastCreatorDeclineReason;
  final String? lastCreatorDeclinedAt;
  final String? assignmentResponseDueAt;
  final List<String> timedOutAssignedCreatorIds;
  final String? lastAssignmentTimedOutAt;
  final String? paymentReference;
  final String? paidAt;
  final String? productionDueAt;
  final String? previousProductionDueAt;
  final String? deliveryExtensionReason;
  final String? deliveryExtendedAt;
  final String? deliveryExtendedBy;
  final String? proposedProductionDueAt;
  final String? deliveryExtensionStatus;
  final String? deliveryExtensionRespondedAt;
  final String? deliveryExtensionNotifiedAt;
  final String? deliveryExtensionResponseDueAt;
  final int deliveryExtensionReminderCount;
  final String? lastDeliveryExtensionReminderAt;
  final String? deliveryExtensionEscalatedAt;
  final String? deliveryExtensionEscalatedBy;
  final String? deliveryExtensionEscalationDueAt;
  final String? deliveryExtensionResolutionEvidence;
  final String? deliveryExtensionResolvedBy;
  final int deliveryExtensionVersion;
  final int creatorExtensionAcknowledgedVersion;
  final String? creatorExtensionAcknowledgedAt;
  final String? creatorExtensionAcknowledgementDueAt;
  final int creatorExtensionReminderCount;
  final String? lastCreatorExtensionReminderAt;
  final String? creatorCommunicationRiskStatus;
  final String? creatorCommunicationRiskFlaggedAt;
  final String? creatorCommunicationRiskFlaggedBy;
  final String? creatorCommunicationRiskResolution;
  final String? creatorCommunicationRiskResolutionNote;
  final String? creatorCommunicationRiskResolvedAt;
  final String? creatorCommunicationRiskResolvedBy;
  final String? creatorPerformanceReviewOutcome;
  final String? creatorPerformanceReviewNote;
  final String? creatorPerformanceReviewResolvedAt;
  final String? creatorPerformanceReviewResolvedBy;
  final String? operationsAssigneeId;
  final String? operationsAssignedAt;
  final String? operationsAssignmentExpiresAt;
  final List<String> operationsAuditTrail;
  final String? previewReference;
  final CharacterQualityReview qualityReview;
  final int previewVersion;
  final int revisionsUsed;
  final List<String> revisionNotes;
  final String? deliveredAt;
  final int? creatorPayoutCents;
  final String? creatorPayoutCurrency;
  final String? settlementStatus;
  final String? payoutEligibleAt;
  final String? payoutReference;
  final String? payoutAccountVerificationReference;
  final int payoutAttemptCount;
  final String? lastPayoutFailureCode;
  final String? lastPayoutFailedAt;
  final String? settledAt;
  final String? disputePriorStatus;
  final String? disputeReason;
  final String? disputeOpenedAt;
  final String? disputeResolution;
  final String? refundReference;
  final String? refundedAt;
  final String? reviewDecision;
  final String? reviewReasonCode;
  final String? reviewNote;
  final List<String> reviewChecks;
  final String? reviewerId;
  final String? reviewPolicyVersion;
  final String? reviewedAt;
  final String? resubmissionOfOrderId;
  final String? resubmissionReason;
  final String? materialDeletionScheduledAt;
  final String? materialDeletionRequestedAt;
  final String? materialDeletedAt;
  final String? privacyCorrectionStatus;
  final String? privacyCorrectionNote;
  final String? privacyCorrectionRequestedAt;
  final String? privacyCorrectionDueAt;
  final String? privacyCorrectionResolvedAt;
  final String? privacyCorrectionResolutionNote;
  final String? privacyCorrectionResolverId;

  CustomizationOrder copyWith({
    String? status,
    String? marketRegion,
    int? materialCount,
    int? quoteAmountCents,
    String? quoteCurrency,
    String? quoteTaxTreatment,
    String? quoteCurrencyOverrideReason,
    int? includedRevisions,
    int? estimatedDeliveryDays,
    String? assignedCreatorId,
    int? creatorSuggestedAmountCents,
    String? creatorSuggestedCurrency,
    List<String>? applicantCreatorIds,
    List<String>? withdrawnApplicantCreatorIds,
    List<String>? declinedAssignedCreatorIds,
    String? lastCreatorDeclineReason,
    String? lastCreatorDeclinedAt,
    String? assignmentResponseDueAt,
    List<String>? timedOutAssignedCreatorIds,
    String? lastAssignmentTimedOutAt,
    bool clearAssignedCreator = false,
    String? paymentReference,
    String? paidAt,
    String? productionDueAt,
    String? previousProductionDueAt,
    String? deliveryExtensionReason,
    String? deliveryExtendedAt,
    String? deliveryExtendedBy,
    String? proposedProductionDueAt,
    String? deliveryExtensionStatus,
    String? deliveryExtensionRespondedAt,
    String? deliveryExtensionNotifiedAt,
    String? deliveryExtensionResponseDueAt,
    int? deliveryExtensionReminderCount,
    String? lastDeliveryExtensionReminderAt,
    String? deliveryExtensionEscalatedAt,
    String? deliveryExtensionEscalatedBy,
    String? deliveryExtensionEscalationDueAt,
    String? deliveryExtensionResolutionEvidence,
    String? deliveryExtensionResolvedBy,
    int? deliveryExtensionVersion,
    int? creatorExtensionAcknowledgedVersion,
    String? creatorExtensionAcknowledgedAt,
    String? creatorExtensionAcknowledgementDueAt,
    int? creatorExtensionReminderCount,
    String? lastCreatorExtensionReminderAt,
    String? creatorCommunicationRiskStatus,
    String? creatorCommunicationRiskFlaggedAt,
    String? creatorCommunicationRiskFlaggedBy,
    String? creatorCommunicationRiskResolution,
    String? creatorCommunicationRiskResolutionNote,
    String? creatorCommunicationRiskResolvedAt,
    String? creatorCommunicationRiskResolvedBy,
    String? creatorPerformanceReviewOutcome,
    String? creatorPerformanceReviewNote,
    String? creatorPerformanceReviewResolvedAt,
    String? creatorPerformanceReviewResolvedBy,
    String? operationsAssigneeId,
    String? operationsAssignedAt,
    String? operationsAssignmentExpiresAt,
    List<String>? operationsAuditTrail,
    bool clearOperationsAssignee = false,
    String? previewReference,
    CharacterQualityReview? qualityReview,
    int? previewVersion,
    int? revisionsUsed,
    List<String>? revisionNotes,
    String? deliveredAt,
    int? creatorPayoutCents,
    String? creatorPayoutCurrency,
    String? settlementStatus,
    String? payoutEligibleAt,
    String? payoutReference,
    String? payoutAccountVerificationReference,
    int? payoutAttemptCount,
    String? lastPayoutFailureCode,
    String? lastPayoutFailedAt,
    String? settledAt,
    String? disputePriorStatus,
    String? disputeReason,
    String? disputeOpenedAt,
    String? disputeResolution,
    String? refundReference,
    String? refundedAt,
    String? reviewDecision,
    String? reviewReasonCode,
    String? reviewNote,
    List<String>? reviewChecks,
    String? reviewerId,
    String? reviewPolicyVersion,
    String? reviewedAt,
    String? resubmissionOfOrderId,
    String? resubmissionReason,
    String? materialDeletionScheduledAt,
    String? materialDeletionRequestedAt,
    String? materialDeletedAt,
    String? privacyCorrectionStatus,
    String? privacyCorrectionNote,
    String? privacyCorrectionRequestedAt,
    String? privacyCorrectionDueAt,
    String? privacyCorrectionResolvedAt,
    String? privacyCorrectionResolutionNote,
    String? privacyCorrectionResolverId,
  }) =>
      CustomizationOrder(
        id: id,
        characterName: characterName,
        sourceType: sourceType,
        status: status ?? this.status,
        marketRegion: marketRegion ?? this.marketRegion,
        requestedFeatures: requestedFeatures,
        privacyConsentVersion: privacyConsentVersion,
        privacyConsentAt: privacyConsentAt,
        materialCount: materialCount ?? this.materialCount,
        quoteAmountCents: quoteAmountCents ?? this.quoteAmountCents,
        quoteCurrency: quoteCurrency ?? this.quoteCurrency,
        quoteTaxTreatment: quoteTaxTreatment ?? this.quoteTaxTreatment,
        quoteCurrencyOverrideReason:
            quoteCurrencyOverrideReason ?? this.quoteCurrencyOverrideReason,
        includedRevisions: includedRevisions ?? this.includedRevisions,
        estimatedDeliveryDays:
            estimatedDeliveryDays ?? this.estimatedDeliveryDays,
        assignedCreatorId: clearAssignedCreator
            ? null
            : assignedCreatorId ?? this.assignedCreatorId,
        creatorSuggestedAmountCents:
            creatorSuggestedAmountCents ?? this.creatorSuggestedAmountCents,
        creatorSuggestedCurrency:
            creatorSuggestedCurrency ?? this.creatorSuggestedCurrency,
        applicantCreatorIds: applicantCreatorIds ?? this.applicantCreatorIds,
        withdrawnApplicantCreatorIds:
            withdrawnApplicantCreatorIds ?? this.withdrawnApplicantCreatorIds,
        declinedAssignedCreatorIds:
            declinedAssignedCreatorIds ?? this.declinedAssignedCreatorIds,
        lastCreatorDeclineReason:
            lastCreatorDeclineReason ?? this.lastCreatorDeclineReason,
        lastCreatorDeclinedAt:
            lastCreatorDeclinedAt ?? this.lastCreatorDeclinedAt,
        assignmentResponseDueAt:
            assignmentResponseDueAt ?? this.assignmentResponseDueAt,
        timedOutAssignedCreatorIds:
            timedOutAssignedCreatorIds ?? this.timedOutAssignedCreatorIds,
        lastAssignmentTimedOutAt:
            lastAssignmentTimedOutAt ?? this.lastAssignmentTimedOutAt,
        paymentReference: paymentReference ?? this.paymentReference,
        paidAt: paidAt ?? this.paidAt,
        productionDueAt: productionDueAt ?? this.productionDueAt,
        previousProductionDueAt:
            previousProductionDueAt ?? this.previousProductionDueAt,
        deliveryExtensionReason:
            deliveryExtensionReason ?? this.deliveryExtensionReason,
        deliveryExtendedAt: deliveryExtendedAt ?? this.deliveryExtendedAt,
        deliveryExtendedBy: deliveryExtendedBy ?? this.deliveryExtendedBy,
        proposedProductionDueAt:
            proposedProductionDueAt ?? this.proposedProductionDueAt,
        deliveryExtensionStatus:
            deliveryExtensionStatus ?? this.deliveryExtensionStatus,
        deliveryExtensionRespondedAt:
            deliveryExtensionRespondedAt ?? this.deliveryExtensionRespondedAt,
        deliveryExtensionNotifiedAt:
            deliveryExtensionNotifiedAt ?? this.deliveryExtensionNotifiedAt,
        deliveryExtensionResponseDueAt: deliveryExtensionResponseDueAt ??
            this.deliveryExtensionResponseDueAt,
        deliveryExtensionReminderCount: deliveryExtensionReminderCount ??
            this.deliveryExtensionReminderCount,
        lastDeliveryExtensionReminderAt: lastDeliveryExtensionReminderAt ??
            this.lastDeliveryExtensionReminderAt,
        deliveryExtensionEscalatedAt:
            deliveryExtensionEscalatedAt ?? this.deliveryExtensionEscalatedAt,
        deliveryExtensionEscalatedBy:
            deliveryExtensionEscalatedBy ?? this.deliveryExtensionEscalatedBy,
        deliveryExtensionEscalationDueAt: deliveryExtensionEscalationDueAt ??
            this.deliveryExtensionEscalationDueAt,
        deliveryExtensionResolutionEvidence:
            deliveryExtensionResolutionEvidence ??
                this.deliveryExtensionResolutionEvidence,
        deliveryExtensionResolvedBy:
            deliveryExtensionResolvedBy ?? this.deliveryExtensionResolvedBy,
        deliveryExtensionVersion:
            deliveryExtensionVersion ?? this.deliveryExtensionVersion,
        creatorExtensionAcknowledgedVersion:
            creatorExtensionAcknowledgedVersion ??
                this.creatorExtensionAcknowledgedVersion,
        creatorExtensionAcknowledgedAt: creatorExtensionAcknowledgedAt ??
            this.creatorExtensionAcknowledgedAt,
        creatorExtensionAcknowledgementDueAt:
            creatorExtensionAcknowledgementDueAt ??
                this.creatorExtensionAcknowledgementDueAt,
        creatorExtensionReminderCount:
            creatorExtensionReminderCount ?? this.creatorExtensionReminderCount,
        lastCreatorExtensionReminderAt: lastCreatorExtensionReminderAt ??
            this.lastCreatorExtensionReminderAt,
        creatorCommunicationRiskStatus: creatorCommunicationRiskStatus ??
            this.creatorCommunicationRiskStatus,
        creatorCommunicationRiskFlaggedAt: creatorCommunicationRiskFlaggedAt ??
            this.creatorCommunicationRiskFlaggedAt,
        creatorCommunicationRiskFlaggedBy: creatorCommunicationRiskFlaggedBy ??
            this.creatorCommunicationRiskFlaggedBy,
        creatorCommunicationRiskResolution:
            creatorCommunicationRiskResolution ??
                this.creatorCommunicationRiskResolution,
        creatorCommunicationRiskResolutionNote:
            creatorCommunicationRiskResolutionNote ??
                this.creatorCommunicationRiskResolutionNote,
        creatorCommunicationRiskResolvedAt:
            creatorCommunicationRiskResolvedAt ??
                this.creatorCommunicationRiskResolvedAt,
        creatorCommunicationRiskResolvedBy:
            creatorCommunicationRiskResolvedBy ??
                this.creatorCommunicationRiskResolvedBy,
        creatorPerformanceReviewOutcome: creatorPerformanceReviewOutcome ??
            this.creatorPerformanceReviewOutcome,
        creatorPerformanceReviewNote:
            creatorPerformanceReviewNote ?? this.creatorPerformanceReviewNote,
        creatorPerformanceReviewResolvedAt:
            creatorPerformanceReviewResolvedAt ??
                this.creatorPerformanceReviewResolvedAt,
        creatorPerformanceReviewResolvedBy:
            creatorPerformanceReviewResolvedBy ??
                this.creatorPerformanceReviewResolvedBy,
        operationsAssigneeId: clearOperationsAssignee
            ? null
            : operationsAssigneeId ?? this.operationsAssigneeId,
        operationsAssignedAt: clearOperationsAssignee
            ? null
            : operationsAssignedAt ?? this.operationsAssignedAt,
        operationsAssignmentExpiresAt: clearOperationsAssignee
            ? null
            : operationsAssignmentExpiresAt ??
                this.operationsAssignmentExpiresAt,
        operationsAuditTrail: operationsAuditTrail ?? this.operationsAuditTrail,
        previewReference: previewReference ?? this.previewReference,
        qualityReview: qualityReview ?? this.qualityReview,
        previewVersion: previewVersion ?? this.previewVersion,
        revisionsUsed: revisionsUsed ?? this.revisionsUsed,
        revisionNotes: revisionNotes ?? this.revisionNotes,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        creatorPayoutCents: creatorPayoutCents ?? this.creatorPayoutCents,
        creatorPayoutCurrency:
            creatorPayoutCurrency ?? this.creatorPayoutCurrency,
        settlementStatus: settlementStatus ?? this.settlementStatus,
        payoutEligibleAt: payoutEligibleAt ?? this.payoutEligibleAt,
        payoutReference: payoutReference ?? this.payoutReference,
        payoutAccountVerificationReference:
            payoutAccountVerificationReference ??
                this.payoutAccountVerificationReference,
        payoutAttemptCount: payoutAttemptCount ?? this.payoutAttemptCount,
        lastPayoutFailureCode:
            lastPayoutFailureCode ?? this.lastPayoutFailureCode,
        lastPayoutFailedAt: lastPayoutFailedAt ?? this.lastPayoutFailedAt,
        settledAt: settledAt ?? this.settledAt,
        disputePriorStatus: disputePriorStatus ?? this.disputePriorStatus,
        disputeReason: disputeReason ?? this.disputeReason,
        disputeOpenedAt: disputeOpenedAt ?? this.disputeOpenedAt,
        disputeResolution: disputeResolution ?? this.disputeResolution,
        refundReference: refundReference ?? this.refundReference,
        refundedAt: refundedAt ?? this.refundedAt,
        reviewDecision: reviewDecision ?? this.reviewDecision,
        reviewReasonCode: reviewReasonCode ?? this.reviewReasonCode,
        reviewNote: reviewNote ?? this.reviewNote,
        reviewChecks: reviewChecks ?? this.reviewChecks,
        reviewerId: reviewerId ?? this.reviewerId,
        reviewPolicyVersion: reviewPolicyVersion ?? this.reviewPolicyVersion,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        resubmissionOfOrderId:
            resubmissionOfOrderId ?? this.resubmissionOfOrderId,
        resubmissionReason: resubmissionReason ?? this.resubmissionReason,
        materialDeletionScheduledAt:
            materialDeletionScheduledAt ?? this.materialDeletionScheduledAt,
        materialDeletionRequestedAt:
            materialDeletionRequestedAt ?? this.materialDeletionRequestedAt,
        materialDeletedAt: materialDeletedAt ?? this.materialDeletedAt,
        privacyCorrectionStatus:
            privacyCorrectionStatus ?? this.privacyCorrectionStatus,
        privacyCorrectionNote:
            privacyCorrectionNote ?? this.privacyCorrectionNote,
        privacyCorrectionRequestedAt:
            privacyCorrectionRequestedAt ?? this.privacyCorrectionRequestedAt,
        privacyCorrectionDueAt:
            privacyCorrectionDueAt ?? this.privacyCorrectionDueAt,
        privacyCorrectionResolvedAt:
            privacyCorrectionResolvedAt ?? this.privacyCorrectionResolvedAt,
        privacyCorrectionResolutionNote: privacyCorrectionResolutionNote ??
            this.privacyCorrectionResolutionNote,
        privacyCorrectionResolverId:
            privacyCorrectionResolverId ?? this.privacyCorrectionResolverId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'characterName': characterName,
        'sourceType': sourceType,
        'status': status,
        'marketRegion': marketRegion,
        'requestedFeatures': requestedFeatures,
        'privacyConsentVersion': privacyConsentVersion,
        'privacyConsentAt': privacyConsentAt,
        'materialCount': materialCount,
        'quoteAmountCents': quoteAmountCents,
        'quoteCurrency': quoteCurrency,
        'quoteTaxTreatment': quoteTaxTreatment,
        'quoteCurrencyOverrideReason': quoteCurrencyOverrideReason,
        'includedRevisions': includedRevisions,
        'estimatedDeliveryDays': estimatedDeliveryDays,
        'assignedCreatorId': assignedCreatorId,
        'creatorSuggestedAmountCents': creatorSuggestedAmountCents,
        'creatorSuggestedCurrency': creatorSuggestedCurrency,
        'applicantCreatorIds': applicantCreatorIds,
        'withdrawnApplicantCreatorIds': withdrawnApplicantCreatorIds,
        'declinedAssignedCreatorIds': declinedAssignedCreatorIds,
        'lastCreatorDeclineReason': lastCreatorDeclineReason,
        'lastCreatorDeclinedAt': lastCreatorDeclinedAt,
        'assignmentResponseDueAt': assignmentResponseDueAt,
        'timedOutAssignedCreatorIds': timedOutAssignedCreatorIds,
        'lastAssignmentTimedOutAt': lastAssignmentTimedOutAt,
        'paymentReference': paymentReference,
        'paidAt': paidAt,
        'productionDueAt': productionDueAt,
        'previousProductionDueAt': previousProductionDueAt,
        'deliveryExtensionReason': deliveryExtensionReason,
        'deliveryExtendedAt': deliveryExtendedAt,
        'deliveryExtendedBy': deliveryExtendedBy,
        'proposedProductionDueAt': proposedProductionDueAt,
        'deliveryExtensionStatus': deliveryExtensionStatus,
        'deliveryExtensionRespondedAt': deliveryExtensionRespondedAt,
        'deliveryExtensionNotifiedAt': deliveryExtensionNotifiedAt,
        'deliveryExtensionResponseDueAt': deliveryExtensionResponseDueAt,
        'deliveryExtensionReminderCount': deliveryExtensionReminderCount,
        'lastDeliveryExtensionReminderAt': lastDeliveryExtensionReminderAt,
        'deliveryExtensionEscalatedAt': deliveryExtensionEscalatedAt,
        'deliveryExtensionEscalatedBy': deliveryExtensionEscalatedBy,
        'deliveryExtensionEscalationDueAt': deliveryExtensionEscalationDueAt,
        'deliveryExtensionResolutionEvidence':
            deliveryExtensionResolutionEvidence,
        'deliveryExtensionResolvedBy': deliveryExtensionResolvedBy,
        'deliveryExtensionVersion': deliveryExtensionVersion,
        'creatorExtensionAcknowledgedVersion':
            creatorExtensionAcknowledgedVersion,
        'creatorExtensionAcknowledgedAt': creatorExtensionAcknowledgedAt,
        'creatorExtensionAcknowledgementDueAt':
            creatorExtensionAcknowledgementDueAt,
        'creatorExtensionReminderCount': creatorExtensionReminderCount,
        'lastCreatorExtensionReminderAt': lastCreatorExtensionReminderAt,
        'creatorCommunicationRiskStatus': creatorCommunicationRiskStatus,
        'creatorCommunicationRiskFlaggedAt': creatorCommunicationRiskFlaggedAt,
        'creatorCommunicationRiskFlaggedBy': creatorCommunicationRiskFlaggedBy,
        'creatorCommunicationRiskResolution':
            creatorCommunicationRiskResolution,
        'creatorCommunicationRiskResolutionNote':
            creatorCommunicationRiskResolutionNote,
        'creatorCommunicationRiskResolvedAt':
            creatorCommunicationRiskResolvedAt,
        'creatorCommunicationRiskResolvedBy':
            creatorCommunicationRiskResolvedBy,
        'creatorPerformanceReviewOutcome': creatorPerformanceReviewOutcome,
        'creatorPerformanceReviewNote': creatorPerformanceReviewNote,
        'creatorPerformanceReviewResolvedAt':
            creatorPerformanceReviewResolvedAt,
        'creatorPerformanceReviewResolvedBy':
            creatorPerformanceReviewResolvedBy,
        'operationsAssigneeId': operationsAssigneeId,
        'operationsAssignedAt': operationsAssignedAt,
        'operationsAssignmentExpiresAt': operationsAssignmentExpiresAt,
        'operationsAuditTrail': operationsAuditTrail,
        'previewReference': previewReference,
        'qualityReview': qualityReview.toJson(),
        'previewVersion': previewVersion,
        'revisionsUsed': revisionsUsed,
        'revisionNotes': revisionNotes,
        'deliveredAt': deliveredAt,
        'creatorPayoutCents': creatorPayoutCents,
        'creatorPayoutCurrency': creatorPayoutCurrency,
        'settlementStatus': settlementStatus,
        'payoutEligibleAt': payoutEligibleAt,
        'payoutReference': payoutReference,
        'payoutAccountVerificationReference':
            payoutAccountVerificationReference,
        'payoutAttemptCount': payoutAttemptCount,
        'lastPayoutFailureCode': lastPayoutFailureCode,
        'lastPayoutFailedAt': lastPayoutFailedAt,
        'settledAt': settledAt,
        'disputePriorStatus': disputePriorStatus,
        'disputeReason': disputeReason,
        'disputeOpenedAt': disputeOpenedAt,
        'disputeResolution': disputeResolution,
        'refundReference': refundReference,
        'refundedAt': refundedAt,
        'reviewDecision': reviewDecision,
        'reviewReasonCode': reviewReasonCode,
        'reviewNote': reviewNote,
        'reviewChecks': reviewChecks,
        'reviewerId': reviewerId,
        'reviewPolicyVersion': reviewPolicyVersion,
        'reviewedAt': reviewedAt,
        'resubmissionOfOrderId': resubmissionOfOrderId,
        'resubmissionReason': resubmissionReason,
        'materialDeletionScheduledAt': materialDeletionScheduledAt,
        'materialDeletionRequestedAt': materialDeletionRequestedAt,
        'materialDeletedAt': materialDeletedAt,
        'privacyCorrectionStatus': privacyCorrectionStatus,
        'privacyCorrectionNote': privacyCorrectionNote,
        'privacyCorrectionRequestedAt': privacyCorrectionRequestedAt,
        'privacyCorrectionDueAt': privacyCorrectionDueAt,
        'privacyCorrectionResolvedAt': privacyCorrectionResolvedAt,
        'privacyCorrectionResolutionNote': privacyCorrectionResolutionNote,
        'privacyCorrectionResolverId': privacyCorrectionResolverId,
      };

  static CustomizationOrder? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final id = value['id'];
    final characterName = value['characterName'];
    final sourceType = value['sourceType'];
    final status = value['status'];
    if (id is! String ||
        characterName is! String ||
        sourceType is! String ||
        status is! String) {
      return null;
    }
    return CustomizationOrder(
      id: id,
      characterName: characterName,
      sourceType: sourceType,
      status: status,
      marketRegion: value['marketRegion'] as String? ?? 'unspecified',
      requestedFeatures: (value['requestedFeatures'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      privacyConsentVersion: value['privacyConsentVersion'] as String?,
      privacyConsentAt: value['privacyConsentAt'] as String?,
      materialCount: value['materialCount'] is int
          ? value['materialCount'] as int
          : (value['materialFileNames'] as List? ?? const []).length,
      quoteAmountCents: value['quoteAmountCents'] as int?,
      quoteCurrency: value['quoteCurrency'] as String?,
      quoteTaxTreatment: value['quoteTaxTreatment'] as String?,
      quoteCurrencyOverrideReason:
          value['quoteCurrencyOverrideReason'] as String?,
      includedRevisions: value['includedRevisions'] as int?,
      estimatedDeliveryDays: value['estimatedDeliveryDays'] as int?,
      assignedCreatorId: value['assignedCreatorId'] as String?,
      creatorSuggestedAmountCents: value['creatorSuggestedAmountCents'] as int?,
      creatorSuggestedCurrency: value['creatorSuggestedCurrency'] as String?,
      applicantCreatorIds: (value['applicantCreatorIds'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      withdrawnApplicantCreatorIds:
          (value['withdrawnApplicantCreatorIds'] as List? ?? const [])
              .whereType<String>()
              .toList(),
      declinedAssignedCreatorIds:
          (value['declinedAssignedCreatorIds'] as List? ?? const [])
              .whereType<String>()
              .toList(),
      lastCreatorDeclineReason: value['lastCreatorDeclineReason'] as String?,
      lastCreatorDeclinedAt: value['lastCreatorDeclinedAt'] as String?,
      assignmentResponseDueAt: value['assignmentResponseDueAt'] as String?,
      timedOutAssignedCreatorIds:
          (value['timedOutAssignedCreatorIds'] as List? ?? const [])
              .whereType<String>()
              .toList(),
      lastAssignmentTimedOutAt: value['lastAssignmentTimedOutAt'] as String?,
      paymentReference: value['paymentReference'] as String?,
      paidAt: value['paidAt'] as String?,
      productionDueAt: value['productionDueAt'] as String?,
      previousProductionDueAt: value['previousProductionDueAt'] as String?,
      deliveryExtensionReason: value['deliveryExtensionReason'] as String?,
      deliveryExtendedAt: value['deliveryExtendedAt'] as String?,
      deliveryExtendedBy: value['deliveryExtendedBy'] as String?,
      proposedProductionDueAt: value['proposedProductionDueAt'] as String?,
      deliveryExtensionStatus: value['deliveryExtensionStatus'] as String?,
      deliveryExtensionRespondedAt:
          value['deliveryExtensionRespondedAt'] as String?,
      deliveryExtensionNotifiedAt:
          value['deliveryExtensionNotifiedAt'] as String?,
      deliveryExtensionResponseDueAt:
          value['deliveryExtensionResponseDueAt'] as String?,
      deliveryExtensionReminderCount:
          value['deliveryExtensionReminderCount'] as int? ?? 0,
      lastDeliveryExtensionReminderAt:
          value['lastDeliveryExtensionReminderAt'] as String?,
      deliveryExtensionEscalatedAt:
          value['deliveryExtensionEscalatedAt'] as String?,
      deliveryExtensionEscalatedBy:
          value['deliveryExtensionEscalatedBy'] as String?,
      deliveryExtensionEscalationDueAt:
          value['deliveryExtensionEscalationDueAt'] as String?,
      deliveryExtensionResolutionEvidence:
          value['deliveryExtensionResolutionEvidence'] as String?,
      deliveryExtensionResolvedBy:
          value['deliveryExtensionResolvedBy'] as String?,
      deliveryExtensionVersion: value['deliveryExtensionVersion'] as int? ?? 0,
      creatorExtensionAcknowledgedVersion:
          value['creatorExtensionAcknowledgedVersion'] as int? ?? 0,
      creatorExtensionAcknowledgedAt:
          value['creatorExtensionAcknowledgedAt'] as String?,
      creatorExtensionAcknowledgementDueAt:
          value['creatorExtensionAcknowledgementDueAt'] as String?,
      creatorExtensionReminderCount:
          value['creatorExtensionReminderCount'] as int? ?? 0,
      lastCreatorExtensionReminderAt:
          value['lastCreatorExtensionReminderAt'] as String?,
      creatorCommunicationRiskStatus:
          value['creatorCommunicationRiskStatus'] as String?,
      creatorCommunicationRiskFlaggedAt:
          value['creatorCommunicationRiskFlaggedAt'] as String?,
      creatorCommunicationRiskFlaggedBy:
          value['creatorCommunicationRiskFlaggedBy'] as String?,
      creatorCommunicationRiskResolution:
          value['creatorCommunicationRiskResolution'] as String?,
      creatorCommunicationRiskResolutionNote:
          value['creatorCommunicationRiskResolutionNote'] as String?,
      creatorCommunicationRiskResolvedAt:
          value['creatorCommunicationRiskResolvedAt'] as String?,
      creatorCommunicationRiskResolvedBy:
          value['creatorCommunicationRiskResolvedBy'] as String?,
      creatorPerformanceReviewOutcome:
          value['creatorPerformanceReviewOutcome'] as String?,
      creatorPerformanceReviewNote:
          value['creatorPerformanceReviewNote'] as String?,
      creatorPerformanceReviewResolvedAt:
          value['creatorPerformanceReviewResolvedAt'] as String?,
      creatorPerformanceReviewResolvedBy:
          value['creatorPerformanceReviewResolvedBy'] as String?,
      operationsAssigneeId: value['operationsAssigneeId'] as String?,
      operationsAssignedAt: value['operationsAssignedAt'] as String?,
      operationsAssignmentExpiresAt:
          value['operationsAssignmentExpiresAt'] as String?,
      operationsAuditTrail: (value['operationsAuditTrail'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      previewReference: value['previewReference'] as String?,
      qualityReview: CharacterQualityReview.fromJson(value['qualityReview']),
      previewVersion: value['previewVersion'] as int? ?? 0,
      revisionsUsed: value['revisionsUsed'] as int? ?? 0,
      revisionNotes: (value['revisionNotes'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      deliveredAt: value['deliveredAt'] as String?,
      creatorPayoutCents: value['creatorPayoutCents'] as int?,
      creatorPayoutCurrency: value['creatorPayoutCurrency'] as String?,
      settlementStatus: value['settlementStatus'] as String?,
      payoutEligibleAt: value['payoutEligibleAt'] as String?,
      payoutReference: value['payoutReference'] as String?,
      payoutAccountVerificationReference:
          value['payoutAccountVerificationReference'] as String?,
      payoutAttemptCount: value['payoutAttemptCount'] as int? ?? 0,
      lastPayoutFailureCode: value['lastPayoutFailureCode'] as String?,
      lastPayoutFailedAt: value['lastPayoutFailedAt'] as String?,
      settledAt: value['settledAt'] as String?,
      disputePriorStatus: value['disputePriorStatus'] as String?,
      disputeReason: value['disputeReason'] as String?,
      disputeOpenedAt: value['disputeOpenedAt'] as String?,
      disputeResolution: value['disputeResolution'] as String?,
      refundReference: value['refundReference'] as String?,
      refundedAt: value['refundedAt'] as String?,
      reviewDecision: value['reviewDecision'] as String?,
      reviewReasonCode: value['reviewReasonCode'] as String?,
      reviewNote: value['reviewNote'] as String?,
      reviewChecks: (value['reviewChecks'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      reviewerId: value['reviewerId'] as String?,
      reviewPolicyVersion: value['reviewPolicyVersion'] as String?,
      reviewedAt: value['reviewedAt'] as String?,
      resubmissionOfOrderId: value['resubmissionOfOrderId'] as String?,
      resubmissionReason: value['resubmissionReason'] as String?,
      materialDeletionScheduledAt:
          value['materialDeletionScheduledAt'] as String?,
      materialDeletionRequestedAt:
          value['materialDeletionRequestedAt'] as String?,
      materialDeletedAt: value['materialDeletedAt'] as String?,
      privacyCorrectionStatus: value['privacyCorrectionStatus'] as String?,
      privacyCorrectionNote: value['privacyCorrectionNote'] as String?,
      privacyCorrectionRequestedAt:
          value['privacyCorrectionRequestedAt'] as String?,
      privacyCorrectionDueAt: value['privacyCorrectionDueAt'] as String?,
      privacyCorrectionResolvedAt:
          value['privacyCorrectionResolvedAt'] as String?,
      privacyCorrectionResolutionNote:
          value['privacyCorrectionResolutionNote'] as String?,
      privacyCorrectionResolverId:
          value['privacyCorrectionResolverId'] as String?,
    );
  }
}

abstract interface class CustomizationOrderRepository {
  Future<List<CustomizationOrder>> loadOrders();

  Future<bool> submitReview({
    required String characterName,
    required String sourceType,
    List<String> requestedFeatures = const [],
    String? privacyConsentVersion,
    int materialCount = 0,
    String marketRegion = 'unspecified',
    String? resubmissionOfOrderId,
    String? resubmissionReason,
  });

  Future<void> withdrawReview(String orderId);

  Future<int> processDueMaterialDeletions({DateTime? now});

  Future<bool> requestImmediateMaterialDeletion(String orderId);

  Future<Map<String, dynamic>?> exportPersonalData(String orderId);

  Future<bool> requestPrivacyCorrection({
    required String orderId,
    required String note,
  });

  Future<void> resolvePrivacyCorrection({
    required String orderId,
    required bool approved,
    required String resolutionNote,
    String resolverId = 'platform-reviewer-local',
  });

  Future<void> approveForCreatorMatching(
    String orderId, {
    required List<String> reviewChecks,
    String reviewerId = 'platform-reviewer-local',
    String reviewPolicyVersion = 'customization-review-v1',
  });

  Future<void> rejectReview({
    required String orderId,
    required String reason,
    String reasonCode = 'other',
    String reviewerId = 'platform-reviewer-local',
    String reviewPolicyVersion = 'customization-review-v1',
  });

  Future<void> applyForCreator({
    required String orderId,
    required String creatorId,
  });

  Future<void> withdrawCreatorApplication({
    required String orderId,
    required String creatorId,
  });

  Future<void> declineAssignedTask({
    required String orderId,
    required String creatorId,
    required String reason,
  });

  Future<int> processExpiredCreatorAssignments({DateTime? now});

  Future<void> assignCreator({
    required String orderId,
    required String creatorId,
  });

  Future<void> submitCreatorProposal({
    required String orderId,
    required String creatorId,
    required int suggestedAmountCents,
    String creatorMarketRegion = 'other',
    required int estimatedDeliveryDays,
  });

  Future<void> publishPlatformQuote({
    required String orderId,
    required int amountCents,
    required String currency,
    String taxTreatment = 'calculated_at_checkout',
    String? currencyOverrideReason,
    required int includedRevisions,
    required int estimatedDeliveryDays,
  });

  Future<void> acceptQuote(String orderId);

  Future<void> declineQuote(String orderId);

  Future<void> recordVerifiedPayment({
    required String orderId,
    required String paymentReference,
  });

  Future<void> extendProductionDeadline({
    required String orderId,
    required int additionalDays,
    required String reason,
    String operatorId = 'platform-operator-local',
  });

  Future<void> respondToDeliveryExtension({
    required String orderId,
    required bool accepted,
  });

  Future<void> recordDeliveryExtensionReminder({
    required String orderId,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  });

  Future<void> escalateDeliveryExtensionResponse({
    required String orderId,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  });

  Future<void> resolveEscalatedDeliveryExtension({
    required String orderId,
    required EscalatedExtensionResolution resolution,
    required String evidenceReference,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  });

  Future<void> acknowledgeCreatorExtensionNotice({
    required String orderId,
    required String creatorId,
    DateTime? now,
  });

  Future<void> recordCreatorExtensionReminder({
    required String orderId,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  });

  Future<void> flagCreatorCommunicationRisk({
    required String orderId,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  });

  Future<void> resolveCreatorCommunicationRisk({
    required String orderId,
    required CreatorCommunicationRiskResolution resolution,
    required String note,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  });

  Future<void> resolveCreatorPerformanceReview({
    required String orderId,
    required CreatorPerformanceReviewOutcome outcome,
    required String note,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  });

  Future<void> claimOperationsOrder({
    required String orderId,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  });

  Future<void> releaseOperationsOrder({
    required String orderId,
    String operatorId = 'platform-operator-local',
  });

  Future<void> renewOperationsOrderClaim({
    required String orderId,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  });

  Future<void> submitCreatorPreview({
    required String orderId,
    required String creatorId,
    required String previewReference,
  });

  Future<void> submitContentQualityReview({
    required String orderId,
    required int expectedPreviewVersion,
    required CharacterQualityReview review,
  });

  Future<void> requestRevision(
    String orderId, {
    required String note,
  });

  Future<void> approveDelivery(String orderId);

  Future<void> recordCreatorPayout({
    required String orderId,
    required String payoutReference,
    required String payoutAccountVerificationReference,
  });

  Future<void> recordCreatorPayoutFailure({
    required String orderId,
    required String failureCode,
    required String payoutAccountVerificationReference,
  });

  Future<void> openDispute({
    required String orderId,
    required String reason,
  });

  Future<void> resolveDispute({
    required String orderId,
    required DisputeResolution resolution,
  });

  Future<void> recordVerifiedRefund({
    required String orderId,
    required String refundReference,
  });
}

class LocalCustomizationOrderRepository
    implements CustomizationOrderRepository {
  const LocalCustomizationOrderRepository();

  Future<File> _file() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final directory = Directory(
      '${supportDirectory.path}${Platform.pathSeparator}character_gate',
    );
    await directory.create(recursive: true);
    return File(
      '${directory.path}${Platform.pathSeparator}customization_orders.json',
    );
  }

  @override
  Future<void> claimOperationsOrder({
    required String orderId,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  }) async {
    if (operatorId.trim().isEmpty) return;
    final orders = await loadOrders();
    final claimTime = (now ?? DateTime.now()).toUtc();
    final timestamp = claimTime.toIso8601String();
    await _saveOrders(
      orders
          .map((order) => order.id == orderId &&
                  (order.operationsAssigneeId == null ||
                      order.operationsAssigneeId == operatorId.trim() ||
                      _isOperationsClaimExpired(order, claimTime))
              ? order.copyWith(
                  operationsAssigneeId: operatorId.trim(),
                  operationsAssignedAt: timestamp,
                  operationsAssignmentExpiresAt:
                      claimTime.add(operationsClaimDuration).toIso8601String(),
                  operationsAuditTrail: _appendOperationsAudit(
                    order.operationsAuditTrail,
                    timestamp,
                    order.operationsAssigneeId == null
                        ? 'claimed'
                        : order.operationsAssigneeId == operatorId.trim()
                            ? 'reclaimed'
                            : 'taken_over',
                    operatorId.trim(),
                  ),
                )
              : order)
          .toList(),
    );
  }

  @override
  Future<void> releaseOperationsOrder({
    required String orderId,
    String operatorId = 'platform-operator-local',
  }) async {
    final orders = await loadOrders();
    final timestamp = DateTime.now().toUtc().toIso8601String();
    await _saveOrders(
      orders
          .map((order) => order.id == orderId &&
                  order.operationsAssigneeId == operatorId.trim()
              ? order.copyWith(
                  clearOperationsAssignee: true,
                  operationsAuditTrail: _appendOperationsAudit(
                    order.operationsAuditTrail,
                    timestamp,
                    'released',
                    operatorId.trim(),
                  ),
                )
              : order)
          .toList(),
    );
  }

  @override
  Future<void> renewOperationsOrderClaim({
    required String orderId,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  }) async {
    if (operatorId.trim().isEmpty) return;
    final claimTime = (now ?? DateTime.now()).toUtc();
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map((order) => order.id == orderId &&
                  order.operationsAssigneeId == operatorId.trim() &&
                  !_isOperationsClaimExpired(order, claimTime)
              ? order.copyWith(
                  operationsAssignedAt: claimTime.toIso8601String(),
                  operationsAssignmentExpiresAt:
                      claimTime.add(operationsClaimDuration).toIso8601String(),
                  operationsAuditTrail: _appendOperationsAudit(
                    order.operationsAuditTrail,
                    claimTime.toIso8601String(),
                    'renewed',
                    operatorId.trim(),
                  ),
                )
              : order)
          .toList(),
    );
  }

  @override
  Future<void> resolveCreatorCommunicationRisk({
    required String orderId,
    required CreatorCommunicationRiskResolution resolution,
    required String note,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  }) async {
    if (note.trim().isEmpty || operatorId.trim().isEmpty) return;
    final timestamp = (now ?? DateTime.now()).toUtc();
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map((order) => order.id == orderId
              ? _resolveCreatorCommunicationRisk(
                  order, resolution, note.trim(), operatorId.trim(), timestamp)
              : order)
          .toList(),
    );
  }

  @override
  Future<void> resolveCreatorPerformanceReview({
    required String orderId,
    required CreatorPerformanceReviewOutcome outcome,
    required String note,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  }) async {
    if (note.trim().isEmpty || operatorId.trim().isEmpty) return;
    final timestamp = (now ?? DateTime.now()).toUtc();
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map((order) => order.id == orderId
              ? _resolveCreatorPerformanceReview(
                  order, outcome, note.trim(), operatorId.trim(), timestamp)
              : order)
          .toList(),
    );
  }

  @override
  Future<void> declineAssignedTask({
    required String orderId,
    required String creatorId,
    required String reason,
  }) async {
    final normalizedReason = reason.trim();
    if (normalizedReason.isEmpty) return;
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map(
            (order) => order.id == orderId &&
                    order.status == '创作者评估中' &&
                    order.assignedCreatorId == creatorId
                ? order.copyWith(
                    status: '待创作者申请',
                    clearAssignedCreator: true,
                    applicantCreatorIds: order.applicantCreatorIds
                        .where((id) => id != creatorId)
                        .toList(),
                    declinedAssignedCreatorIds: {
                      ...order.declinedAssignedCreatorIds,
                      creatorId,
                    }.toList(),
                    lastCreatorDeclineReason: normalizedReason,
                    lastCreatorDeclinedAt:
                        DateTime.now().toUtc().toIso8601String(),
                  )
                : order,
          )
          .toList(),
    );
  }

  @override
  Future<void> withdrawCreatorApplication({
    required String orderId,
    required String creatorId,
  }) async {
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map(
            (order) => order.id == orderId &&
                    order.status == '待创作者申请' &&
                    order.applicantCreatorIds.contains(creatorId)
                ? order.copyWith(
                    applicantCreatorIds: order.applicantCreatorIds
                        .where((id) => id != creatorId)
                        .toList(),
                    withdrawnApplicantCreatorIds: {
                      ...order.withdrawnApplicantCreatorIds,
                      creatorId,
                    }.toList(),
                  )
                : order,
          )
          .toList(),
    );
  }

  @Deprecated('Platform flows should call applyForCreator then assignCreator.')
  Future<void> claimForCreator({
    required String orderId,
    required String creatorId,
  }) async {
    await applyForCreator(orderId: orderId, creatorId: creatorId);
    await assignCreator(orderId: orderId, creatorId: creatorId);
  }

  Future<void> _saveOrders(List<CustomizationOrder> orders) async {
    final file = await _file();
    await file.writeAsString(
      jsonEncode(orders.map((order) => order.toJson()).toList()),
      flush: true,
    );
  }

  @override
  Future<List<CustomizationOrder>> loadOrders() async {
    try {
      final file = await _file();
      if (!await file.exists()) return [];
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return [];
      return decoded
          .map(CustomizationOrder.fromJson)
          .whereType<CustomizationOrder>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> submitReview({
    required String characterName,
    required String sourceType,
    List<String> requestedFeatures = const [],
    String? privacyConsentVersion,
    int materialCount = 0,
    String marketRegion = 'unspecified',
    String? resubmissionOfOrderId,
    String? resubmissionReason,
  }) async {
    final orders = await loadOrders();
    final normalizedMarketRegion =
        supportedCustomizationMarketRegions.contains(marketRegion)
            ? marketRegion
            : 'unspecified';
    if (resubmissionOfOrderId != null &&
        orders.any((order) =>
            order.resubmissionOfOrderId == resubmissionOfOrderId &&
            order.status != '预审未通过' &&
            order.status != '已撤回')) {
      return false;
    }
    orders.insert(
      0,
      CustomizationOrder(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        characterName: characterName,
        sourceType: sourceType,
        status: '免费预审中',
        marketRegion: normalizedMarketRegion,
        requestedFeatures: List.of(requestedFeatures),
        privacyConsentVersion: privacyConsentVersion,
        privacyConsentAt: privacyConsentVersion == null
            ? null
            : DateTime.now().toUtc().toIso8601String(),
        materialCount: materialCount,
        resubmissionOfOrderId: resubmissionOfOrderId,
        resubmissionReason: resubmissionReason,
      ),
    );
    await _saveOrders(orders);
    return true;
  }

  @override
  Future<void> withdrawReview(String orderId) async {
    final orders = await loadOrders();
    final updated = orders
        .map(
          (order) => order.id == orderId && order.status == '免费预审中'
              ? CustomizationOrder(
                  id: order.id,
                  characterName: order.characterName,
                  sourceType: order.sourceType,
                  status: '已撤回',
                  marketRegion: order.marketRegion,
                  requestedFeatures: order.requestedFeatures,
                  privacyConsentVersion: order.privacyConsentVersion,
                  privacyConsentAt: order.privacyConsentAt,
                  materialCount: order.materialCount,
                  resubmissionOfOrderId: order.resubmissionOfOrderId,
                  resubmissionReason: order.resubmissionReason,
                  materialDeletionScheduledAt: _materialDeletionDeadline(),
                )
              : order,
        )
        .toList();
    await _saveOrders(updated);
  }

  @override
  Future<int> processDueMaterialDeletions({DateTime? now}) async {
    final effectiveNow = (now ?? DateTime.now()).toUtc();
    final orders = await loadOrders();
    var deletedCount = 0;
    final updated = orders.map((order) {
      final deadline =
          DateTime.tryParse(order.materialDeletionScheduledAt ?? '');
      if (order.materialDeletedAt != null ||
          deadline == null ||
          deadline.toUtc().isAfter(effectiveNow)) {
        return order;
      }
      deletedCount += 1;
      return order.copyWith(
        materialCount: 0,
        materialDeletedAt: effectiveNow.toIso8601String(),
      );
    }).toList();
    if (deletedCount > 0) await _saveOrders(updated);
    return deletedCount;
  }

  @override
  Future<bool> requestImmediateMaterialDeletion(String orderId) async {
    final orders = await loadOrders();
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index < 0 ||
        !{'预审未通过', '已撤回'}.contains(orders[index].status) ||
        orders[index].materialDeletedAt != null) {
      return false;
    }
    final now = DateTime.now().toUtc().toIso8601String();
    orders[index] = orders[index].copyWith(
      materialCount: 0,
      materialDeletionRequestedAt: now,
      materialDeletedAt: now,
    );
    await _saveOrders(orders);
    return true;
  }

  @override
  Future<Map<String, dynamic>?> exportPersonalData(String orderId) async {
    final orders = await loadOrders();
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index < 0) return null;
    return _personalDataExport(orders[index]);
  }

  @override
  Future<bool> requestPrivacyCorrection({
    required String orderId,
    required String note,
  }) async {
    final normalized = note.trim();
    final orders = await loadOrders();
    final index = orders.indexWhere((order) => order.id == orderId);
    if (normalized.isEmpty ||
        index < 0 ||
        orders[index].privacyCorrectionStatus == 'pending') {
      return false;
    }
    final requestedAt = DateTime.now().toUtc();
    orders[index] = orders[index].copyWith(
      privacyCorrectionStatus: 'pending',
      privacyCorrectionNote: normalized,
      privacyCorrectionRequestedAt: requestedAt.toIso8601String(),
      privacyCorrectionDueAt:
          requestedAt.add(const Duration(days: 30)).toIso8601String(),
    );
    await _saveOrders(orders);
    return true;
  }

  @override
  Future<void> resolvePrivacyCorrection({
    required String orderId,
    required bool approved,
    required String resolutionNote,
    String resolverId = 'platform-reviewer-local',
  }) async {
    final normalized = resolutionNote.trim();
    final orders = await loadOrders();
    final index = orders.indexWhere((order) => order.id == orderId);
    if (normalized.isEmpty ||
        index < 0 ||
        orders[index].privacyCorrectionStatus != 'pending') {
      return;
    }
    orders[index] = orders[index].copyWith(
      privacyCorrectionStatus: approved ? 'approved' : 'rejected',
      privacyCorrectionResolutionNote: normalized,
      privacyCorrectionResolverId: resolverId,
      privacyCorrectionResolvedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await _saveOrders(orders);
  }

  @override
  Future<void> approveForCreatorMatching(
    String orderId, {
    required List<String> reviewChecks,
    String reviewerId = 'platform-reviewer-local',
    String reviewPolicyVersion = 'customization-review-v1',
  }) async {
    if (!reviewChecks.toSet().containsAll(requiredCustomizationReviewChecks)) {
      return;
    }
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map(
            (order) => order.id == orderId && order.status == '免费预审中'
                ? order.copyWith(
                    status: '待创作者申请',
                    reviewDecision: 'approved',
                    reviewChecks: List.of(reviewChecks),
                    reviewerId: reviewerId,
                    reviewPolicyVersion: reviewPolicyVersion,
                    reviewedAt: DateTime.now().toUtc().toIso8601String(),
                  )
                : order,
          )
          .toList(),
    );
  }

  @override
  Future<void> rejectReview({
    required String orderId,
    required String reason,
    String reasonCode = 'other',
    String reviewerId = 'platform-reviewer-local',
    String reviewPolicyVersion = 'customization-review-v1',
  }) async {
    final normalizedReason = reason.trim();
    if (normalizedReason.isEmpty) return;
    final normalizedCode = customizationReviewReasonCodes.contains(reasonCode)
        ? reasonCode
        : 'other';
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map(
            (order) => order.id == orderId && order.status == '免费预审中'
                ? order.copyWith(
                    status: '预审未通过',
                    reviewDecision: 'rejected',
                    reviewReasonCode: normalizedCode,
                    reviewNote: normalizedReason,
                    reviewerId: reviewerId,
                    reviewPolicyVersion: reviewPolicyVersion,
                    reviewedAt: DateTime.now().toUtc().toIso8601String(),
                    materialDeletionScheduledAt: _materialDeletionDeadline(),
                  )
                : order,
          )
          .toList(),
    );
  }

  @override
  Future<void> applyForCreator({
    required String orderId,
    required String creatorId,
  }) async {
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map(
            (order) => order.id == orderId &&
                    order.status == '待创作者申请' &&
                    !order.declinedAssignedCreatorIds.contains(creatorId) &&
                    !order.timedOutAssignedCreatorIds.contains(creatorId)
                ? order.copyWith(
                    applicantCreatorIds: {
                      ...order.applicantCreatorIds,
                      creatorId,
                    }.toList(),
                  )
                : order,
          )
          .toList(),
    );
  }

  @override
  Future<void> assignCreator({
    required String orderId,
    required String creatorId,
  }) async {
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map(
            (order) => order.id == orderId &&
                    order.status == '待创作者申请' &&
                    order.applicantCreatorIds.contains(creatorId)
                ? order.copyWith(
                    status: '创作者评估中',
                    assignedCreatorId: creatorId,
                    assignmentResponseDueAt: DateTime.now()
                        .toUtc()
                        .add(creatorAssignmentResponseDuration)
                        .toIso8601String(),
                  )
                : order,
          )
          .toList(),
    );
  }

  @override
  Future<int> processExpiredCreatorAssignments({DateTime? now}) async {
    final cutoff = (now ?? DateTime.now()).toUtc();
    final orders = await loadOrders();
    var count = 0;
    final updated = orders.map((order) {
      final dueAt = DateTime.tryParse(order.assignmentResponseDueAt ?? '');
      if (order.status != '创作者评估中' ||
          order.assignedCreatorId == null ||
          dueAt == null ||
          cutoff.isBefore(dueAt.toUtc())) {
        return order;
      }
      count += 1;
      final creatorId = order.assignedCreatorId!;
      return order.copyWith(
        status: '待创作者申请',
        clearAssignedCreator: true,
        applicantCreatorIds:
            order.applicantCreatorIds.where((id) => id != creatorId).toList(),
        timedOutAssignedCreatorIds: {
          ...order.timedOutAssignedCreatorIds,
          creatorId,
        }.toList(),
        lastAssignmentTimedOutAt: cutoff.toIso8601String(),
      );
    }).toList();
    if (count > 0) await _saveOrders(updated);
    return count;
  }

  @override
  Future<void> submitCreatorProposal({
    required String orderId,
    required String creatorId,
    required int suggestedAmountCents,
    String creatorMarketRegion = 'other',
    required int estimatedDeliveryDays,
  }) async {
    if (suggestedAmountCents <= 0 || estimatedDeliveryDays <= 0) return;
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map(
            (order) => order.id == orderId &&
                    order.status == '创作者评估中' &&
                    order.assignedCreatorId == creatorId
                ? order.copyWith(
                    status: '平台审核报价',
                    creatorSuggestedAmountCents: suggestedAmountCents,
                    creatorSuggestedCurrency:
                        creatorSettlementCurrencyForRegion(creatorMarketRegion),
                    estimatedDeliveryDays: estimatedDeliveryDays,
                  )
                : order,
          )
          .toList(),
    );
  }

  @override
  Future<void> publishPlatformQuote({
    required String orderId,
    required int amountCents,
    required String currency,
    String taxTreatment = 'calculated_at_checkout',
    String? currencyOverrideReason,
    required int includedRevisions,
    required int estimatedDeliveryDays,
  }) async {
    final normalizedTaxTreatment =
        customizationQuoteTaxTreatments.contains(taxTreatment)
            ? taxTreatment
            : 'calculated_at_checkout';
    if (amountCents <= 0 ||
        includedRevisions < 0 ||
        estimatedDeliveryDays <= 0) {
      return;
    }
    final orders = await loadOrders();
    final updated = orders
        .map(
          (order) => order.id == orderId &&
                  order.status == '平台审核报价' &&
                  (currency ==
                          defaultCurrencyForMarketRegion(order.marketRegion) ||
                      (currencyOverrideReason?.trim().isNotEmpty ?? false))
              ? order.copyWith(
                  status: '待确认报价',
                  quoteAmountCents: amountCents,
                  quoteCurrency: currency,
                  quoteTaxTreatment: normalizedTaxTreatment,
                  quoteCurrencyOverrideReason: currencyOverrideReason?.trim(),
                  includedRevisions: includedRevisions,
                  estimatedDeliveryDays: estimatedDeliveryDays,
                  creatorPayoutCents: order.creatorSuggestedAmountCents,
                  creatorPayoutCurrency:
                      order.creatorSuggestedCurrency ?? 'USD',
                )
              : order,
        )
        .toList();
    await _saveOrders(updated);
  }

  @override
  Future<void> acceptQuote(String orderId) async {
    final orders = await loadOrders();
    final updated = orders
        .map(
          (order) => order.id == orderId && order.status == '待确认报价'
              ? order.copyWith(status: '待支付')
              : order,
        )
        .toList();
    await _saveOrders(updated);
  }

  @override
  Future<void> declineQuote(String orderId) async {
    final orders = await loadOrders();
    final updated = orders
        .map(
          (order) => order.id == orderId &&
                  (order.status == '待确认报价' || order.status == '待支付')
              ? order.copyWith(status: '已拒绝报价')
              : order,
        )
        .toList();
    await _saveOrders(updated);
  }

  @override
  Future<void> recordVerifiedPayment({
    required String orderId,
    required String paymentReference,
  }) async {
    if (paymentReference.trim().isEmpty) return;
    final orders = await loadOrders();
    final now = DateTime.now().toUtc();
    final updated = orders
        .map(
          (order) => order.id == orderId && order.status == '待支付'
              ? order.copyWith(
                  status: '制作中',
                  paymentReference: paymentReference,
                  paidAt: now.toIso8601String(),
                  productionDueAt: now
                      .add(Duration(days: order.estimatedDeliveryDays ?? 7))
                      .toIso8601String(),
                  settlementStatus: '平台托管中',
                )
              : order,
        )
        .toList();
    await _saveOrders(updated);
  }

  @override
  Future<void> extendProductionDeadline({
    required String orderId,
    required int additionalDays,
    required String reason,
    String operatorId = 'platform-operator-local',
  }) async {
    final normalizedReason = reason.trim();
    final orders = await loadOrders();
    final now = DateTime.now().toUtc();
    await _saveOrders(
      orders.map((order) {
        final dueAt = DateTime.tryParse(order.productionDueAt ?? '');
        if (order.id != orderId ||
            !{'制作中', '修改中', '待用户验收'}.contains(order.status) ||
            order.deliveryExtensionStatus == 'pending' ||
            dueAt == null ||
            additionalDays < 1 ||
            additionalDays > 30 ||
            normalizedReason.isEmpty ||
            operatorId.trim().isEmpty) {
          return order;
        }
        return order.copyWith(
          previousProductionDueAt: order.productionDueAt,
          proposedProductionDueAt: dueAt
              .toUtc()
              .add(Duration(days: additionalDays))
              .toIso8601String(),
          deliveryExtensionReason: normalizedReason,
          deliveryExtensionStatus: 'pending',
          deliveryExtensionNotifiedAt: now.toIso8601String(),
          deliveryExtensionResponseDueAt:
              now.add(deliveryExtensionResponseDuration).toIso8601String(),
          deliveryExtendedAt: now.toIso8601String(),
          deliveryExtendedBy: operatorId.trim(),
          deliveryExtensionVersion: order.deliveryExtensionVersion + 1,
          creatorExtensionReminderCount: 0,
          creatorExtensionAcknowledgementDueAt:
              now.add(creatorExtensionAcknowledgementSla).toIso8601String(),
        );
      }).toList(),
    );
  }

  @override
  Future<void> respondToDeliveryExtension({
    required String orderId,
    required bool accepted,
  }) async {
    final orders = await loadOrders();
    final now = DateTime.now().toUtc();
    await _saveOrders(
      orders
          .map((order) => order.id == orderId
              ? _respondToDeliveryExtension(order, accepted, now)
              : order)
          .toList(),
    );
  }

  @override
  Future<void> recordDeliveryExtensionReminder({
    required String orderId,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  }) async {
    final timestamp = (now ?? DateTime.now()).toUtc();
    if (operatorId.trim().isEmpty) return;
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map((order) => order.id == orderId &&
                  _canRecordDeliveryExtensionReminder(order, timestamp)
              ? order.copyWith(
                  deliveryExtensionReminderCount:
                      order.deliveryExtensionReminderCount + 1,
                  lastDeliveryExtensionReminderAt: timestamp.toIso8601String(),
                )
              : order)
          .toList(),
    );
  }

  @override
  Future<void> escalateDeliveryExtensionResponse({
    required String orderId,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  }) async {
    if (operatorId.trim().isEmpty) return;
    final timestamp = (now ?? DateTime.now()).toUtc();
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map((order) => order.id == orderId &&
                  _canEscalateDeliveryExtensionResponse(order, timestamp)
              ? order.copyWith(
                  deliveryExtensionStatus: 'escalated',
                  deliveryExtensionEscalatedAt: timestamp.toIso8601String(),
                  deliveryExtensionEscalatedBy: operatorId.trim(),
                  deliveryExtensionEscalationDueAt: timestamp
                      .add(deliveryExtensionEscalationSla)
                      .toIso8601String(),
                )
              : order)
          .toList(),
    );
  }

  @override
  Future<void> resolveEscalatedDeliveryExtension({
    required String orderId,
    required EscalatedExtensionResolution resolution,
    required String evidenceReference,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  }) async {
    if (operatorId.trim().isEmpty || evidenceReference.trim().isEmpty) return;
    final timestamp = (now ?? DateTime.now()).toUtc();
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map((order) => order.id == orderId
              ? _resolveEscalatedDeliveryExtension(
                  order,
                  resolution,
                  evidenceReference.trim(),
                  operatorId.trim(),
                  timestamp,
                )
              : order)
          .toList(),
    );
  }

  @override
  Future<void> acknowledgeCreatorExtensionNotice({
    required String orderId,
    required String creatorId,
    DateTime? now,
  }) async {
    final timestamp = (now ?? DateTime.now()).toUtc();
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map((order) => order.id == orderId &&
                  order.assignedCreatorId == creatorId &&
                  order.deliveryExtensionVersion > 0
              ? order.copyWith(
                  creatorExtensionAcknowledgedVersion:
                      order.deliveryExtensionVersion,
                  creatorExtensionAcknowledgedAt: timestamp.toIso8601String(),
                )
              : order)
          .toList(),
    );
  }

  @override
  Future<void> recordCreatorExtensionReminder({
    required String orderId,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  }) async {
    if (operatorId.trim().isEmpty) return;
    final timestamp = (now ?? DateTime.now()).toUtc();
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map((order) => order.id == orderId &&
                  _canRecordCreatorExtensionReminder(order, timestamp)
              ? order.copyWith(
                  creatorExtensionReminderCount:
                      order.creatorExtensionReminderCount + 1,
                  lastCreatorExtensionReminderAt: timestamp.toIso8601String(),
                )
              : order)
          .toList(),
    );
  }

  @override
  Future<void> flagCreatorCommunicationRisk({
    required String orderId,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  }) async {
    if (operatorId.trim().isEmpty) return;
    final timestamp = (now ?? DateTime.now()).toUtc();
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map((order) =>
              order.id == orderId && _canFlagCreatorCommunicationRisk(order)
                  ? order.copyWith(
                      creatorCommunicationRiskStatus: 'pending_review',
                      creatorCommunicationRiskFlaggedAt:
                          timestamp.toIso8601String(),
                      creatorCommunicationRiskFlaggedBy: operatorId.trim(),
                    )
                  : order)
          .toList(),
    );
  }

  @override
  Future<void> submitCreatorPreview({
    required String orderId,
    required String creatorId,
    required String previewReference,
  }) async {
    if (previewReference.trim().isEmpty) return;
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map(
            (order) => order.id == orderId &&
                    order.assignedCreatorId == creatorId &&
                    (order.status == '制作中' || order.status == '修改中')
                ? order.copyWith(
                    status: '待平台质检',
                    previewReference: previewReference,
                    previewVersion: order.previewVersion + 1,
                    qualityReview: const CharacterQualityReview(),
                  )
                : order,
          )
          .toList(),
    );
  }

  @override
  Future<void> submitContentQualityReview({
    required String orderId,
    required int expectedPreviewVersion,
    required CharacterQualityReview review,
  }) async {
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map((order) => order.id == orderId &&
                  order.status == '待平台质检' &&
                  order.previewVersion == expectedPreviewVersion
              ? order.copyWith(
                  status: review.canRelease
                      ? '待用户验收'
                      : review.hasFailure &&
                              (review.failureNote?.trim().isNotEmpty ?? false)
                          ? '修改中'
                          : order.status,
                  qualityReview: review,
                )
              : order)
          .toList(),
    );
  }

  @override
  Future<void> requestRevision(
    String orderId, {
    required String note,
  }) async {
    final normalizedNote = note.trim();
    if (normalizedNote.isEmpty) return;
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map(
            (order) => order.id == orderId &&
                    order.status == '待用户验收' &&
                    order.revisionsUsed < (order.includedRevisions ?? 0)
                ? order.copyWith(
                    status: '修改中',
                    revisionsUsed: order.revisionsUsed + 1,
                    revisionNotes: [...order.revisionNotes, normalizedNote],
                  )
                : order,
          )
          .toList(),
    );
  }

  @override
  Future<void> approveDelivery(String orderId) async {
    final orders = await loadOrders();
    final now = DateTime.now().toUtc();
    await _saveOrders(
      orders
          .map(
            (order) => order.id == orderId && order.status == '待用户验收'
                ? order.copyWith(
                    status: '已交付',
                    deliveredAt: now.toIso8601String(),
                    settlementStatus: '待结算',
                    payoutEligibleAt:
                        now.add(creatorPayoutHoldDuration).toIso8601String(),
                  )
                : order,
          )
          .toList(),
    );
  }

  @override
  Future<void> recordCreatorPayout({
    required String orderId,
    required String payoutReference,
    required String payoutAccountVerificationReference,
  }) async {
    if (payoutReference.trim().isEmpty ||
        payoutAccountVerificationReference.trim().isEmpty) {
      return;
    }
    final orders = await loadOrders();
    final now = DateTime.now().toUtc();
    await _saveOrders(
      orders
          .map(
            (order) => order.id == orderId &&
                    order.status == '已交付' &&
                    {'待结算', '结算失败'}.contains(order.settlementStatus) &&
                    _isPayoutEligible(order, now)
                ? order.copyWith(
                    settlementStatus: '已结算',
                    payoutReference: payoutReference,
                    payoutAccountVerificationReference:
                        payoutAccountVerificationReference,
                    payoutAttemptCount: order.payoutAttemptCount + 1,
                    settledAt: now.toIso8601String(),
                  )
                : order,
          )
          .toList(),
    );
  }

  @override
  Future<void> recordCreatorPayoutFailure({
    required String orderId,
    required String failureCode,
    required String payoutAccountVerificationReference,
  }) async {
    final code = failureCode.trim();
    final verificationReference = payoutAccountVerificationReference.trim();
    if (code.isEmpty || verificationReference.isEmpty) return;
    final orders = await loadOrders();
    final now = DateTime.now().toUtc();
    await _saveOrders(
      orders
          .map(
            (order) => order.id == orderId &&
                    order.status == '已交付' &&
                    {'待结算', '结算失败'}.contains(order.settlementStatus) &&
                    _isPayoutEligible(order, now)
                ? order.copyWith(
                    settlementStatus: '结算失败',
                    payoutAccountVerificationReference: verificationReference,
                    payoutAttemptCount: order.payoutAttemptCount + 1,
                    lastPayoutFailureCode: code,
                    lastPayoutFailedAt: now.toIso8601String(),
                  )
                : order,
          )
          .toList(),
    );
  }

  @override
  Future<void> openDispute({
    required String orderId,
    required String reason,
  }) async {
    final normalizedReason = reason.trim();
    if (normalizedReason.isEmpty) return;
    const eligibleStatuses = {'制作中', '修改中', '待用户验收', '已交付'};
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map(
            (order) => order.id == orderId &&
                    eligibleStatuses.contains(order.status) &&
                    order.settlementStatus != '已结算'
                ? order.copyWith(
                    status: '争议处理中',
                    disputePriorStatus: order.status,
                    disputeReason: normalizedReason,
                    disputeOpenedAt: DateTime.now().toUtc().toIso8601String(),
                  )
                : order,
          )
          .toList(),
    );
  }

  @override
  Future<void> resolveDispute({
    required String orderId,
    required DisputeResolution resolution,
  }) async {
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map(
            (order) => order.id == orderId && order.status == '争议处理中'
                ? order.copyWith(
                    status: resolution == DisputeResolution.refundApproved
                        ? '退款处理中'
                        : (order.disputePriorStatus ?? '制作中'),
                    disputeResolution: resolution.name,
                    settlementStatus:
                        resolution == DisputeResolution.refundApproved
                            ? '结算已冻结'
                            : order.settlementStatus,
                  )
                : order,
          )
          .toList(),
    );
  }

  @override
  Future<void> recordVerifiedRefund({
    required String orderId,
    required String refundReference,
  }) async {
    if (refundReference.trim().isEmpty) return;
    final orders = await loadOrders();
    await _saveOrders(
      orders
          .map(
            (order) => order.id == orderId && order.status == '退款处理中'
                ? order.copyWith(
                    status: '已退款',
                    refundReference: refundReference,
                    refundedAt: DateTime.now().toUtc().toIso8601String(),
                    settlementStatus: '结算已关闭',
                  )
                : order,
          )
          .toList(),
    );
  }
}

class MemoryCustomizationOrderRepository
    implements CustomizationOrderRepository {
  MemoryCustomizationOrderRepository({
    List<CustomizationOrder> initialOrders = const [],
  }) : _orders = List.of(initialOrders);

  final List<CustomizationOrder> _orders;

  @override
  Future<List<CustomizationOrder>> loadOrders() async => List.of(_orders);

  @override
  Future<void> claimOperationsOrder({
    required String orderId,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    final claimTime = (now ?? DateTime.now()).toUtc();
    if (index < 0 ||
        operatorId.trim().isEmpty ||
        (_orders[index].operationsAssigneeId != null &&
            _orders[index].operationsAssigneeId != operatorId.trim() &&
            !_isOperationsClaimExpired(_orders[index], claimTime))) {
      return;
    }
    _orders[index] = _orders[index].copyWith(
      operationsAssigneeId: operatorId.trim(),
      operationsAssignedAt: claimTime.toIso8601String(),
      operationsAssignmentExpiresAt:
          claimTime.add(operationsClaimDuration).toIso8601String(),
      operationsAuditTrail: _appendOperationsAudit(
        _orders[index].operationsAuditTrail,
        claimTime.toIso8601String(),
        _orders[index].operationsAssigneeId == null
            ? 'claimed'
            : _orders[index].operationsAssigneeId == operatorId.trim()
                ? 'reclaimed'
                : 'taken_over',
        operatorId.trim(),
      ),
    );
  }

  @override
  Future<void> releaseOperationsOrder({
    required String orderId,
    String operatorId = 'platform-operator-local',
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 || _orders[index].operationsAssigneeId != operatorId.trim()) {
      return;
    }
    _orders[index] = _orders[index].copyWith(
      clearOperationsAssignee: true,
      operationsAuditTrail: _appendOperationsAudit(
        _orders[index].operationsAuditTrail,
        DateTime.now().toUtc().toIso8601String(),
        'released',
        operatorId.trim(),
      ),
    );
  }

  @override
  Future<void> renewOperationsOrderClaim({
    required String orderId,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    final claimTime = (now ?? DateTime.now()).toUtc();
    if (index < 0 ||
        _orders[index].operationsAssigneeId != operatorId.trim() ||
        _isOperationsClaimExpired(_orders[index], claimTime)) {
      return;
    }
    _orders[index] = _orders[index].copyWith(
      operationsAssignedAt: claimTime.toIso8601String(),
      operationsAssignmentExpiresAt:
          claimTime.add(operationsClaimDuration).toIso8601String(),
      operationsAuditTrail: _appendOperationsAudit(
        _orders[index].operationsAuditTrail,
        claimTime.toIso8601String(),
        'renewed',
        operatorId.trim(),
      ),
    );
  }

  @override
  Future<bool> submitReview({
    required String characterName,
    required String sourceType,
    List<String> requestedFeatures = const [],
    String? privacyConsentVersion,
    int materialCount = 0,
    String marketRegion = 'unspecified',
    String? resubmissionOfOrderId,
    String? resubmissionReason,
  }) async {
    final normalizedMarketRegion =
        supportedCustomizationMarketRegions.contains(marketRegion)
            ? marketRegion
            : 'unspecified';
    if (resubmissionOfOrderId != null &&
        _orders.any((order) =>
            order.resubmissionOfOrderId == resubmissionOfOrderId &&
            order.status != '预审未通过' &&
            order.status != '已撤回')) {
      return false;
    }
    _orders.insert(
      0,
      CustomizationOrder(
        id: '${_orders.length + 1}',
        characterName: characterName,
        sourceType: sourceType,
        status: '免费预审中',
        marketRegion: normalizedMarketRegion,
        requestedFeatures: List.of(requestedFeatures),
        privacyConsentVersion: privacyConsentVersion,
        privacyConsentAt: privacyConsentVersion == null
            ? null
            : DateTime.now().toUtc().toIso8601String(),
        materialCount: materialCount,
        resubmissionOfOrderId: resubmissionOfOrderId,
        resubmissionReason: resubmissionReason,
      ),
    );
    return true;
  }

  @override
  Future<void> withdrawReview(String orderId) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 || _orders[index].status != '免费预审中') return;
    final order = _orders[index];
    _orders[index] = CustomizationOrder(
      id: order.id,
      characterName: order.characterName,
      sourceType: order.sourceType,
      status: '已撤回',
      marketRegion: order.marketRegion,
      requestedFeatures: order.requestedFeatures,
      privacyConsentVersion: order.privacyConsentVersion,
      privacyConsentAt: order.privacyConsentAt,
      materialCount: order.materialCount,
      resubmissionOfOrderId: order.resubmissionOfOrderId,
      resubmissionReason: order.resubmissionReason,
      materialDeletionScheduledAt: _materialDeletionDeadline(),
    );
  }

  @override
  Future<int> processDueMaterialDeletions({DateTime? now}) async {
    final effectiveNow = (now ?? DateTime.now()).toUtc();
    var deletedCount = 0;
    for (var index = 0; index < _orders.length; index += 1) {
      final order = _orders[index];
      final deadline =
          DateTime.tryParse(order.materialDeletionScheduledAt ?? '');
      if (order.materialDeletedAt != null ||
          deadline == null ||
          deadline.toUtc().isAfter(effectiveNow)) {
        continue;
      }
      _orders[index] = order.copyWith(
        materialCount: 0,
        materialDeletedAt: effectiveNow.toIso8601String(),
      );
      deletedCount += 1;
    }
    return deletedCount;
  }

  @override
  Future<bool> requestImmediateMaterialDeletion(String orderId) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 ||
        !{'预审未通过', '已撤回'}.contains(_orders[index].status) ||
        _orders[index].materialDeletedAt != null) {
      return false;
    }
    final now = DateTime.now().toUtc().toIso8601String();
    _orders[index] = _orders[index].copyWith(
      materialCount: 0,
      materialDeletionRequestedAt: now,
      materialDeletedAt: now,
    );
    return true;
  }

  @override
  Future<Map<String, dynamic>?> exportPersonalData(String orderId) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0) return null;
    return _personalDataExport(_orders[index]);
  }

  @override
  Future<bool> requestPrivacyCorrection({
    required String orderId,
    required String note,
  }) async {
    final normalized = note.trim();
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (normalized.isEmpty ||
        index < 0 ||
        _orders[index].privacyCorrectionStatus == 'pending') {
      return false;
    }
    final requestedAt = DateTime.now().toUtc();
    _orders[index] = _orders[index].copyWith(
      privacyCorrectionStatus: 'pending',
      privacyCorrectionNote: normalized,
      privacyCorrectionRequestedAt: requestedAt.toIso8601String(),
      privacyCorrectionDueAt:
          requestedAt.add(const Duration(days: 30)).toIso8601String(),
    );
    return true;
  }

  @override
  Future<void> resolvePrivacyCorrection({
    required String orderId,
    required bool approved,
    required String resolutionNote,
    String resolverId = 'platform-reviewer-local',
  }) async {
    final normalized = resolutionNote.trim();
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (normalized.isEmpty ||
        index < 0 ||
        _orders[index].privacyCorrectionStatus != 'pending') {
      return;
    }
    _orders[index] = _orders[index].copyWith(
      privacyCorrectionStatus: approved ? 'approved' : 'rejected',
      privacyCorrectionResolutionNote: normalized,
      privacyCorrectionResolverId: resolverId,
      privacyCorrectionResolvedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> resolveCreatorCommunicationRisk({
    required String orderId,
    required CreatorCommunicationRiskResolution resolution,
    required String note,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 || note.trim().isEmpty || operatorId.trim().isEmpty) return;
    _orders[index] = _resolveCreatorCommunicationRisk(
      _orders[index],
      resolution,
      note.trim(),
      operatorId.trim(),
      (now ?? DateTime.now()).toUtc(),
    );
  }

  @override
  Future<void> resolveCreatorPerformanceReview({
    required String orderId,
    required CreatorPerformanceReviewOutcome outcome,
    required String note,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 || note.trim().isEmpty || operatorId.trim().isEmpty) return;
    _orders[index] = _resolveCreatorPerformanceReview(
      _orders[index],
      outcome,
      note.trim(),
      operatorId.trim(),
      (now ?? DateTime.now()).toUtc(),
    );
  }

  @override
  Future<void> approveForCreatorMatching(
    String orderId, {
    required List<String> reviewChecks,
    String reviewerId = 'platform-reviewer-local',
    String reviewPolicyVersion = 'customization-review-v1',
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 ||
        _orders[index].status != '免费预审中' ||
        !reviewChecks.toSet().containsAll(requiredCustomizationReviewChecks)) {
      return;
    }
    _orders[index] = _orders[index].copyWith(
      status: '待创作者申请',
      reviewDecision: 'approved',
      reviewChecks: List.of(reviewChecks),
      reviewerId: reviewerId,
      reviewPolicyVersion: reviewPolicyVersion,
      reviewedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> rejectReview({
    required String orderId,
    required String reason,
    String reasonCode = 'other',
    String reviewerId = 'platform-reviewer-local',
    String reviewPolicyVersion = 'customization-review-v1',
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    final normalizedReason = reason.trim();
    if (index < 0 ||
        _orders[index].status != '免费预审中' ||
        normalizedReason.isEmpty) {
      return;
    }
    final normalizedCode = customizationReviewReasonCodes.contains(reasonCode)
        ? reasonCode
        : 'other';
    _orders[index] = _orders[index].copyWith(
      status: '预审未通过',
      reviewDecision: 'rejected',
      reviewReasonCode: normalizedCode,
      reviewNote: normalizedReason,
      reviewerId: reviewerId,
      reviewPolicyVersion: reviewPolicyVersion,
      reviewedAt: DateTime.now().toUtc().toIso8601String(),
      materialDeletionScheduledAt: _materialDeletionDeadline(),
    );
  }

  @override
  Future<void> applyForCreator({
    required String orderId,
    required String creatorId,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 ||
        _orders[index].status != '待创作者申请' ||
        _orders[index].declinedAssignedCreatorIds.contains(creatorId) ||
        _orders[index].timedOutAssignedCreatorIds.contains(creatorId)) {
      return;
    }
    _orders[index] = _orders[index].copyWith(
        applicantCreatorIds: {
      ..._orders[index].applicantCreatorIds,
      creatorId,
    }.toList());
  }

  @override
  Future<void> withdrawCreatorApplication({
    required String orderId,
    required String creatorId,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 ||
        _orders[index].status != '待创作者申请' ||
        !_orders[index].applicantCreatorIds.contains(creatorId)) {
      return;
    }
    final order = _orders[index];
    _orders[index] = order.copyWith(
      applicantCreatorIds:
          order.applicantCreatorIds.where((id) => id != creatorId).toList(),
      withdrawnApplicantCreatorIds: {
        ...order.withdrawnApplicantCreatorIds,
        creatorId,
      }.toList(),
    );
  }

  @override
  Future<void> declineAssignedTask({
    required String orderId,
    required String creatorId,
    required String reason,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    final normalizedReason = reason.trim();
    if (index < 0 || normalizedReason.isEmpty) return;
    final order = _orders[index];
    if (order.status != '创作者评估中' || order.assignedCreatorId != creatorId) {
      return;
    }
    _orders[index] = order.copyWith(
      status: '待创作者申请',
      clearAssignedCreator: true,
      applicantCreatorIds:
          order.applicantCreatorIds.where((id) => id != creatorId).toList(),
      declinedAssignedCreatorIds: {
        ...order.declinedAssignedCreatorIds,
        creatorId,
      }.toList(),
      lastCreatorDeclineReason: normalizedReason,
      lastCreatorDeclinedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> assignCreator({
    required String orderId,
    required String creatorId,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 ||
        _orders[index].status != '待创作者申请' ||
        !_orders[index].applicantCreatorIds.contains(creatorId)) {
      return;
    }
    _orders[index] = _orders[index].copyWith(
      status: '创作者评估中',
      assignedCreatorId: creatorId,
      assignmentResponseDueAt: DateTime.now()
          .toUtc()
          .add(creatorAssignmentResponseDuration)
          .toIso8601String(),
    );
  }

  @override
  Future<int> processExpiredCreatorAssignments({DateTime? now}) async {
    final cutoff = (now ?? DateTime.now()).toUtc();
    var count = 0;
    for (var index = 0; index < _orders.length; index += 1) {
      final order = _orders[index];
      final dueAt = DateTime.tryParse(order.assignmentResponseDueAt ?? '');
      if (order.status != '创作者评估中' ||
          order.assignedCreatorId == null ||
          dueAt == null ||
          cutoff.isBefore(dueAt.toUtc())) {
        continue;
      }
      final creatorId = order.assignedCreatorId!;
      _orders[index] = order.copyWith(
        status: '待创作者申请',
        clearAssignedCreator: true,
        applicantCreatorIds:
            order.applicantCreatorIds.where((id) => id != creatorId).toList(),
        timedOutAssignedCreatorIds: {
          ...order.timedOutAssignedCreatorIds,
          creatorId,
        }.toList(),
        lastAssignmentTimedOutAt: cutoff.toIso8601String(),
      );
      count += 1;
    }
    return count;
  }

  @Deprecated('Platform flows should call applyForCreator then assignCreator.')
  Future<void> claimForCreator({
    required String orderId,
    required String creatorId,
  }) async {
    await applyForCreator(orderId: orderId, creatorId: creatorId);
    await assignCreator(orderId: orderId, creatorId: creatorId);
  }

  @override
  Future<void> submitCreatorProposal({
    required String orderId,
    required String creatorId,
    required int suggestedAmountCents,
    String creatorMarketRegion = 'other',
    required int estimatedDeliveryDays,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 ||
        _orders[index].status != '创作者评估中' ||
        _orders[index].assignedCreatorId != creatorId ||
        suggestedAmountCents <= 0 ||
        estimatedDeliveryDays <= 0) {
      return;
    }
    _orders[index] = _orders[index].copyWith(
      status: '平台审核报价',
      creatorSuggestedAmountCents: suggestedAmountCents,
      creatorSuggestedCurrency:
          creatorSettlementCurrencyForRegion(creatorMarketRegion),
      estimatedDeliveryDays: estimatedDeliveryDays,
    );
  }

  @override
  Future<void> publishPlatformQuote({
    required String orderId,
    required int amountCents,
    required String currency,
    String taxTreatment = 'calculated_at_checkout',
    String? currencyOverrideReason,
    required int includedRevisions,
    required int estimatedDeliveryDays,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 ||
        _orders[index].status != '平台审核报价' ||
        (currency !=
                defaultCurrencyForMarketRegion(_orders[index].marketRegion) &&
            !(currencyOverrideReason?.trim().isNotEmpty ?? false)) ||
        amountCents <= 0 ||
        includedRevisions < 0 ||
        estimatedDeliveryDays <= 0) {
      return;
    }
    final normalizedTaxTreatment =
        customizationQuoteTaxTreatments.contains(taxTreatment)
            ? taxTreatment
            : 'calculated_at_checkout';
    _orders[index] = _orders[index].copyWith(
      status: '待确认报价',
      quoteAmountCents: amountCents,
      quoteCurrency: currency,
      quoteTaxTreatment: normalizedTaxTreatment,
      quoteCurrencyOverrideReason: currencyOverrideReason?.trim(),
      includedRevisions: includedRevisions,
      estimatedDeliveryDays: estimatedDeliveryDays,
      creatorPayoutCents: _orders[index].creatorSuggestedAmountCents,
      creatorPayoutCurrency: _orders[index].creatorSuggestedCurrency ?? 'USD',
    );
  }

  @override
  Future<void> acceptQuote(String orderId) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 || _orders[index].status != '待确认报价') return;
    _orders[index] = _orders[index].copyWith(status: '待支付');
  }

  @override
  Future<void> declineQuote(String orderId) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 ||
        (_orders[index].status != '待确认报价' && _orders[index].status != '待支付')) {
      return;
    }
    _orders[index] = _orders[index].copyWith(status: '已拒绝报价');
  }

  @override
  Future<void> recordVerifiedPayment({
    required String orderId,
    required String paymentReference,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 ||
        _orders[index].status != '待支付' ||
        paymentReference.trim().isEmpty) {
      return;
    }
    final now = DateTime.now().toUtc();
    _orders[index] = _orders[index].copyWith(
      status: '制作中',
      paymentReference: paymentReference,
      paidAt: now.toIso8601String(),
      productionDueAt: now
          .add(Duration(days: _orders[index].estimatedDeliveryDays ?? 7))
          .toIso8601String(),
      settlementStatus: '平台托管中',
    );
  }

  @override
  Future<void> extendProductionDeadline({
    required String orderId,
    required int additionalDays,
    required String reason,
    String operatorId = 'platform-operator-local',
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    final normalizedReason = reason.trim();
    if (index < 0 ||
        !{'制作中', '修改中', '待用户验收'}.contains(_orders[index].status) ||
        _orders[index].deliveryExtensionStatus == 'pending' ||
        additionalDays < 1 ||
        additionalDays > 30 ||
        normalizedReason.isEmpty ||
        operatorId.trim().isEmpty) {
      return;
    }
    final order = _orders[index];
    final dueAt = DateTime.tryParse(order.productionDueAt ?? '');
    if (dueAt == null) return;
    final now = DateTime.now().toUtc();
    _orders[index] = order.copyWith(
      previousProductionDueAt: order.productionDueAt,
      proposedProductionDueAt:
          dueAt.toUtc().add(Duration(days: additionalDays)).toIso8601String(),
      deliveryExtensionReason: normalizedReason,
      deliveryExtensionStatus: 'pending',
      deliveryExtensionNotifiedAt: now.toIso8601String(),
      deliveryExtensionResponseDueAt:
          now.add(deliveryExtensionResponseDuration).toIso8601String(),
      deliveryExtendedAt: now.toIso8601String(),
      deliveryExtendedBy: operatorId.trim(),
      deliveryExtensionVersion: order.deliveryExtensionVersion + 1,
      creatorExtensionReminderCount: 0,
      creatorExtensionAcknowledgementDueAt:
          now.add(creatorExtensionAcknowledgementSla).toIso8601String(),
    );
  }

  @override
  Future<void> respondToDeliveryExtension({
    required String orderId,
    required bool accepted,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0) return;
    _orders[index] = _respondToDeliveryExtension(
      _orders[index],
      accepted,
      DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> recordDeliveryExtensionReminder({
    required String orderId,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    final timestamp = (now ?? DateTime.now()).toUtc();
    if (index < 0 ||
        operatorId.trim().isEmpty ||
        !_canRecordDeliveryExtensionReminder(_orders[index], timestamp)) {
      return;
    }
    final order = _orders[index];
    _orders[index] = order.copyWith(
      deliveryExtensionReminderCount: order.deliveryExtensionReminderCount + 1,
      lastDeliveryExtensionReminderAt: timestamp.toIso8601String(),
    );
  }

  @override
  Future<void> escalateDeliveryExtensionResponse({
    required String orderId,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    final timestamp = (now ?? DateTime.now()).toUtc();
    if (index < 0 ||
        operatorId.trim().isEmpty ||
        !_canEscalateDeliveryExtensionResponse(_orders[index], timestamp)) {
      return;
    }
    _orders[index] = _orders[index].copyWith(
      deliveryExtensionStatus: 'escalated',
      deliveryExtensionEscalatedAt: timestamp.toIso8601String(),
      deliveryExtensionEscalatedBy: operatorId.trim(),
      deliveryExtensionEscalationDueAt:
          timestamp.add(deliveryExtensionEscalationSla).toIso8601String(),
    );
  }

  @override
  Future<void> resolveEscalatedDeliveryExtension({
    required String orderId,
    required EscalatedExtensionResolution resolution,
    required String evidenceReference,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 ||
        operatorId.trim().isEmpty ||
        evidenceReference.trim().isEmpty) {
      return;
    }
    _orders[index] = _resolveEscalatedDeliveryExtension(
      _orders[index],
      resolution,
      evidenceReference.trim(),
      operatorId.trim(),
      (now ?? DateTime.now()).toUtc(),
    );
  }

  @override
  Future<void> acknowledgeCreatorExtensionNotice({
    required String orderId,
    required String creatorId,
    DateTime? now,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 ||
        _orders[index].assignedCreatorId != creatorId ||
        _orders[index].deliveryExtensionVersion < 1) {
      return;
    }
    final order = _orders[index];
    _orders[index] = order.copyWith(
      creatorExtensionAcknowledgedVersion: order.deliveryExtensionVersion,
      creatorExtensionAcknowledgedAt:
          (now ?? DateTime.now()).toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> recordCreatorExtensionReminder({
    required String orderId,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    final timestamp = (now ?? DateTime.now()).toUtc();
    if (index < 0 ||
        operatorId.trim().isEmpty ||
        !_canRecordCreatorExtensionReminder(_orders[index], timestamp)) {
      return;
    }
    final order = _orders[index];
    _orders[index] = order.copyWith(
      creatorExtensionReminderCount: order.creatorExtensionReminderCount + 1,
      lastCreatorExtensionReminderAt: timestamp.toIso8601String(),
    );
  }

  @override
  Future<void> flagCreatorCommunicationRisk({
    required String orderId,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 ||
        operatorId.trim().isEmpty ||
        !_canFlagCreatorCommunicationRisk(_orders[index])) {
      return;
    }
    _orders[index] = _orders[index].copyWith(
      creatorCommunicationRiskStatus: 'pending_review',
      creatorCommunicationRiskFlaggedAt:
          (now ?? DateTime.now()).toUtc().toIso8601String(),
      creatorCommunicationRiskFlaggedBy: operatorId.trim(),
    );
  }

  @override
  Future<void> submitCreatorPreview({
    required String orderId,
    required String creatorId,
    required String previewReference,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 ||
        _orders[index].assignedCreatorId != creatorId ||
        (_orders[index].status != '制作中' && _orders[index].status != '修改中') ||
        previewReference.trim().isEmpty) {
      return;
    }
    final order = _orders[index];
    _orders[index] = order.copyWith(
      status: '待平台质检',
      previewReference: previewReference,
      previewVersion: order.previewVersion + 1,
      qualityReview: const CharacterQualityReview(),
    );
  }

  @override
  Future<void> submitContentQualityReview({
    required String orderId,
    required int expectedPreviewVersion,
    required CharacterQualityReview review,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 ||
        _orders[index].status != '待平台质检' ||
        _orders[index].previewVersion != expectedPreviewVersion) {
      return;
    }
    final status = review.canRelease
        ? '待用户验收'
        : review.hasFailure && (review.failureNote?.trim().isNotEmpty ?? false)
            ? '修改中'
            : _orders[index].status;
    _orders[index] = _orders[index].copyWith(
      status: status,
      qualityReview: review,
    );
  }

  @override
  Future<void> requestRevision(
    String orderId, {
    required String note,
  }) async {
    final normalizedNote = note.trim();
    if (normalizedNote.isEmpty) return;
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0) return;
    final order = _orders[index];
    if (order.status != '待用户验收' ||
        order.revisionsUsed >= (order.includedRevisions ?? 0)) {
      return;
    }
    _orders[index] = order.copyWith(
      status: '修改中',
      revisionsUsed: order.revisionsUsed + 1,
      revisionNotes: [...order.revisionNotes, normalizedNote],
    );
  }

  @override
  Future<void> approveDelivery(String orderId) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 || _orders[index].status != '待用户验收') return;
    final now = DateTime.now().toUtc();
    _orders[index] = _orders[index].copyWith(
      status: '已交付',
      deliveredAt: now.toIso8601String(),
      settlementStatus: '待结算',
      payoutEligibleAt: now.add(creatorPayoutHoldDuration).toIso8601String(),
    );
  }

  @override
  Future<void> recordCreatorPayout({
    required String orderId,
    required String payoutReference,
    required String payoutAccountVerificationReference,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 ||
        _orders[index].status != '已交付' ||
        !{'待结算', '结算失败'}.contains(_orders[index].settlementStatus) ||
        !_isPayoutEligible(_orders[index], DateTime.now().toUtc()) ||
        payoutReference.trim().isEmpty ||
        payoutAccountVerificationReference.trim().isEmpty) {
      return;
    }
    _orders[index] = _orders[index].copyWith(
      settlementStatus: '已结算',
      payoutReference: payoutReference,
      payoutAccountVerificationReference: payoutAccountVerificationReference,
      payoutAttemptCount: _orders[index].payoutAttemptCount + 1,
      settledAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> recordCreatorPayoutFailure({
    required String orderId,
    required String failureCode,
    required String payoutAccountVerificationReference,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    final code = failureCode.trim();
    final verificationReference = payoutAccountVerificationReference.trim();
    if (index < 0 || code.isEmpty || verificationReference.isEmpty) return;
    final order = _orders[index];
    final now = DateTime.now().toUtc();
    if (order.status != '已交付' ||
        !{'待结算', '结算失败'}.contains(order.settlementStatus) ||
        !_isPayoutEligible(order, now)) {
      return;
    }
    _orders[index] = order.copyWith(
      settlementStatus: '结算失败',
      payoutAccountVerificationReference: verificationReference,
      payoutAttemptCount: order.payoutAttemptCount + 1,
      lastPayoutFailureCode: code,
      lastPayoutFailedAt: now.toIso8601String(),
    );
  }

  @override
  Future<void> openDispute({
    required String orderId,
    required String reason,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 || reason.trim().isEmpty) return;
    final order = _orders[index];
    const eligibleStatuses = {'制作中', '修改中', '待用户验收', '已交付'};
    if (!eligibleStatuses.contains(order.status) ||
        order.settlementStatus == '已结算') {
      return;
    }
    _orders[index] = order.copyWith(
      status: '争议处理中',
      disputePriorStatus: order.status,
      disputeReason: reason.trim(),
      disputeOpenedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> resolveDispute({
    required String orderId,
    required DisputeResolution resolution,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 || _orders[index].status != '争议处理中') return;
    final order = _orders[index];
    _orders[index] = order.copyWith(
      status: resolution == DisputeResolution.refundApproved
          ? '退款处理中'
          : (order.disputePriorStatus ?? '制作中'),
      disputeResolution: resolution.name,
      settlementStatus: resolution == DisputeResolution.refundApproved
          ? '结算已冻结'
          : order.settlementStatus,
    );
  }

  @override
  Future<void> recordVerifiedRefund({
    required String orderId,
    required String refundReference,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 ||
        _orders[index].status != '退款处理中' ||
        refundReference.trim().isEmpty) {
      return;
    }
    _orders[index] = _orders[index].copyWith(
      status: '已退款',
      refundReference: refundReference,
      refundedAt: DateTime.now().toUtc().toIso8601String(),
      settlementStatus: '结算已关闭',
    );
  }
}

bool _isPayoutEligible(CustomizationOrder order, DateTime now) {
  final eligibleAt = DateTime.tryParse(order.payoutEligibleAt ?? '');
  return eligibleAt != null && !now.isBefore(eligibleAt);
}

bool _isDeliveryExtensionResponseOverdue(
  CustomizationOrder order,
  DateTime now,
) {
  final dueAt = DateTime.tryParse(order.deliveryExtensionResponseDueAt ?? '');
  return order.deliveryExtensionStatus == 'pending' &&
      dueAt != null &&
      !now.toUtc().isBefore(dueAt.toUtc());
}

bool _canRecordDeliveryExtensionReminder(
  CustomizationOrder order,
  DateTime now,
) {
  if (!_isDeliveryExtensionResponseOverdue(order, now) ||
      order.deliveryExtensionReminderCount >=
          maximumDeliveryExtensionReminders) {
    return false;
  }
  final lastReminder =
      DateTime.tryParse(order.lastDeliveryExtensionReminderAt ?? '');
  return lastReminder == null ||
      !now.toUtc().isBefore(
            lastReminder.toUtc().add(deliveryExtensionReminderCooldown),
          );
}

bool _canEscalateDeliveryExtensionResponse(
  CustomizationOrder order,
  DateTime now,
) {
  return _isDeliveryExtensionResponseOverdue(order, now) &&
      order.deliveryExtensionReminderCount >= maximumDeliveryExtensionReminders;
}

bool _canRecordCreatorExtensionReminder(
  CustomizationOrder order,
  DateTime now,
) {
  final dueAt =
      DateTime.tryParse(order.creatorExtensionAcknowledgementDueAt ?? '');
  if (order.deliveryExtensionVersion <=
          order.creatorExtensionAcknowledgedVersion ||
      dueAt == null ||
      now.toUtc().isBefore(dueAt.toUtc()) ||
      order.creatorExtensionReminderCount >= maximumCreatorExtensionReminders) {
    return false;
  }
  final lastReminder =
      DateTime.tryParse(order.lastCreatorExtensionReminderAt ?? '');
  return lastReminder == null ||
      !now.toUtc().isBefore(
            lastReminder.toUtc().add(creatorExtensionReminderCooldown),
          );
}

bool _canFlagCreatorCommunicationRisk(CustomizationOrder order) =>
    order.deliveryExtensionVersion >
        order.creatorExtensionAcknowledgedVersion &&
    order.creatorExtensionReminderCount >= maximumCreatorExtensionReminders &&
    order.creatorCommunicationRiskStatus == null;

List<String> _appendOperationsAudit(
  List<String> current,
  String timestamp,
  String action,
  String operatorId,
) {
  final updated = [
    ...current,
    '$timestamp|$action|${Uri.encodeComponent(operatorId)}',
  ];
  const maximumEntries = 100;
  return updated.length <= maximumEntries
      ? updated
      : updated.sublist(updated.length - maximumEntries);
}

bool _isOperationsClaimExpired(CustomizationOrder order, DateTime now) {
  final expiresAt =
      DateTime.tryParse(order.operationsAssignmentExpiresAt ?? '');
  return order.operationsAssigneeId != null &&
      (expiresAt == null || !now.toUtc().isBefore(expiresAt.toUtc()));
}

CustomizationOrder _resolveCreatorCommunicationRisk(
  CustomizationOrder order,
  CreatorCommunicationRiskResolution resolution,
  String note,
  String operatorId,
  DateTime now,
) {
  if (order.creatorCommunicationRiskStatus != 'pending_review') return order;
  final performanceReview =
      resolution == CreatorCommunicationRiskResolution.performanceReview;
  return order.copyWith(
    creatorCommunicationRiskStatus:
        performanceReview ? 'performance_review' : 'resolved',
    creatorCommunicationRiskResolution: resolution.name,
    creatorCommunicationRiskResolutionNote: note,
    creatorCommunicationRiskResolvedAt: now.toIso8601String(),
    creatorCommunicationRiskResolvedBy: operatorId,
    settlementStatus: performanceReview ? '结算已冻结' : order.settlementStatus,
  );
}

CustomizationOrder _resolveCreatorPerformanceReview(
  CustomizationOrder order,
  CreatorPerformanceReviewOutcome outcome,
  String note,
  String operatorId,
  DateTime now,
) {
  if (order.creatorCommunicationRiskStatus != 'performance_review') {
    return order;
  }
  final dispute = outcome == CreatorPerformanceReviewOutcome.openOrderDispute;
  return order.copyWith(
    creatorCommunicationRiskStatus: 'resolved',
    creatorPerformanceReviewOutcome: outcome.name,
    creatorPerformanceReviewNote: note,
    creatorPerformanceReviewResolvedAt: now.toIso8601String(),
    creatorPerformanceReviewResolvedBy: operatorId,
    status: dispute ? '争议处理中' : order.status,
    disputePriorStatus: dispute ? order.status : order.disputePriorStatus,
    disputeReason: dispute ? '创作者履约风险审查升级' : order.disputeReason,
    disputeOpenedAt: dispute ? now.toIso8601String() : order.disputeOpenedAt,
    settlementStatus: dispute ? '结算已冻结' : '平台托管中',
  );
}

CustomizationOrder _resolveEscalatedDeliveryExtension(
  CustomizationOrder order,
  EscalatedExtensionResolution resolution,
  String evidenceReference,
  String operatorId,
  DateTime now,
) {
  if (order.deliveryExtensionStatus != 'escalated') return order;
  final accepted = resolution == EscalatedExtensionResolution.userAccepted;
  final declined = resolution == EscalatedExtensionResolution.userDeclined;
  if (accepted &&
      (order.proposedProductionDueAt == null ||
          order.deliveryExtensionEscalatedBy == operatorId)) {
    return order;
  }
  return order.copyWith(
    productionDueAt:
        accepted ? order.proposedProductionDueAt : order.productionDueAt,
    deliveryExtensionStatus: switch (resolution) {
      EscalatedExtensionResolution.userAccepted => 'accepted',
      EscalatedExtensionResolution.userDeclined => 'declined',
      EscalatedExtensionResolution.proposalWithdrawn => 'withdrawn',
    },
    deliveryExtensionRespondedAt: now.toIso8601String(),
    deliveryExtensionResolutionEvidence: evidenceReference,
    deliveryExtensionResolvedBy: operatorId,
    status: declined ? '争议处理中' : order.status,
    disputePriorStatus: declined ? order.status : order.disputePriorStatus,
    disputeReason: declined ? '人工联系后用户拒绝交付延期' : order.disputeReason,
    disputeOpenedAt: declined ? now.toIso8601String() : order.disputeOpenedAt,
    settlementStatus: declined ? '结算已冻结' : order.settlementStatus,
  );
}

CustomizationOrder _respondToDeliveryExtension(
  CustomizationOrder order,
  bool accepted,
  DateTime now,
) {
  if (order.deliveryExtensionStatus != 'pending' ||
      order.proposedProductionDueAt == null ||
      !{'制作中', '修改中', '待用户验收'}.contains(order.status)) {
    return order;
  }
  return order.copyWith(
    productionDueAt:
        accepted ? order.proposedProductionDueAt : order.productionDueAt,
    deliveryExtensionStatus: accepted ? 'accepted' : 'declined',
    deliveryExtensionRespondedAt: now.toIso8601String(),
    deliveryExtensionResolutionEvidence:
        accepted ? 'in_app_explicit_acceptance' : 'in_app_explicit_decline',
    deliveryExtensionResolvedBy: 'user-self-service',
    status: accepted ? order.status : '争议处理中',
    disputePriorStatus: accepted ? order.disputePriorStatus : order.status,
    disputeReason: accepted ? order.disputeReason : '用户拒绝平台提出的交付延期',
    disputeOpenedAt: accepted ? order.disputeOpenedAt : now.toIso8601String(),
    settlementStatus: accepted ? order.settlementStatus : '结算已冻结',
  );
}
