import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_entitlement_repository.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_quality_review.dart';
import 'package:hildors_cockpit/src/features/customization/customization_page.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';
import 'package:hildors_cockpit/src/features/customization/customization_refund_service.dart';
import 'package:hildors_cockpit/src/features/customization/creator_profile_repository.dart';

class _RacingOperationsRepository extends MemoryCustomizationOrderRepository {
  _RacingOperationsRepository({required super.initialOrders});

  @override
  Future<void> claimOperationsOrder({
    required String orderId,
    String operatorId = 'platform-operator-local',
    DateTime? now,
  }) =>
      super.claimOperationsOrder(
        orderId: orderId,
        operatorId: 'competing-operator',
        now: now,
      );
}

void main() {
  Widget buildSubject() => const MaterialApp(home: CustomizationPage());

  Future<void> assignCreator(
    MemoryCustomizationOrderRepository orders,
    String orderId,
    String creatorId,
  ) async {
    await orders.applyForCreator(orderId: orderId, creatorId: creatorId);
    await orders.assignCreator(orderId: orderId, creatorId: creatorId);
  }

  Future<void> approveReview(
    MemoryCustomizationOrderRepository orders,
    String orderId,
  ) =>
      orders.approveForCreatorMatching(
        orderId,
        reviewChecks: requiredCustomizationReviewChecks.toList(),
      );

  Future<void> passQualityReview(
    MemoryCustomizationOrderRepository orders,
    String orderId,
  ) async =>
      orders.submitContentQualityReview(
        orderId: orderId,
        expectedPreviewVersion: (await orders.loadOrders())
            .singleWhere((order) => order.id == orderId)
            .previewVersion,
        review: CharacterQualityReview(
          results: {
            for (final check in requiredCharacterQualityChecks)
              check: CharacterQualityCheckResult.passed,
          },
          reviewerId: 'quality-reviewer-local',
          deviceModel: 'P20',
          packageVersion: '1.0.0',
          reviewedAt: '2026-09-10T10:00:00Z',
        ),
      );

  testWidgets('separates free characters, paid commissions, and wishes',
      (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('角色之门'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('免费原创角色'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('免费原创角色'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('定制你的专属角色'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('定制你的专属角色'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('许愿一个角色'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('许愿一个角色'), findsOneWidget);
  });

  testWidgets('opens free character library and claims prototype character',
      (tester) async {
    final repository = MemoryCharacterEntitlementRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: FreeOriginalCharactersPage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Celestial Mage'), findsOneWidget);

    await tester.tap(find.text('Celestial Mage'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('Claim for free'), findsOneWidget);

    await tester.tap(find.text('Claim for free'));
    await tester.pumpAndSettle();
    expect(find.text('Added to collection'), findsOneWidget);
    expect(
        find.textContaining('Cloud account entitlements are not connected yet'),
        findsOneWidget);
    expect(
        await repository.loadClaimedCharacterIds(), contains('celestial-mage'));

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Added to collection'), findsOneWidget);
  });

  test('claiming the same free character remains idempotent', () async {
    final repository = MemoryCharacterEntitlementRepository();

    await repository.claim('celestial-mage');
    await repository.claim('celestial-mage');

    expect(await repository.loadClaimedCharacterIds(), {'celestial-mage'});
  });

  testWidgets('shows package videos without fabricating device delivery',
      (tester) async {
    final repository = MemoryCharacterEntitlementRepository([
      'celestial-mage',
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: CustomizationPage(
          repository: repository,
          orderRepository: MemoryCustomizationOrderRepository(),
        ),
      ),
    );

    await tester.tap(find.text('我的角色'));
    await tester.pumpAndSettle();
    expect(find.text('Celestial Mage'), findsOneWidget);
    expect(find.text('查看包内视频'), findsOneWidget);

    await tester.tap(find.text('查看包内视频'));
    await tester.pumpAndSettle();

    expect(find.text('此角色暂未提供可用视频，待内容包交付后选择。'), findsOneWidget);
    expect(
      await repository.loadDeviceCharacterIds(),
      isEmpty,
    );
  });

  test('an unclaimed character cannot be sent to a device', () async {
    final repository = MemoryCharacterEntitlementRepository();

    await repository.sendToDevice('celestial-mage');

    expect(await repository.loadDeviceCharacterIds(), isEmpty);
  });

  test('order persistence excludes local material names and paths', () {
    final migrated = CustomizationOrder.fromJson({
      'id': 'legacy-1',
      'characterName': '星际狐狸',
      'sourceType': '原创角色',
      'status': '免费预审中',
      'materialFileNames': ['Alice-front.png', 'Alice-side.png'],
    });

    expect(migrated?.materialCount, 2);
    expect(migrated?.toJson().containsKey('materialFileNames'), isFalse);
    expect(migrated?.toJson()['materialCount'], 2);
  });

  test('platform quote requires explicit acceptance before payment', () async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(characterName: '星际狐狸', sourceType: '原创角色');
    final id = (await orders.loadOrders()).single.id;

    await approveReview(orders, id);
    await assignCreator(orders, id, 'local-certified-creator');
    await orders.submitCreatorProposal(
      orderId: id,
      creatorId: 'local-certified-creator',
      suggestedAmountCents: 11000,
      estimatedDeliveryDays: 10,
    );

    await orders.publishPlatformQuote(
      orderId: id,
      amountCents: 12900,
      currency: 'USD',
      includedRevisions: 2,
      estimatedDeliveryDays: 10,
    );
    var order = (await orders.loadOrders()).single;
    expect(order.status, '待确认报价');
    expect(order.quoteAmountCents, 12900);

    await orders.acceptQuote(id);
    order = (await orders.loadOrders()).single;
    expect(order.status, '待支付');

    await orders.recordVerifiedPayment(
      orderId: id,
      paymentReference: 'provider-event-1',
    );
    order = (await orders.loadOrders()).single;
    expect(order.status, '制作中');
    expect(order.paymentReference, 'provider-event-1');
    expect(order.paidAt, isNotNull);
    expect(order.productionDueAt, isNotNull);

    await orders.submitCreatorPreview(
      orderId: id,
      creatorId: 'local-certified-creator',
      previewReference: 'protected-preview-v1',
    );
    order = (await orders.loadOrders()).single;
    expect(order.status, '待平台质检');
    await passQualityReview(orders, id);
    order = (await orders.loadOrders()).single;
    expect(order.status, '待用户验收');
    expect(order.previewVersion, 1);

    await orders.requestRevision(id, note: '   ');
    order = (await orders.loadOrders()).single;
    expect(order.status, '待用户验收');
    expect(order.revisionsUsed, 0);

    await orders.requestRevision(id, note: '请调整手部动作');
    order = (await orders.loadOrders()).single;
    expect(order.status, '修改中');
    expect(order.revisionsUsed, 1);
    expect(order.revisionNotes, ['请调整手部动作']);

    await orders.submitCreatorPreview(
      orderId: id,
      creatorId: 'local-certified-creator',
      previewReference: 'protected-preview-v2',
    );
    await passQualityReview(orders, id);
    await orders.approveDelivery(id);
    order = (await orders.loadOrders()).single;
    expect(order.status, '已交付');
    expect(order.previewVersion, 2);
    expect(order.deliveredAt, isNotNull);
    expect(order.creatorPayoutCents, 11000);
    expect(order.settlementStatus, '待结算');
    expect(order.payoutEligibleAt, isNotNull);

    await orders.openDispute(orderId: id, reason: '交付动作与报价范围不一致');
    order = (await orders.loadOrders()).single;
    expect(order.status, '争议处理中');
    expect(order.disputePriorStatus, '已交付');
    expect(order.disputeOpenedAt, isNotNull);

    await orders.recordCreatorPayout(
      orderId: id,
      payoutReference: 'blocked-payout',
      payoutAccountVerificationReference: 'verified-account-1',
    );
    expect((await orders.loadOrders()).single.payoutReference, isNull);

    await orders.resolveDispute(
      orderId: id,
      resolution: DisputeResolution.resumeOrder,
    );
    order = (await orders.loadOrders()).single;
    expect(order.status, '已交付');

    await orders.recordCreatorPayout(
      orderId: id,
      payoutReference: 'held-payout',
      payoutAccountVerificationReference: 'verified-account-1',
    );
    order = (await orders.loadOrders()).single;
    expect(order.settlementStatus, '待结算');
    expect(order.payoutReference, isNull);
  });

  test('payment cannot be recorded before quote acceptance', () async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(characterName: '星际狐狸', sourceType: '原创角色');
    final id = (await orders.loadOrders()).single.id;

    await orders.recordVerifiedPayment(
      orderId: id,
      paymentReference: 'untrusted-client-event',
    );

    final order = (await orders.loadOrders()).single;
    expect(order.status, '免费预审中');
    expect(order.paymentReference, isNull);
  });

  test('creator payout cannot be recorded before delivery', () async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(characterName: '星际狐狸', sourceType: '原创角色');
    final id = (await orders.loadOrders()).single.id;

    await orders.recordCreatorPayout(
      orderId: id,
      payoutReference: 'premature-payout',
      payoutAccountVerificationReference: 'verified-account-1',
    );

    final order = (await orders.loadOrders()).single;
    expect(order.settlementStatus, isNull);
    expect(order.payoutReference, isNull);
  });

  test('creator payout requires a verified payout account reference', () async {
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'awaiting-payout',
          characterName: '星际狐狸',
          sourceType: '原创角色',
          status: '已交付',
          settlementStatus: '待结算',
          creatorPayoutCents: 11000,
          creatorPayoutCurrency: 'USD',
          payoutEligibleAt: '2020-01-01T00:00:00Z',
        ),
      ],
    );

    await orders.recordCreatorPayout(
      orderId: 'awaiting-payout',
      payoutReference: 'payout-without-verified-account',
      payoutAccountVerificationReference: '',
    );

    final order = (await orders.loadOrders()).single;
    expect(order.settlementStatus, '待结算');
    expect(order.payoutReference, isNull);
    expect(order.settledAt, isNull);
  });

  test('creator payout succeeds after the hold period', () async {
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'eligible-payout',
          characterName: '星际狐狸',
          sourceType: '原创角色',
          status: '已交付',
          settlementStatus: '待结算',
          creatorPayoutCents: 11000,
          creatorPayoutCurrency: 'USD',
          payoutEligibleAt: '2020-01-01T00:00:00Z',
        ),
      ],
    );

    await orders.recordCreatorPayoutFailure(
      orderId: 'eligible-payout',
      failureCode: 'account_temporarily_unavailable',
      payoutAccountVerificationReference: 'verified-account-1',
    );
    var order = (await orders.loadOrders()).single;
    expect(order.settlementStatus, '结算失败');
    expect(order.payoutAttemptCount, 1);
    expect(order.lastPayoutFailureCode, 'account_temporarily_unavailable');
    expect(order.lastPayoutFailedAt, isNotNull);

    await orders.recordCreatorPayout(
      orderId: 'eligible-payout',
      payoutReference: 'payout-1',
      payoutAccountVerificationReference: 'verified-account-1',
    );

    order = (await orders.loadOrders()).single;
    expect(order.settlementStatus, '已结算');
    expect(order.payoutAttemptCount, 2);
    expect(order.payoutReference, 'payout-1');
    expect(
      order.payoutAccountVerificationReference,
      'verified-account-1',
    );
    expect(order.settledAt, isNotNull);
  });

  testWidgets('platform operations can record a payout failure',
      (tester) async {
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'operations-payout',
          characterName: '月光骑士',
          sourceType: '原创角色',
          status: '已交付',
          settlementStatus: '待结算',
          creatorPayoutCents: 8800,
          creatorPayoutCurrency: 'USD',
          payoutEligibleAt: '2020-01-01T00:00:00Z',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: PlatformOperationsPage(repository: orders)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('月光骑士'));
    await tester.pumpAndSettle();

    expect(find.text('创作者结算处理'), findsOneWidget);
    expect(find.text('应付：USD 88.00'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('payout-account-verification')),
      'verified-account-2',
    );
    await tester.pump();
    await tester.tap(find.text('登记本次放款失败'));
    await tester.pumpAndSettle();

    final order = (await orders.loadOrders()).single;
    expect(order.settlementStatus, '结算失败');
    expect(order.lastPayoutFailureCode, 'account_unavailable');
    expect(find.text('结算失败 1'), findsOneWidget);
  });

  testWidgets('overdue production appears in platform operations queue',
      (tester) async {
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'overdue-production',
          characterName: '逾期制作任务',
          sourceType: '原创角色',
          status: '制作中',
          productionDueAt: '2020-01-01T00:00:00Z',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: PlatformOperationsPage(repository: orders)),
    );
    await tester.pumpAndSettle();

    expect(find.text('交付逾期 1'), findsOneWidget);
    expect(find.text('制作交付已逾期'), findsOneWidget);
    await tester.tap(find.text('逾期制作任务'));
    await tester.pumpAndSettle();
    expect(find.text('交付逾期处理'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('delivery-extension-days')),
      '5',
    );
    await tester.enterText(
      find.byKey(const Key('delivery-extension-reason')),
      '渲染资源异常，已安排加急处理',
    );
    await tester.pump();
    await tester.tap(find.text('确认延期并通知用户'));
    await tester.pumpAndSettle();

    final updated = (await orders.loadOrders()).single;
    expect(updated.previousProductionDueAt, '2020-01-01T00:00:00Z');
    expect(updated.productionDueAt, '2020-01-01T00:00:00Z');
    expect(updated.proposedProductionDueAt, '2020-01-06T00:00:00.000Z');
    expect(updated.deliveryExtensionStatus, 'pending');
    expect(updated.deliveryExtensionNotifiedAt, isNotNull);
    expect(updated.deliveryExtensionResponseDueAt, isNotNull);
    expect(updated.deliveryExtensionReason, '渲染资源异常，已安排加急处理');
    expect(updated.deliveryExtensionVersion, 1);
    expect(updated.creatorExtensionAcknowledgementDueAt, isNotNull);
    expect(
      DateTime.parse(updated.creatorExtensionAcknowledgementDueAt!).difference(
        DateTime.parse(updated.deliveryExtensionNotifiedAt!),
      ),
      creatorExtensionAcknowledgementSla,
    );
    expect(updated.deliveryExtendedAt, isNotNull);
    expect(updated.deliveryExtendedBy, 'platform-operator-local');
    expect(find.text('待确认延期 1'), findsOneWidget);
    expect(find.text('等待用户确认延期'), findsOneWidget);

    await orders.respondToDeliveryExtension(
      orderId: updated.id,
      accepted: true,
    );
    final accepted = (await orders.loadOrders()).single;
    expect(accepted.productionDueAt, '2020-01-06T00:00:00.000Z');
    expect(accepted.deliveryExtensionStatus, 'accepted');
    expect(accepted.deliveryExtensionRespondedAt, isNotNull);
    expect(accepted.deliveryExtensionResolutionEvidence,
        'in_app_explicit_acceptance');
    expect(accepted.deliveryExtensionResolvedBy, 'user-self-service');
  });

  testWidgets('平台运营队列按风险优先级排序', (tester) async {
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'normal-review',
          characterName: '普通预审',
          sourceType: '原创角色',
          status: '免费预审中',
        ),
        CustomizationOrder(
          id: 'critical-review',
          characterName: '履约风险',
          sourceType: '原创角色',
          status: '制作中',
          creatorCommunicationRiskStatus: 'performance_review',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: PlatformOperationsPage(repository: orders)),
    );
    await tester.pumpAndSettle();
    expect(find.text('高优先级 1'), findsOneWidget);
    expect(find.text('P1'), findsOneWidget);
    expect(
      tester
          .getTopLeft(find.byKey(const Key('platform-order-critical-review')))
          .dy,
      lessThan(tester
          .getTopLeft(find.byKey(const Key('platform-order-normal-review')))
          .dy),
    );

    await tester.enterText(
      find.byKey(const Key('platform-queue-search')),
      '普通预审',
    );
    await tester.pump();
    expect(
        find.byKey(const Key('platform-order-normal-review')), findsOneWidget);
    expect(
        find.byKey(const Key('platform-order-critical-review')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('platform-queue-search')),
      'critical-review',
    );
    await tester.pump();
    expect(find.byKey(const Key('platform-order-critical-review')),
        findsOneWidget);
    expect(find.byKey(const Key('platform-order-normal-review')), findsNothing);
  });

  test('运营工单领取后不能被其他人覆盖', () async {
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'operations-owner',
          characterName: '待领取工单',
          sourceType: '原创角色',
          status: '免费预审中',
        ),
      ],
    );
    await orders.claimOperationsOrder(
      orderId: 'operations-owner',
      operatorId: 'ops-a',
      now: DateTime.utc(2020, 1, 1),
    );
    await orders.claimOperationsOrder(
      orderId: 'operations-owner',
      operatorId: 'ops-b',
      now: DateTime.utc(2020, 1, 1, 1),
    );
    var order = (await orders.loadOrders()).single;
    expect(order.operationsAssigneeId, 'ops-a');
    expect(order.operationsAssignedAt, '2020-01-01T00:00:00.000Z');
    expect(order.operationsAssignmentExpiresAt, '2020-01-01T04:00:00.000Z');

    await orders.renewOperationsOrderClaim(
      orderId: 'operations-owner',
      operatorId: 'ops-b',
      now: DateTime.utc(2020, 1, 1, 2),
    );
    expect((await orders.loadOrders()).single.operationsAssignmentExpiresAt,
        '2020-01-01T04:00:00.000Z');
    await orders.renewOperationsOrderClaim(
      orderId: 'operations-owner',
      operatorId: 'ops-a',
      now: DateTime.utc(2020, 1, 1, 2),
    );
    expect((await orders.loadOrders()).single.operationsAssignmentExpiresAt,
        '2020-01-01T06:00:00.000Z');

    await orders.releaseOperationsOrder(
      orderId: 'operations-owner',
      operatorId: 'ops-b',
    );
    expect((await orders.loadOrders()).single.operationsAssigneeId, 'ops-a');
    await orders.claimOperationsOrder(
      orderId: 'operations-owner',
      operatorId: 'ops-b',
      now: DateTime.utc(2020, 1, 1, 7),
    );
    order = (await orders.loadOrders()).single;
    expect(order.operationsAssigneeId, 'ops-b');
    expect(order.operationsAssignmentExpiresAt, '2020-01-01T11:00:00.000Z');
    await orders.releaseOperationsOrder(
      orderId: 'operations-owner',
      operatorId: 'ops-a',
    );
    expect((await orders.loadOrders()).single.operationsAssigneeId, 'ops-b');
    await orders.releaseOperationsOrder(
      orderId: 'operations-owner',
      operatorId: 'ops-b',
    );
    order = (await orders.loadOrders()).single;
    expect(order.operationsAssigneeId, isNull);
    expect(order.operationsAssignedAt, isNull);
    expect(
      order.operationsAuditTrail.map((event) => event.split('|')[1]),
      ['claimed', 'renewed', 'taken_over', 'released'],
    );
    final restored = CustomizationOrder.fromJson(order.toJson());
    expect(restored?.operationsAuditTrail, order.operationsAuditTrail);

    final legacyOrders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'legacy-owner-without-expiry',
          characterName: '旧版占用工单',
          sourceType: '原创角色',
          status: '免费预审中',
          operationsAssigneeId: 'legacy-operator',
        ),
      ],
    );
    await legacyOrders.claimOperationsOrder(
      orderId: 'legacy-owner-without-expiry',
      operatorId: 'ops-new',
      now: DateTime.utc(2020, 1, 2),
    );
    final migrated = (await legacyOrders.loadOrders()).single;
    expect(migrated.operationsAssigneeId, 'ops-new');
    expect(migrated.operationsAuditTrail.last, contains('|taken_over|'));
  });

  test('运营审计仅保留最近一百条并安全编码人员标识', () async {
    final existing = List.generate(
      100,
      (index) =>
          '2026-09-10T00:00:${index.toString().padLeft(2, '0')}Z|renewed|ops',
    );
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: [
        CustomizationOrder(
          id: 'bounded-audit',
          characterName: '审计容量工单',
          sourceType: '原创角色',
          status: '免费预审中',
          operationsAuditTrail: existing,
        ),
      ],
    );

    await orders.claimOperationsOrder(
      orderId: 'bounded-audit',
      operatorId: 'ops|special',
      now: DateTime.utc(2026, 9, 10, 1),
    );

    final updated = (await orders.loadOrders()).single;
    expect(updated.operationsAuditTrail, hasLength(100));
    expect(updated.operationsAuditTrail.first, existing[1]);
    expect(updated.operationsAuditTrail.last.split('|'), hasLength(3));
    expect(updated.operationsAuditTrail.last, endsWith('ops%7Cspecial'));
    expect(
      Uri.decodeComponent(updated.operationsAuditTrail.last.split('|').last),
      'ops|special',
    );
  });

  testWidgets('运营队列显示并可快捷筛选我的工单和即将到期工单', (tester) async {
    final now = DateTime.now().toUtc();
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: [
        CustomizationOrder(
          id: 'mine-expiring',
          characterName: '我的即将到期工单',
          sourceType: '原创角色',
          status: '免费预审中',
          operationsAssigneeId: 'platform-operator-local',
          operationsAssignedAt: now.toIso8601String(),
          operationsAssignmentExpiresAt:
              now.add(const Duration(minutes: 20)).toIso8601String(),
        ),
        const CustomizationOrder(
          id: 'unclaimed-task',
          characterName: '未领取工单',
          sourceType: '原创角色',
          status: '免费预审中',
        ),
        CustomizationOrder(
          id: 'expired-task',
          characterName: '可接管工单',
          sourceType: '原创角色',
          status: '免费预审中',
          operationsAssigneeId: 'former-operator',
          operationsAssignedAt:
              now.subtract(const Duration(hours: 5)).toIso8601String(),
          operationsAssignmentExpiresAt:
              now.subtract(const Duration(hours: 1)).toIso8601String(),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: PlatformOperationsPage(repository: orders)),
    );
    await tester.pumpAndSettle();
    expect(find.text('我的工单 1'), findsOneWidget);
    expect(find.text('即将到期 1'), findsOneWidget);
    expect(find.text('可接管 1'), findsOneWidget);
    expect(find.textContaining('租约剩余约'), findsOneWidget);

    await tester.tap(find.byTooltip('筛选运营队列'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is CheckedPopupMenuItem<String> && widget.value == '我的工单',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('我的即将到期工单'), findsOneWidget);
    expect(find.text('未领取工单'), findsNothing);
    expect(find.text('可接管工单'), findsNothing);

    await tester.tap(find.text('即将到期 1'));
    await tester.pumpAndSettle();
    expect(find.text('当前筛选：即将到期'), findsOneWidget);
    expect(find.text('我的即将到期工单'), findsOneWidget);
    expect(find.text('未领取工单'), findsNothing);

    await tester.tap(find.text('可接管 1'));
    await tester.pumpAndSettle();
    expect(find.text('当前筛选：可接管'), findsOneWidget);
    expect(find.text('可接管工单'), findsOneWidget);
    expect(find.text('我的即将到期工单'), findsNothing);
    expect(find.text('未领取工单'), findsNothing);

    await tester.tap(find.byTooltip('接管过期工单'));
    await tester.pumpAndSettle();
    expect(find.text('可接管 0'), findsOneWidget);
    expect(find.text('我的工单 2'), findsOneWidget);
    expect(find.text('当前没有待处理订单'), findsOneWidget);
    expect(find.text('已接管过期工单'), findsOneWidget);
    final takenOver = (await orders.loadOrders())
        .singleWhere((order) => order.id == 'expired-task');
    expect(takenOver.operationsAssigneeId, 'platform-operator-local');
    expect(takenOver.operationsAuditTrail.last, contains('|taken_over|'));
  });

  testWidgets('运营人员可一次续期自己即将到期的工单', (tester) async {
    final now = DateTime.now().toUtc();
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: [
        CustomizationOrder(
          id: 'renew-mine',
          characterName: '待续期工单',
          sourceType: '原创角色',
          status: '免费预审中',
          operationsAssigneeId: 'platform-operator-local',
          operationsAssignedAt: now.toIso8601String(),
          operationsAssignmentExpiresAt:
              now.add(const Duration(minutes: 20)).toIso8601String(),
        ),
        CustomizationOrder(
          id: 'renew-other',
          characterName: '他人工单',
          sourceType: '原创角色',
          status: '免费预审中',
          operationsAssigneeId: 'another-operator',
          operationsAssignedAt: now.toIso8601String(),
          operationsAssignmentExpiresAt:
              now.add(const Duration(minutes: 20)).toIso8601String(),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: PlatformOperationsPage(repository: orders)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('续期全部即将到期工单'));
    await tester.pumpAndSettle();

    final updated = await orders.loadOrders();
    final mine = updated.singleWhere((order) => order.id == 'renew-mine');
    final other = updated.singleWhere((order) => order.id == 'renew-other');
    expect(
      DateTime.parse(mine.operationsAssignmentExpiresAt!)
          .difference(DateTime.now().toUtc()),
      greaterThan(const Duration(hours: 3)),
    );
    expect(
      other.operationsAssignmentExpiresAt,
      now.add(const Duration(minutes: 20)).toIso8601String(),
    );
    expect(find.text('即将到期 0'), findsOneWidget);
    expect(find.text('已续期 1 个即将到期工单'), findsOneWidget);
    expect(find.textContaining('最近操作：续期'), findsOneWidget);

    final auditEntry = find.byKey(const Key('operations-audit-renew-mine'));
    await tester.ensureVisible(auditEntry);
    await tester.pumpAndSettle();
    await tester.tap(auditEntry);
    await tester.pumpAndSettle();
    expect(find.text('待续期工单 · 运营记录'), findsOneWidget);
    expect(find.textContaining('续期 · platform-operator-local'), findsWidgets);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('续期4小时').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('工单已续期4小时'), findsOneWidget);
  });

  testWidgets('并发接管冲突不会误报成功', (tester) async {
    final now = DateTime.now().toUtc();
    final orders = _RacingOperationsRepository(
      initialOrders: [
        CustomizationOrder(
          id: 'racing-takeover',
          characterName: '并发接管工单',
          sourceType: '原创角色',
          status: '免费预审中',
          operationsAssigneeId: 'former-operator',
          operationsAssignedAt:
              now.subtract(const Duration(hours: 5)).toIso8601String(),
          operationsAssignmentExpiresAt:
              now.subtract(const Duration(hours: 1)).toIso8601String(),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: PlatformOperationsPage(repository: orders)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('接管过期工单'));
    await tester.pumpAndSettle();

    expect(find.text('工单状态已变化，请刷新后重试'), findsOneWidget);
    expect(find.text('已接管过期工单'), findsNothing);
    expect(
      (await orders.loadOrders()).single.operationsAssigneeId,
      'competing-operator',
    );
  });

  testWidgets('运营队列停留期间会自动刷新租约到期状态', (tester) async {
    final now = DateTime.now().toUtc();
    var clock = now;
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: [
        CustomizationOrder(
          id: 'live-expiry',
          characterName: '实时到期工单',
          sourceType: '原创角色',
          status: '免费预审中',
          operationsAssigneeId: 'platform-operator-local',
          operationsAssignedAt: now.toIso8601String(),
          operationsAssignmentExpiresAt:
              now.add(const Duration(seconds: 10)).toIso8601String(),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PlatformOperationsPage(
          repository: orders,
          now: () => clock,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('我的工单 1'), findsOneWidget);
    expect(find.text('可接管 0'), findsOneWidget);

    clock = now.add(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 31));

    expect(find.text('我的工单 0'), findsOneWidget);
    expect(find.text('可接管 1'), findsOneWidget);
    expect(find.textContaining('领取已过期，可接管'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('运营队列进入后台暂停时钟并在恢复时立即校正', (tester) async {
    final now = DateTime.utc(2026, 9, 10, 9, 0);
    var clock = now;
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: [
        CustomizationOrder(
          id: 'lifecycle-expiry',
          characterName: '前后台租约工单',
          sourceType: '原创角色',
          status: '免费预审中',
          operationsAssigneeId: 'platform-operator-local',
          operationsAssignedAt: now.toIso8601String(),
          operationsAssignmentExpiresAt:
              now.add(const Duration(seconds: 10)).toIso8601String(),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PlatformOperationsPage(
          repository: orders,
          now: () => clock,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('我的工单 1'), findsOneWidget);
    expect(find.text('最后同步：09:00:00 UTC'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.paused,
    );
    clock = now.add(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('我的工单 1'), findsOneWidget);

    await orders.releaseOperationsOrder(
      orderId: 'lifecycle-expiry',
      operatorId: 'platform-operator-local',
    );
    await orders.claimOperationsOrder(
      orderId: 'lifecycle-expiry',
      operatorId: 'background-operator',
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('我的工单 0'), findsOneWidget);
    expect(find.text('可接管 0'), findsOneWidget);
    expect(find.textContaining('负责人：background-operator'), findsOneWidget);
    expect(find.text('最后同步：09:00:31 UTC'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('运营数据超过五分钟未同步时提供立即刷新', (tester) async {
    final now = DateTime.utc(2026, 9, 10, 9);
    var clock = now;
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'stale-data',
          characterName: '数据新鲜度工单',
          sourceType: '原创角色',
          status: '免费预审中',
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PlatformOperationsPage(
          repository: orders,
          now: () => clock,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('最后同步：09:00:00 UTC'), findsOneWidget);
    expect(find.text('数据超过5分钟未同步，立即刷新'), findsNothing);

    clock = now.add(const Duration(minutes: 6));
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('数据超过5分钟未同步，立即刷新'), findsOneWidget);

    await tester.tap(find.text('数据超过5分钟未同步，立即刷新'));
    await tester.pumpAndSettle();
    expect(find.text('最后同步：09:06:00 UTC'), findsOneWidget);
    expect(find.text('数据超过5分钟未同步，立即刷新'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('其他运营人员持有有效租约时不能进入处置页面', (tester) async {
    final now = DateTime.now().toUtc();
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: [
        CustomizationOrder(
          id: 'owned-by-other',
          characterName: '他人处理中工单',
          sourceType: '原创角色',
          status: '免费预审中',
          operationsAssigneeId: 'another-operator',
          operationsAssignedAt: now.toIso8601String(),
          operationsAssignmentExpiresAt:
              now.add(const Duration(hours: 3)).toIso8601String(),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: PlatformOperationsPage(repository: orders)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('他人处理中工单'));
    await tester.pumpAndSettle();

    expect(find.text('工单正由 another-operator 处理'), findsOneWidget);
    expect(find.text('平台免费预审'), findsNothing);
    expect(
      (await orders.loadOrders()).single.operationsAssigneeId,
      'another-operator',
    );
  });

  testWidgets('进入处置页面前会将自己的租约续期到完整四小时', (tester) async {
    final now = DateTime.now().toUtc();
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: [
        CustomizationOrder(
          id: 'renew-before-open',
          characterName: '进入前续期工单',
          sourceType: '原创角色',
          status: '免费预审中',
          operationsAssigneeId: 'platform-operator-local',
          operationsAssignedAt: now.toIso8601String(),
          operationsAssignmentExpiresAt:
              now.add(const Duration(minutes: 10)).toIso8601String(),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: PlatformOperationsPage(repository: orders)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('进入前续期工单'));
    await tester.pumpAndSettle();

    expect(find.text('平台免费预审'), findsOneWidget);
    final updated = (await orders.loadOrders()).single;
    expect(
      DateTime.parse(updated.operationsAssignmentExpiresAt!)
          .difference(DateTime.now().toUtc()),
      greaterThan(const Duration(hours: 3)),
    );
    expect(updated.operationsAuditTrail.last, contains('|renewed|'));
  });

  test('declining a delivery extension opens a dispute and freezes settlement',
      () async {
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'declined-extension',
          characterName: '延期争议任务',
          sourceType: '原创角色',
          status: '制作中',
          productionDueAt: '2026-09-01T00:00:00Z',
          proposedProductionDueAt: '2026-09-06T00:00:00Z',
          deliveryExtensionStatus: 'pending',
          settlementStatus: '平台托管中',
        ),
      ],
    );

    await orders.respondToDeliveryExtension(
      orderId: 'declined-extension',
      accepted: false,
    );
    final order = (await orders.loadOrders()).single;
    expect(order.status, '争议处理中');
    expect(order.disputePriorStatus, '制作中');
    expect(order.deliveryExtensionStatus, 'declined');
    expect(order.settlementStatus, '结算已冻结');
    expect(order.disputeReason, '用户拒绝平台提出的交付延期');
    expect(
        order.deliveryExtensionResolutionEvidence, 'in_app_explicit_decline');
    expect(order.deliveryExtensionResolvedBy, 'user-self-service');
  });

  test('延期确认提醒仅在响应窗口逾期后留痕', () async {
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'extension-reminder',
          characterName: '延期提醒任务',
          sourceType: '原创角色',
          status: '制作中',
          productionDueAt: '2020-01-01T00:00:00Z',
          proposedProductionDueAt: '2020-01-06T00:00:00Z',
          deliveryExtensionStatus: 'pending',
          deliveryExtensionResponseDueAt: '2020-01-03T00:00:00Z',
        ),
      ],
    );

    await orders.recordDeliveryExtensionReminder(
      orderId: 'extension-reminder',
      now: DateTime.utc(2020, 1, 2),
    );
    expect(
      (await orders.loadOrders()).single.deliveryExtensionReminderCount,
      0,
    );

    await orders.recordDeliveryExtensionReminder(
      orderId: 'extension-reminder',
      now: DateTime.utc(2020, 1, 4, 8, 30),
    );
    final reminded = (await orders.loadOrders()).single;
    expect(reminded.deliveryExtensionReminderCount, 1);
    expect(
        reminded.lastDeliveryExtensionReminderAt, '2020-01-04T08:30:00.000Z');

    await orders.recordDeliveryExtensionReminder(
      orderId: 'extension-reminder',
      now: DateTime.utc(2020, 1, 4, 9),
    );
    expect(
      (await orders.loadOrders()).single.deliveryExtensionReminderCount,
      1,
    );

    await orders.recordDeliveryExtensionReminder(
      orderId: 'extension-reminder',
      now: DateTime.utc(2020, 1, 5, 8, 30),
    );
    await orders.recordDeliveryExtensionReminder(
      orderId: 'extension-reminder',
      now: DateTime.utc(2020, 1, 6, 8, 30),
    );
    await orders.recordDeliveryExtensionReminder(
      orderId: 'extension-reminder',
      now: DateTime.utc(2020, 1, 7, 8, 30),
    );
    expect(
      (await orders.loadOrders()).single.deliveryExtensionReminderCount,
      maximumDeliveryExtensionReminders,
    );

    await orders.respondToDeliveryExtension(
      orderId: 'extension-reminder',
      accepted: true,
    );
    await orders.recordDeliveryExtensionReminder(
      orderId: 'extension-reminder',
      now: DateTime.utc(2020, 1, 5),
    );
    expect(
      (await orders.loadOrders()).single.deliveryExtensionReminderCount,
      maximumDeliveryExtensionReminders,
    );
  });

  test('三次延期提醒后可转人工且不会自动接受新日期', () async {
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'extension-escalation',
          characterName: '延期升级任务',
          sourceType: '原创角色',
          status: '制作中',
          productionDueAt: '2020-01-01T00:00:00Z',
          proposedProductionDueAt: '2020-01-10T00:00:00Z',
          deliveryExtensionStatus: 'pending',
          deliveryExtensionResponseDueAt: '2020-01-03T00:00:00Z',
          deliveryExtensionReminderCount: maximumDeliveryExtensionReminders,
        ),
      ],
    );

    await orders.escalateDeliveryExtensionResponse(
      orderId: 'extension-escalation',
      operatorId: 'ops-123',
      now: DateTime.utc(2020, 1, 7),
    );
    final escalated = (await orders.loadOrders()).single;
    expect(escalated.deliveryExtensionStatus, 'escalated');
    expect(escalated.deliveryExtensionEscalatedAt, '2020-01-07T00:00:00.000Z');
    expect(escalated.deliveryExtensionEscalatedBy, 'ops-123');
    expect(
        escalated.deliveryExtensionEscalationDueAt, '2020-01-09T00:00:00.000Z');
    expect(escalated.productionDueAt, '2020-01-01T00:00:00Z');

    await orders.respondToDeliveryExtension(
      orderId: 'extension-escalation',
      accepted: true,
    );
    expect(
      (await orders.loadOrders()).single.productionDueAt,
      '2020-01-01T00:00:00Z',
    );

    await orders.resolveEscalatedDeliveryExtension(
      orderId: 'extension-escalation',
      resolution: EscalatedExtensionResolution.userAccepted,
      evidenceReference: 'consent-call-unreviewed',
      operatorId: 'ops-123',
      now: DateTime.utc(2020, 1, 8),
    );
    expect(
      (await orders.loadOrders()).single.deliveryExtensionStatus,
      'escalated',
    );

    await orders.resolveEscalatedDeliveryExtension(
      orderId: 'extension-escalation',
      resolution: EscalatedExtensionResolution.userAccepted,
      evidenceReference: 'consent-call-001',
      operatorId: 'ops-456',
      now: DateTime.utc(2020, 1, 8),
    );
    final resolved = (await orders.loadOrders()).single;
    expect(resolved.deliveryExtensionStatus, 'accepted');
    expect(resolved.productionDueAt, '2020-01-10T00:00:00Z');
    expect(resolved.deliveryExtensionResolutionEvidence, 'consent-call-001');
    expect(resolved.deliveryExtensionResolvedBy, 'ops-456');
  });

  test('人工延期处置可撤回方案或按用户拒绝进入争议', () async {
    CustomizationOrder order(String id) => CustomizationOrder(
          id: id,
          characterName: '人工处置任务',
          sourceType: '原创角色',
          status: '制作中',
          productionDueAt: '2020-01-01T00:00:00Z',
          proposedProductionDueAt: '2020-01-10T00:00:00Z',
          deliveryExtensionStatus: 'escalated',
          settlementStatus: '平台托管中',
        );
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: [order('withdrawn'), order('declined')],
    );

    await orders.resolveEscalatedDeliveryExtension(
      orderId: 'withdrawn',
      resolution: EscalatedExtensionResolution.proposalWithdrawn,
      evidenceReference: 'ops-note-001',
    );
    await orders.resolveEscalatedDeliveryExtension(
      orderId: 'declined',
      resolution: EscalatedExtensionResolution.userDeclined,
      evidenceReference: 'user-email-001',
    );
    final results = await orders.loadOrders();
    final withdrawn = results.firstWhere((item) => item.id == 'withdrawn');
    final declined = results.firstWhere((item) => item.id == 'declined');
    expect(withdrawn.deliveryExtensionStatus, 'withdrawn');
    expect(withdrawn.productionDueAt, '2020-01-01T00:00:00Z');
    expect(withdrawn.status, '制作中');
    expect(declined.deliveryExtensionStatus, 'declined');
    expect(declined.status, '争议处理中');
    expect(declined.settlementStatus, '结算已冻结');
    expect(declined.productionDueAt, '2020-01-01T00:00:00Z');
  });

  testWidgets('approved custom delivery moves into device-ready library',
      (tester) async {
    final orders = MemoryCustomizationOrderRepository();
    final entitlements = MemoryCharacterEntitlementRepository();
    await orders.submitReview(characterName: '星际狐狸', sourceType: '原创角色');
    final id = (await orders.loadOrders()).single.id;
    await approveReview(orders, id);
    await assignCreator(orders, id, 'local-certified-creator');
    await orders.submitCreatorProposal(
      orderId: id,
      creatorId: 'local-certified-creator',
      suggestedAmountCents: 11000,
      estimatedDeliveryDays: 10,
    );
    await orders.publishPlatformQuote(
      orderId: id,
      amountCents: 12900,
      currency: 'USD',
      includedRevisions: 2,
      estimatedDeliveryDays: 12,
    );
    await orders.acceptQuote(id);
    await orders.recordVerifiedPayment(
      orderId: id,
      paymentReference: 'provider-event-2',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CreatorTaskBoardPage(
          orderRepository: orders,
          previewPicker: () async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('提交受控预览'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('提交受控预览'));
    await tester.pumpAndSettle();
    expect(find.text('待平台质检'), findsOneWidget);
    await orders.submitContentQualityReview(
      orderId: id,
      expectedPreviewVersion: (await orders.loadOrders()).single.previewVersion,
      review: CharacterQualityReview(
        results: {
          for (final check in requiredCharacterQualityChecks)
            check: CharacterQualityCheckResult.passed,
        },
        reviewerId: 'quality-reviewer-1',
        deviceModel: 'P20',
        packageVersion: '1.0.0',
        reviewedAt: '2026-09-10T10:00:00Z',
      ),
    );
    expect((await orders.loadOrders()).single.status, '待用户验收');

    await tester.pumpWidget(
      MaterialApp(
        home: MyCharactersPage(
          repository: entitlements,
          orderRepository: orders,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('星际狐狸'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('确认验收并交付'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认验收并交付'));
    await tester.pumpAndSettle();
    expect(
        await entitlements.loadClaimedCharacterIds(), contains('custom-$id'));

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('我的定制角色'), findsOneWidget);
    expect(find.text('查看包内视频'), findsOneWidget);
    await tester.tap(find.text('查看包内视频'));
    await tester.pumpAndSettle();
    expect(await entitlements.loadDeviceCharacterIds(), isEmpty);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await orders.openDispute(orderId: id, reason: '交付范围不一致');
    await orders.resolveDispute(
      orderId: id,
      resolution: DisputeResolution.refundApproved,
    );
    final refunded = await CustomizationRefundService(
      orders: orders,
      entitlements: entitlements,
    ).completeVerifiedRefund(
      orderId: id,
      refundReference: 'refund-1',
    );

    expect(refunded, isTrue);
    expect((await orders.loadOrders()).single.status, '已退款');
    expect(await entitlements.loadClaimedCharacterIds(),
        isNot(contains('custom-$id')));
    expect(await entitlements.loadDeviceCharacterIds(),
        isNot(contains('custom-$id')));
  });

  testWidgets('creator only sees and claims platform-approved tasks',
      (tester) async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(characterName: '未审核角色', sourceType: '原创角色');
    await orders.submitReview(characterName: '已审核角色', sourceType: '原创角色');
    final allOrders = await orders.loadOrders();
    final approved = allOrders.firstWhere(
      (order) => order.characterName == '已审核角色',
    );
    await approveReview(orders, approved.id);

    await tester.pumpWidget(
      MaterialApp(home: CreatorTaskBoardPage(orderRepository: orders)),
    );
    await tester.pumpAndSettle();

    expect(find.text('已审核角色'), findsOneWidget);
    expect(find.text('未审核角色'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('申请接单'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('申请接单'));
    await tester.pumpAndSettle();
    expect(find.text('撤回接单申请'), findsOneWidget);
    expect(
      (await orders.loadOrders())
          .firstWhere((order) => order.id == approved.id)
          .applicantCreatorIds,
      ['local-certified-creator'],
    );

    final awaitingAssignment = (await orders.loadOrders()).firstWhere(
      (order) => order.id == approved.id,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PlatformAssignmentReviewPage(
          order: awaitingAssignment,
          repository: orders,
          creatorDisplayNames: const {
            'local-certified-creator': '星光创作室',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('星光创作室'), findsOneWidget);
    expect(find.textContaining('脱敏摘要'), findsOneWidget);
    await tester.tap(find.text('选择'));
    await tester.pumpAndSettle();
    expect(
      (await orders.loadOrders())
          .firstWhere((order) => order.id == approved.id)
          .assignedCreatorId,
      'local-certified-creator',
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(home: CreatorTaskBoardPage(orderRepository: orders)),
    );
    await tester.pumpAndSettle();
    expect(find.text('填写工作量与建议报价'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('填写工作量与建议报价'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('填写工作量与建议报价'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('creator-proposal-amount')),
      '110',
    );
    await tester.enterText(
      find.byKey(const Key('creator-proposal-days')),
      '10',
    );
    await tester.tap(find.text('提交平台审核'));
    await tester.pumpAndSettle();

    expect(find.text('等待平台审核报价'), findsOneWidget);
    final claimedTask = (await orders.loadOrders()).firstWhere(
      (order) => order.id == approved.id,
    );
    expect(claimedTask.creatorSuggestedAmountCents, 11000);
    expect(claimedTask.creatorSuggestedCurrency, 'USD');
    expect(claimedTask.estimatedDeliveryDays, 10);
  });

  testWidgets('创作者会看到尚未生效的延期提示', (tester) async {
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'creator-extension-notice',
          characterName: '延期同步角色',
          sourceType: '原创角色',
          status: '制作中',
          assignedCreatorId: 'local-certified-creator',
          productionDueAt: '2030-01-01T00:00:00Z',
          proposedProductionDueAt: '2030-01-06T00:00:00Z',
          deliveryExtensionStatus: 'pending',
          deliveryExtensionVersion: 1,
          creatorExtensionAcknowledgementDueAt: '2030-01-02T00:00:00Z',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: CreatorTaskBoardPage(orderRepository: orders)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('延期尚未生效'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('延期尚未生效'), findsOneWidget);
    expect(find.textContaining('请仍按上方正式截止日期制作'), findsOneWidget);
    expect(find.textContaining('2030-01-06'), findsOneWidget);
    expect(find.text('延期记录'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('acknowledge-extension-creator-extension-notice')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    await tester.tap(find
        .byKey(const Key('acknowledge-extension-creator-extension-notice')));
    await tester.pumpAndSettle();
    final acknowledged = (await orders.loadOrders()).single;
    expect(acknowledged.creatorExtensionAcknowledgedVersion, 1);
    expect(acknowledged.creatorExtensionAcknowledgedAt, isNotNull);
    expect(find.textContaining('已知悉本次延期状态'), findsOneWidget);
  });

  test('创作者延期通知提醒有24小时冷却和2次上限', () async {
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'creator-extension-reminder',
          characterName: '创作者提醒任务',
          sourceType: '原创角色',
          status: '制作中',
          assignedCreatorId: 'local-certified-creator',
          deliveryExtensionVersion: 1,
          creatorExtensionAcknowledgementDueAt: '2020-01-02T00:00:00Z',
        ),
      ],
    );

    Future<void> remind(DateTime now) => orders.recordCreatorExtensionReminder(
          orderId: 'creator-extension-reminder',
          now: now,
        );
    await remind(DateTime.utc(2020, 1, 1));
    await remind(DateTime.utc(2020, 1, 3));
    await remind(DateTime.utc(2020, 1, 3, 1));
    expect((await orders.loadOrders()).single.creatorExtensionReminderCount, 1);
    await remind(DateTime.utc(2020, 1, 4));
    await remind(DateTime.utc(2020, 1, 5));
    final reminded = (await orders.loadOrders()).single;
    expect(reminded.creatorExtensionReminderCount,
        maximumCreatorExtensionReminders);
    expect(reminded.lastCreatorExtensionReminderAt, '2020-01-04T00:00:00.000Z');

    await orders.flagCreatorCommunicationRisk(
      orderId: 'creator-extension-reminder',
      operatorId: 'ops-risk-1',
      now: DateTime.utc(2020, 1, 5),
    );
    final flagged = (await orders.loadOrders()).single;
    expect(flagged.creatorCommunicationRiskStatus, 'pending_review');
    expect(
        flagged.creatorCommunicationRiskFlaggedAt, '2020-01-05T00:00:00.000Z');
    expect(flagged.creatorCommunicationRiskFlaggedBy, 'ops-risk-1');

    await orders.acknowledgeCreatorExtensionNotice(
      orderId: 'creator-extension-reminder',
      creatorId: 'local-certified-creator',
      now: DateTime.utc(2020, 1, 5),
    );
    await remind(DateTime.utc(2020, 1, 6));
    expect((await orders.loadOrders()).single.creatorExtensionReminderCount,
        maximumCreatorExtensionReminders);

    await orders.resolveCreatorCommunicationRisk(
      orderId: 'creator-extension-reminder',
      resolution: CreatorCommunicationRiskResolution.performanceReview,
      note: '多渠道联系未获回复',
      operatorId: 'ops-risk-reviewer',
      now: DateTime.utc(2020, 1, 6),
    );
    final reviewed = (await orders.loadOrders()).single;
    expect(reviewed.creatorCommunicationRiskStatus, 'performance_review');
    expect(reviewed.creatorCommunicationRiskResolution, 'performanceReview');
    expect(reviewed.creatorCommunicationRiskResolutionNote, '多渠道联系未获回复');
    expect(reviewed.creatorCommunicationRiskResolvedBy, 'ops-risk-reviewer');
    expect(reviewed.settlementStatus, '结算已冻结');

    await orders.resolveCreatorPerformanceReview(
      orderId: 'creator-extension-reminder',
      outcome: CreatorPerformanceReviewOutcome.openOrderDispute,
      note: '履约证据不足，需要进入争议审理',
      operatorId: 'ops-performance-reviewer',
      now: DateTime.utc(2020, 1, 7),
    );
    final disputed = (await orders.loadOrders()).single;
    expect(disputed.creatorCommunicationRiskStatus, 'resolved');
    expect(disputed.creatorPerformanceReviewOutcome, 'openOrderDispute');
    expect(disputed.creatorPerformanceReviewNote, '履约证据不足，需要进入争议审理');
    expect(disputed.creatorPerformanceReviewResolvedBy,
        'ops-performance-reviewer');
    expect(disputed.status, '争议处理中');
    expect(disputed.settlementStatus, '结算已冻结');
  });

  test('creator can withdraw and reapply before platform assignment', () async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(characterName: '可撤回任务', sourceType: '原创角色');
    final id = (await orders.loadOrders()).single.id;
    await approveReview(orders, id);

    await orders.applyForCreator(orderId: id, creatorId: 'creator-1');
    await orders.withdrawCreatorApplication(
      orderId: id,
      creatorId: 'creator-1',
    );
    var order = (await orders.loadOrders()).single;
    expect(order.applicantCreatorIds, isEmpty);
    expect(order.withdrawnApplicantCreatorIds, ['creator-1']);

    await orders.applyForCreator(orderId: id, creatorId: 'creator-1');
    order = (await orders.loadOrders()).single;
    expect(order.applicantCreatorIds, ['creator-1']);

    await orders.assignCreator(orderId: id, creatorId: 'creator-1');
    await orders.withdrawCreatorApplication(
      orderId: id,
      creatorId: 'creator-1',
    );
    order = (await orders.loadOrders()).single;
    expect(order.assignedCreatorId, 'creator-1');
    expect(order.status, '创作者评估中');
  });

  test('assigned creator can decline only before submitting a proposal',
      () async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(characterName: '重新匹配任务', sourceType: '原创角色');
    final id = (await orders.loadOrders()).single.id;
    await approveReview(orders, id);
    await assignCreator(orders, id, 'creator-1');

    await orders.declineAssignedTask(
      orderId: id,
      creatorId: 'creator-1',
      reason: '当前档期不足',
    );
    var order = (await orders.loadOrders()).single;
    expect(order.status, '待创作者申请');
    expect(order.assignedCreatorId, isNull);
    expect(order.applicantCreatorIds, isEmpty);
    expect(order.declinedAssignedCreatorIds, ['creator-1']);
    expect(order.lastCreatorDeclineReason, '当前档期不足');
    expect(order.lastCreatorDeclinedAt, isNotNull);

    await orders.applyForCreator(orderId: id, creatorId: 'creator-1');
    order = (await orders.loadOrders()).single;
    expect(order.applicantCreatorIds, isEmpty);

    await assignCreator(orders, id, 'creator-2');
    await orders.submitCreatorProposal(
      orderId: id,
      creatorId: 'creator-2',
      suggestedAmountCents: 9000,
      estimatedDeliveryDays: 8,
    );
    await orders.declineAssignedTask(
      orderId: id,
      creatorId: 'creator-2',
      reason: '报价后尝试退出',
    );
    order = (await orders.loadOrders()).single;
    expect(order.status, '平台审核报价');
    expect(order.assignedCreatorId, 'creator-2');
  });

  test('expired creator assignment returns to matching and blocks reapply',
      () async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(characterName: '超时派单任务', sourceType: '原创角色');
    final id = (await orders.loadOrders()).single.id;
    await approveReview(orders, id);
    await assignCreator(orders, id, 'creator-timeout');
    var order = (await orders.loadOrders()).single;
    expect(order.assignmentResponseDueAt, isNotNull);

    final processed = await orders.processExpiredCreatorAssignments(
      now: DateTime.utc(2100),
    );
    expect(processed, 1);
    order = (await orders.loadOrders()).single;
    expect(order.status, '待创作者申请');
    expect(order.assignedCreatorId, isNull);
    expect(order.timedOutAssignedCreatorIds, ['creator-timeout']);
    expect(order.lastAssignmentTimedOutAt, isNotNull);

    await orders.applyForCreator(
      orderId: id,
      creatorId: 'creator-timeout',
    );
    order = (await orders.loadOrders()).single;
    expect(order.applicantCreatorIds, isEmpty);
  });

  testWidgets('creator earnings summary separates settlement states',
      (tester) async {
    CustomizationOrder earning(
      String id,
      String settlementStatus,
      int amount, {
      String? payoutReference,
      String? settledAt,
    }) =>
        CustomizationOrder(
          id: id,
          characterName: '收益任务 $id',
          sourceType: '原创角色',
          status: '已交付',
          assignedCreatorId: 'local-certified-creator',
          creatorPayoutCents: amount,
          creatorPayoutCurrency: 'USD',
          settlementStatus: settlementStatus,
          payoutReference: payoutReference,
          settledAt: settledAt,
        );
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: [
        earning('escrow', '平台托管中', 1000),
        earning('hold', '待结算', 2000),
        earning('failed', '结算失败', 3000),
        earning(
          'paid',
          '已结算',
          4000,
          payoutReference: 'payout-paid',
          settledAt: '2026-09-01T00:00:00Z',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: CreatorTaskBoardPage(orderRepository: orders)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('creator-earnings-summary')), findsOneWidget);
    expect(find.text('托管中 USD 10.00'), findsOneWidget);
    expect(find.text('观察期 USD 20.00'), findsOneWidget);
    expect(find.text('结算失败 USD 30.00'), findsOneWidget);
    expect(find.text('已到账 USD 40.00'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('open-creator-settlement-statement')),
    );
    await tester.pumpAndSettle();
    expect(find.text('创作者结算明细'), findsOneWidget);
    expect(find.text('约定收入合计：USD 100.00'), findsOneWidget);
    expect(find.text('已到账合计：USD 40.00'), findsOneWidget);
    expect(find.textContaining('不包含用户支付价'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('到账流水：payout-paid'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('到账流水：payout-paid'), findsOneWidget);
    expect(find.text('到账日期：2026-09-01'), findsOneWidget);
  });

  testWidgets('uncertified creator cannot access tasks and can apply',
      (tester) async {
    final profiles = MemoryCreatorProfileRepository();
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(
      characterName: '用户私密任务',
      sourceType: '原创角色',
      requestedFeatures: ['待机动作'],
    );
    final id = (await orders.loadOrders()).single.id;
    await approveReview(orders, id);

    await tester.pumpWidget(
      MaterialApp(
        home: CreatorHubPage(
          orderRepository: orders,
          profileRepository: profiles,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('用户私密任务'), findsNothing);
    await tester.tap(find.text('待机动作'));
    await tester.tap(find.byKey(const Key('creator-market-region')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('中国大陆').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '星光创作室');
    await tester.enterText(
      find.byType(TextField).at(1),
      'https://portfolio.example',
    );
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.scrollUntilVisible(
      find.text('我同意创作者规则、保密要求和禁止私下交易条款'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('我同意创作者规则、保密要求和禁止私下交易条款'));
    await tester.pump();
    await tester.ensureVisible(find.text('提交创作者申请'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('提交创作者申请'));
    await tester.pumpAndSettle();

    expect(find.text('创作者申请审核中'), findsOneWidget);
    expect((await profiles.loadProfile())?.status, '审核中');
    expect((await profiles.loadProfile())?.skillTags, ['待机动作']);
    expect((await profiles.loadProfile())?.marketRegion, 'cn_mainland');

    await profiles.approveApplication();
    final approvedProfile = await profiles.loadProfile();
    expect(approvedProfile?.settlementCurrency, 'CNY');
    expect(approvedProfile?.marketRegionVerifiedAt, isNotNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        home: CreatorHubPage(
          orderRepository: orders,
          profileRepository: profiles,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('设置创作者收款账户'), findsOneWidget);
    expect(find.text('结算币种：CNY'), findsOneWidget);
    expect(find.text('用户私密任务'), findsNothing);
    await tester.tap(find.byKey(const Key('creator-tax-form')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('中国大陆税务资料').last);
    await tester.enterText(
      find.byKey(const Key('creator-payout-reference')),
      'provider-account-token',
    );
    await tester.pump();
    await tester.tap(find.text('提交收款账户审核'));
    await tester.pumpAndSettle();
    expect(find.text('收款账户与税务资料审核中'), findsOneWidget);
    expect((await profiles.loadProfile())?.payoutAccountStatus, '审核中');

    await profiles.approvePayoutAccount();
    final payoutProfile = await profiles.loadProfile();
    expect(payoutProfile?.payoutAccountStatus, '已核验');
    expect(payoutProfile?.taxFormType, '中国大陆税务资料');
    expect(payoutProfile?.payoutVerifiedAt, isNotNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        home: CreatorHubPage(
          orderRepository: orders,
          profileRepository: profiles,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('已核验结算币种：CNY'), findsOneWidget);
    expect(find.text('用户私密任务'), findsOneWidget);
  });

  testWidgets('platform publishes the final quote after creator proposal',
      (tester) async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(characterName: '星际狐狸', sourceType: '原创角色');
    final id = (await orders.loadOrders()).single.id;
    await approveReview(orders, id);
    await assignCreator(orders, id, 'creator-1');
    await orders.submitCreatorProposal(
      orderId: id,
      creatorId: 'creator-1',
      suggestedAmountCents: 11000,
      estimatedDeliveryDays: 10,
    );
    final proposed = (await orders.loadOrders()).single;

    await tester.pumpWidget(
      MaterialApp(
        home: PlatformQuoteReviewPage(
          order: proposed,
          repository: orders,
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('platform-final-amount')),
      '129',
    );
    await tester.enterText(
      find.byKey(const Key('platform-included-revisions')),
      '2',
    );
    await tester.enterText(
      find.byKey(const Key('platform-delivery-days')),
      '12',
    );
    await tester.ensureVisible(find.text('发布平台最终报价'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('发布平台最终报价'));
    await tester.pumpAndSettle();

    final quoted = (await orders.loadOrders()).single;
    expect(quoted.status, '待确认报价');
    expect(quoted.quoteAmountCents, 12900);
    expect(quoted.quoteTaxTreatment, 'calculated_at_checkout');
    expect(quoted.creatorPayoutCurrency, 'USD');
    expect(quoted.includedRevisions, 2);
    expect(quoted.estimatedDeliveryDays, 12);
  });

  testWidgets('Japan orders default to JPY without decimal conversion',
      (tester) async {
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'jp-quote',
          characterName: '日本向けキャラクター',
          sourceType: '原创角色',
          status: '平台审核报价',
          marketRegion: 'jp',
          creatorSuggestedAmountCents: 11000,
          estimatedDeliveryDays: 10,
        ),
      ],
    );
    final order = (await orders.loadOrders()).single;
    await tester.pumpWidget(
      MaterialApp(
        home: PlatformQuoteReviewPage(order: order, repository: orders),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('JPY'), findsOneWidget);
    final amountField = tester.widget<TextField>(
      find.byKey(const Key('platform-final-amount')),
    );
    expect(amountField.controller?.text, isEmpty);
    await tester.tap(find.byKey(const Key('platform-tax-treatment')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('价格已含适用税费').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('platform-final-amount')),
      '19800',
    );
    await tester.enterText(
      find.byKey(const Key('platform-delivery-days')),
      '10',
    );
    await tester.tap(find.text('发布平台最终报价'));
    await tester.pumpAndSettle();

    final quoted = (await orders.loadOrders()).single;
    expect(quoted.quoteCurrency, 'JPY');
    expect(quoted.quoteAmountCents, 19800);
    expect(quoted.quoteTaxTreatment, 'tax_included');
  });

  testWidgets('checkout displays JPY as a zero-decimal currency',
      (tester) async {
    const order = CustomizationOrder(
      id: 'jp-checkout',
      characterName: '日本向けキャラクター',
      sourceType: '原创角色',
      status: '待支付',
      marketRegion: 'jp',
      quoteAmountCents: 19800,
      quoteCurrency: 'JPY',
      quoteTaxTreatment: 'tax_included',
      includedRevisions: 2,
      estimatedDeliveryDays: 10,
    );
    await tester.pumpWidget(
      const MaterialApp(home: CheckoutReviewPage(order: order)),
    );

    expect(find.text('JPY 19800'), findsOneWidget);
    expect(find.text('价格已含适用税费'), findsOneWidget);
  });

  testWidgets('mainland China orders default to CNY', (tester) async {
    const order = CustomizationOrder(
      id: 'cn-quote',
      characterName: '大陆用户角色',
      sourceType: '原创角色',
      status: '平台审核报价',
      marketRegion: 'cn_mainland',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PlatformQuoteReviewPage(
          order: order,
          repository: MemoryCustomizationOrderRepository(),
        ),
      ),
    );
    expect(find.text('CNY'), findsOneWidget);
  });

  testWidgets('Hong Kong orders default to HKD', (tester) async {
    const order = CustomizationOrder(
      id: 'hk-quote',
      characterName: '香港用户角色',
      sourceType: '原创角色',
      status: '平台审核报价',
      marketRegion: 'hk',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PlatformQuoteReviewPage(
          order: order,
          repository: MemoryCustomizationOrderRepository(),
        ),
      ),
    );
    expect(find.text('HKD'), findsOneWidget);
  });

  testWidgets('Macao orders default to MOP', (tester) async {
    const order = CustomizationOrder(
      id: 'mo-quote',
      characterName: '澳门用户角色',
      sourceType: '原创角色',
      status: '平台审核报价',
      marketRegion: 'mo',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PlatformQuoteReviewPage(
          order: order,
          repository: MemoryCustomizationOrderRepository(),
        ),
      ),
    );
    expect(find.text('MOP'), findsOneWidget);
  });

  testWidgets('Taiwan orders default to TWD', (tester) async {
    const order = CustomizationOrder(
      id: 'tw-quote',
      characterName: '台湾用户角色',
      sourceType: '原创角色',
      status: '平台审核报价',
      marketRegion: 'tw',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PlatformQuoteReviewPage(
          order: order,
          repository: MemoryCustomizationOrderRepository(),
        ),
      ),
    );
    expect(find.text('TWD'), findsOneWidget);
  });

  test('non-default quote currency requires an audit reason', () async {
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'currency-override',
          characterName: '日本订单',
          sourceType: '原创角色',
          status: '平台审核报价',
          marketRegion: 'jp',
        ),
      ],
    );

    await orders.publishPlatformQuote(
      orderId: 'currency-override',
      amountCents: 12900,
      currency: 'USD',
      includedRevisions: 2,
      estimatedDeliveryDays: 10,
    );
    expect((await orders.loadOrders()).single.status, '平台审核报价');

    await orders.publishPlatformQuote(
      orderId: 'currency-override',
      amountCents: 12900,
      currency: 'USD',
      currencyOverrideReason: '用户书面要求使用美元结算',
      includedRevisions: 2,
      estimatedDeliveryDays: 10,
    );
    final quoted = (await orders.loadOrders()).single;
    expect(quoted.status, '待确认报价');
    expect(quoted.quoteCurrencyOverrideReason, '用户书面要求使用美元结算');
  });

  test('mainland creators settle in CNY while all others settle in USD',
      () async {
    Future<CustomizationOrder> proposalFor(String region) async {
      final orders = MemoryCustomizationOrderRepository(
        initialOrders: const [
          CustomizationOrder(
            id: 'creator-currency',
            characterName: '创作者结算测试',
            sourceType: '原创角色',
            status: '创作者评估中',
            assignedCreatorId: 'creator-1',
          ),
        ],
      );
      await orders.submitCreatorProposal(
        orderId: 'creator-currency',
        creatorId: 'creator-1',
        creatorMarketRegion: region,
        suggestedAmountCents: 11000,
        estimatedDeliveryDays: 10,
      );
      return (await orders.loadOrders()).single;
    }

    expect((await proposalFor('cn_mainland')).creatorSuggestedCurrency, 'CNY');
    expect((await proposalFor('jp')).creatorSuggestedCurrency, 'USD');
    expect((await proposalFor('hk')).creatorSuggestedCurrency, 'USD');
  });

  testWidgets('platform operations queue advances approved pre-review',
      (tester) async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(
      characterName: '等待预审的角色',
      sourceType: '原创角色',
      requestedFeatures: ['待机动作'],
    );

    await tester.pumpWidget(
      MaterialApp(home: PlatformOperationsPage(repository: orders)),
    );
    await tester.pumpAndSettle();

    expect(find.text('待平台预审'), findsOneWidget);
    await tester.tap(find.text('等待预审的角色'));
    await tester.pumpAndSettle();
    expect(find.text('平台免费预审'), findsOneWidget);
    await tester.tap(find.text('通过预审并开放匹配'));
    await tester.pumpAndSettle();
    expect(find.text('确认预审检查'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '确认通过'))
            .onPressed,
        isNull);
    for (final code in [
      'rights_verified',
      'materials_safe',
      'content_allowed',
      'device_compatible',
    ]) {
      await tester.tap(find.byKey(Key('review-check-$code')));
      await tester.pump();
    }
    await tester.tap(find.text('确认通过'));
    await tester.pumpAndSettle();

    expect(find.text('待派单'), findsOneWidget);
    final approved = (await orders.loadOrders()).single;
    expect(approved.status, '待创作者申请');
    expect(approved.reviewDecision, 'approved');
    expect(approved.reviewChecks, hasLength(4));
    expect(approved.reviewerId, 'platform-reviewer-local');
    expect(approved.reviewPolicyVersion, 'customization-review-v1');
    expect(approved.reviewedAt, isNotNull);
    expect(approved.materialDeletionScheduledAt, isNull);
    expect(approved.operationsAssigneeId, 'platform-operator-local');
    expect(approved.operationsAuditTrail.last, contains('|claimed|'));
  });

  test('incomplete review checklist cannot approve an order', () async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(characterName: '待审核角色', sourceType: '原创角色');
    final id = (await orders.loadOrders()).single.id;

    await orders.approveForCreatorMatching(
      id,
      reviewChecks: const [
        'rights_verified',
        'materials_safe',
        'content_allowed',
      ],
    );

    final unchanged = (await orders.loadOrders()).single;
    expect(unchanged.status, '免费预审中');
    expect(unchanged.reviewDecision, isNull);
    expect(unchanged.reviewedAt, isNull);
  });

  test('rejected pre-review requires and records a reason', () async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(
      characterName: '权利不清的角色',
      sourceType: '原创角色',
      requestedFeatures: ['角色记忆'],
    );
    final id = (await orders.loadOrders()).single.id;

    await orders.rejectReview(orderId: id, reason: '  ');
    expect((await orders.loadOrders()).single.status, '免费预审中');

    await orders.rejectReview(
      orderId: id,
      reason: '需要补充可验证的原创过程',
      reasonCode: 'rights_unverified',
    );
    final rejected = (await orders.loadOrders()).single;
    expect(rejected.status, '预审未通过');
    expect(rejected.reviewDecision, 'rejected');
    expect(rejected.reviewReasonCode, 'rights_unverified');
    expect(rejected.reviewNote, '需要补充可验证的原创过程');
    expect(rejected.reviewerId, 'platform-reviewer-local');
    expect(rejected.reviewPolicyVersion, 'customization-review-v1');
    expect(rejected.reviewedAt, isNotNull);
    expect(rejected.materialDeletionScheduledAt, isNotNull);
    expect(
        DateTime.parse(rejected.materialDeletionScheduledAt!)
            .isAfter(DateTime.now()),
        isTrue);
  });

  testWidgets('platform selects a standard rejection category', (tester) async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(characterName: '待审核角色', sourceType: '原创角色');
    final order = (await orders.loadOrders()).single;

    await tester.pumpWidget(
      MaterialApp(
        home: PlatformPreReviewPage(order: order, repository: orders),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('预审不通过'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('review-rejection-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('权利或授权无法验证').last);
    await tester.enterText(
      find.byKey(const Key('review-rejection-reason')),
      '请提供可验证的授权文件',
    );
    await tester.tap(find.text('确认拒绝'));
    await tester.pumpAndSettle();

    final rejected = (await orders.loadOrders()).single;
    expect(rejected.reviewReasonCode, 'rights_unverified');
    expect(rejected.reviewNote, '请提供可验证的授权文件');
  });

  testWidgets('终态处置完成返回队列后自动释放运营租约', (tester) async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(characterName: '终态释放角色', sourceType: '原创角色');

    await tester.pumpWidget(
      MaterialApp(home: PlatformOperationsPage(repository: orders)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('终态释放角色'));
    await tester.pumpAndSettle();
    expect(find.text('平台免费预审'), findsOneWidget);

    await tester.tap(find.text('预审不通过'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('review-rejection-reason')),
      '素材权利证明不足',
    );
    await tester.tap(find.text('确认拒绝'));
    await tester.pumpAndSettle();

    final rejected = (await orders.loadOrders()).single;
    expect(rejected.status, '预审未通过');
    expect(rejected.operationsAssigneeId, isNull);
    expect(rejected.operationsAuditTrail.last, contains('|released|'));
    expect(find.text('终态释放角色'), findsNothing);
  });

  test('review audit metadata survives serialization', () {
    const order = CustomizationOrder(
      id: 'audit-1',
      characterName: '审计角色',
      sourceType: '原创角色',
      status: '待创作者申请',
      reviewDecision: 'approved',
      reviewChecks: ['rights_verified', 'materials_safe'],
      reviewerId: 'reviewer-42',
      reviewPolicyVersion: 'customization-review-v1',
      reviewedAt: '2026-09-09T10:00:00Z',
    );

    final restored = CustomizationOrder.fromJson(order.toJson());
    expect(restored?.reviewerId, 'reviewer-42');
    expect(restored?.reviewPolicyVersion, 'customization-review-v1');
    expect(restored?.reviewChecks, ['rights_verified', 'materials_safe']);
    expect(restored?.reviewedAt, '2026-09-09T10:00:00Z');
  });

  testWidgets('rejected pre-review shows reason and blocks payment',
      (tester) async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(
      characterName: '权利不清的角色',
      sourceType: '原创角色',
      requestedFeatures: ['角色记忆'],
    );
    final id = (await orders.loadOrders()).single.id;
    await orders.rejectReview(orderId: id, reason: '需要补充可验证的原创过程');
    final rejected = (await orders.loadOrders()).single;

    await tester.pumpWidget(
      MaterialApp(
        home: CustomizationOrderDetailPage(
          order: rejected,
          repository: orders,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('预审未通过'), findsAtLeastNWidgets(1));
    expect(find.text('需要补充可验证的原创过程'), findsAtLeastNWidgets(1));
    expect(find.textContaining('本次未产生费用'), findsOneWidget);
    expect(find.text('参考素材删除计划'), findsOneWidget);
    expect(find.text('确认报价，前往支付'), findsNothing);
    expect(find.text('查看付款前确认'), findsNothing);

    await tester.tap(find.text('立即删除'));
    await tester.pumpAndSettle();
    expect(find.text('立即删除参考素材？'), findsOneWidget);
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();
    expect(find.text('参考素材已删除'), findsOneWidget);
    final deleted = (await orders.loadOrders()).single;
    expect(deleted.materialDeletedAt, isNotNull);
    expect(deleted.materialDeletionRequestedAt, isNotNull);

    await tester.scrollUntilVisible(
      find.text('补充资料并重新申请'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('补充资料并重新申请'));
    await tester.pumpAndSettle();

    expect(find.text('Free review'), findsOneWidget);
    expect(find.textContaining('Updating request'), findsOneWidget);
    final reviewPosition =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    reviewPosition.jumpTo(reviewPosition.maxScrollExtent / 2);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '权利不清的角色');
    final memoryChip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Character memory'),
    );
    expect(memoryChip.selected, isTrue);
  });

  test('resubmitted review links to the rejected order', () async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(characterName: '初次申请', sourceType: '原创手办');
    final originalId = (await orders.loadOrders()).single.id;
    await orders.rejectReview(orderId: originalId, reason: '缺少背面照片');

    final submitted = await orders.submitReview(
      characterName: '初次申请',
      sourceType: '原创手办',
      requestedFeatures: ['待机动作'],
      materialCount: 3,
      resubmissionOfOrderId: originalId,
      resubmissionReason: '缺少背面照片',
    );

    final allOrders = await orders.loadOrders();
    expect(submitted, isTrue);
    expect(allOrders.first.status, '免费预审中');
    expect(allOrders.first.resubmissionOfOrderId, originalId);
    expect(allOrders.first.resubmissionReason, '缺少背面照片');
    expect(allOrders.last.status, '预审未通过');
  });

  testWidgets('platform reviewer sees the previous rejection reason',
      (tester) async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(characterName: '重审角色', sourceType: '原创手办');
    final originalId = (await orders.loadOrders()).single.id;
    await orders.rejectReview(orderId: originalId, reason: '缺少背面照片');
    await orders.submitReview(
      characterName: '重审角色',
      sourceType: '原创手办',
      materialCount: 3,
      resubmissionOfOrderId: originalId,
      resubmissionReason: '缺少背面照片',
    );

    await tester.pumpWidget(
      MaterialApp(home: PlatformOperationsPage(repository: orders)),
    );
    await tester.pumpAndSettle();

    expect(find.text('待平台预审 · 整改重审'), findsOneWidget);
    await tester.tap(find.text('重审角色'));
    await tester.pumpAndSettle();

    expect(find.textContaining('上次未通过原因：缺少背面照片'), findsOneWidget);
    expect(find.textContaining('请重点核验新素材是否已经补齐'), findsOneWidget);
  });

  test('only one active resubmission is allowed for a rejected order',
      () async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(characterName: '初次申请', sourceType: '原创角色');
    final originalId = (await orders.loadOrders()).single.id;
    await orders.rejectReview(orderId: originalId, reason: '请补充原创过程');

    final first = await orders.submitReview(
      characterName: '初次申请',
      sourceType: '原创角色',
      resubmissionOfOrderId: originalId,
    );
    final duplicate = await orders.submitReview(
      characterName: '初次申请',
      sourceType: '原创角色',
      resubmissionOfOrderId: originalId,
    );

    expect(first, isTrue);
    expect(duplicate, isFalse);
    expect(await orders.loadOrders(), hasLength(2));
  });

  test('due material cleanup is auditable and idempotent', () async {
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'due',
          characterName: '到期角色',
          sourceType: '原创角色',
          status: '预审未通过',
          materialCount: 4,
          materialDeletionScheduledAt: '2026-09-01T00:00:00Z',
        ),
        CustomizationOrder(
          id: 'future',
          characterName: '未到期角色',
          sourceType: '原创角色',
          status: '预审未通过',
          materialCount: 3,
          materialDeletionScheduledAt: '2026-10-01T00:00:00Z',
        ),
      ],
    );
    final now = DateTime.parse('2026-09-09T12:00:00Z');

    expect(await orders.processDueMaterialDeletions(now: now), 1);
    final loaded = await orders.loadOrders();
    final due = loaded.firstWhere((order) => order.id == 'due');
    final future = loaded.firstWhere((order) => order.id == 'future');
    expect(due.materialCount, 0);
    expect(due.materialDeletedAt, now.toIso8601String());
    expect(future.materialCount, 3);
    expect(future.materialDeletedAt, isNull);
    expect(await orders.processDueMaterialDeletions(now: now), 0);
  });

  test('active orders cannot delete production materials', () async {
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'active',
          characterName: '制作中角色',
          sourceType: '原创角色',
          status: '制作中',
          materialCount: 4,
        ),
      ],
    );

    expect(await orders.requestImmediateMaterialDeletion('active'), isFalse);
    final unchanged = (await orders.loadOrders()).single;
    expect(unchanged.materialCount, 4);
    expect(unchanged.materialDeletedAt, isNull);
  });

  test('personal data export excludes media and internal references', () async {
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'privacy-export',
          characterName: '数据副本角色',
          sourceType: '原创角色',
          status: '待用户验收',
          requestedFeatures: ['角色记忆'],
          privacyConsentVersion: 'customization-privacy-v1',
          previewReference: 'private-preview-token',
          paymentReference: 'private-payment-reference',
          assignedCreatorId: 'internal-creator-id',
          reviewerId: 'internal-reviewer-id',
        ),
      ],
    );

    final data = await orders.exportPersonalData('privacy-export');
    expect(data?['orderId'], 'privacy-export');
    expect(data?['characterName'], '数据副本角色');
    expect(data?['mediaIncluded'], isFalse);
    expect(data, isNot(contains('previewReference')));
    expect(data, isNot(contains('paymentReference')));
    expect(data, isNot(contains('assignedCreatorId')));
    expect(data, isNot(contains('reviewerId')));
  });

  testWidgets(
      'privacy correction is queued and resolved without changing order status',
      (tester) async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(characterName: '名称需要更正', sourceType: '原创角色');
    final order = (await orders.loadOrders()).single;
    expect(
      await orders.requestPrivacyCorrection(
        orderId: order.id,
        note: '角色名称中的一个字填写错误',
      ),
      isTrue,
    );
    expect(
      await orders.requestPrivacyCorrection(orderId: order.id, note: '重复请求'),
      isFalse,
    );
    final pending = (await orders.loadOrders()).single;
    final requestedAt = DateTime.parse(pending.privacyCorrectionRequestedAt!);
    final dueAt = DateTime.parse(pending.privacyCorrectionDueAt!);
    expect(dueAt.difference(requestedAt), const Duration(days: 30));

    await tester.pumpWidget(
      MaterialApp(home: PlatformOperationsPage(repository: orders)),
    );
    await tester.pumpAndSettle();
    expect(find.text('待处理数据更正'), findsOneWidget);
    await tester.tap(find.text('名称需要更正'));
    await tester.pumpAndSettle();
    expect(find.text('角色名称中的一个字填写错误'), findsOneWidget);
    await tester.tap(find.text('确认已核验并受理'));
    await tester.pumpAndSettle();
    expect(find.text('填写受理结果'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('privacy-correction-resolution')),
      '身份已核验，展示名称将在下一次同步时更新',
    );
    await tester.tap(find.text('提交处理结果'));
    await tester.pumpAndSettle();

    final resolved = (await orders.loadOrders()).single;
    expect(resolved.status, '免费预审中');
    expect(resolved.privacyCorrectionStatus, 'approved');
    expect(
      resolved.privacyCorrectionResolutionNote,
      '身份已核验，展示名称将在下一次同步时更新',
    );
    expect(resolved.privacyCorrectionResolverId, 'platform-reviewer-local');
    expect(resolved.privacyCorrectionResolvedAt, isNotNull);
  });

  testWidgets('overdue privacy correction is highlighted in operations queue',
      (tester) async {
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'overdue-privacy',
          characterName: '逾期数据请求',
          sourceType: '原创角色',
          status: '免费预审中',
          privacyCorrectionStatus: 'pending',
          privacyCorrectionNote: '更正名称',
          privacyCorrectionDueAt: '2020-01-01T00:00:00Z',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: PlatformOperationsPage(repository: orders)),
    );
    await tester.pumpAndSettle();

    expect(find.text('隐私逾期 1'), findsOneWidget);
    expect(find.text('数据更正已逾期'), findsOneWidget);
  });

  testWidgets('checkout confirms controlled delivery without charging',
      (tester) async {
    const order = CustomizationOrder(
      id: 'checkout-1',
      characterName: '星际狐狸',
      sourceType: '原创角色',
      status: '待支付',
      requestedFeatures: ['待机动作'],
      quoteAmountCents: 12900,
      quoteCurrency: 'USD',
      includedRevisions: 2,
      estimatedDeliveryDays: 12,
    );
    await tester.pumpWidget(
      const MaterialApp(home: CheckoutReviewPage(order: order)),
    );

    expect(find.text('USD 129.00'), findsOneWidget);
    expect(find.textContaining('不提供原视频'), findsOneWidget);
    expect(find.text('请先确认交付范围'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(find.text('支付服务尚未接入'), findsOneWidget);
    expect(find.text('当前原型不会发起扣款'), findsOneWidget);
  });

  test('user can decline a published quote without payment', () async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(characterName: '星际狐狸', sourceType: '原创角色');
    final id = (await orders.loadOrders()).single.id;
    await approveReview(orders, id);
    await assignCreator(orders, id, 'creator-1');
    await orders.submitCreatorProposal(
      orderId: id,
      creatorId: 'creator-1',
      suggestedAmountCents: 11000,
      estimatedDeliveryDays: 10,
    );
    await orders.publishPlatformQuote(
      orderId: id,
      amountCents: 12900,
      currency: 'USD',
      includedRevisions: 2,
      estimatedDeliveryDays: 12,
    );

    await orders.declineQuote(id);

    expect((await orders.loadOrders()).single.status, '已拒绝报价');
  });

  testWidgets('submits a free review before any payment', (tester) async {
    final orders = MemoryCustomizationOrderRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: CharacterSourcePage(
          orderRepository: orders,
          materialPicker: () async => ['front.png', 'side.png'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('This is the character I want'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose photos'));
    await tester.pumpAndSettle();
    final reviewPosition =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    reviewPosition
        .jumpTo(600.0.clamp(0.0, reviewPosition.maxScrollExtent).toDouble());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '星际狐狸');
    await tester.ensureVisible(find.text('Idle motion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Idle motion'));
    reviewPosition.jumpTo(reviewPosition.maxScrollExtent);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('market-region')));
    await tester.pumpAndSettle();
    expect(find.text('Mainland China'), findsOneWidget);
    expect(find.text('Hong Kong, China'), findsOneWidget);
    expect(find.text('Macao, China'), findsOneWidget);
    expect(find.text('Taiwan, China'), findsOneWidget);
    expect(find.text('Other Asian region'), findsOneWidget);
    await tester.tap(find.text('Japan').last);
    await tester.pumpAndSettle();
    final consentTiles = tester
        .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
        .toList();
    expect(consentTiles, hasLength(2));
    for (final tile in consentTiles) {
      tile.onChanged!(true);
      await tester.pump();
    }
    final submitButton = find.text('Submit free review');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Free review submitted'), findsOneWidget);
    expect(find.textContaining('Payment begins only after'), findsOneWidget);
    final saved = await orders.loadOrders();
    expect(saved.single.characterName, '星际狐狸');
    expect(saved.single.status, '免费预审中');
    expect(saved.single.requestedFeatures, ['待机动作']);
    expect(saved.single.marketRegion, 'jp');
    expect(
      saved.single.privacyConsentVersion,
      'customization-privacy-jp-v1',
    );
    expect(saved.single.materialCount, 2);
    expect(saved.single.privacyConsentAt, isNotNull);
  });

  testWidgets('shows customization progress in my characters', (tester) async {
    final orders = MemoryCustomizationOrderRepository();
    await orders.submitReview(characterName: '星际狐狸', sourceType: '原创角色');
    await tester.pumpWidget(
      MaterialApp(
        home: MyCharactersPage(
          repository: MemoryCharacterEntitlementRepository(),
          orderRepository: orders,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('定制进度'), findsOneWidget);
    expect(find.text('星际狐狸'), findsOneWidget);
    await tester.tap(find.text('星际狐狸'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('付款尚未开放'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('付款尚未开放'), findsOneWidget);
    expect(find.text('免费撤回申请'), findsOneWidget);
    final withdrawButton = find.text('免费撤回申请');
    await tester.ensureVisible(withdrawButton);
    await tester.pumpAndSettle();
    await tester.tap(withdrawButton);
    await tester.pumpAndSettle();

    expect(find.text('申请已撤回'), findsOneWidget);
    final withdrawn = (await orders.loadOrders()).single;
    expect(withdrawn.status, '已撤回');
    expect(withdrawn.materialDeletionScheduledAt, isNotNull);
  });

  testWidgets('routes third-party IP request away from paid customization',
      (tester) async {
    await tester.pumpWidget(buildSubject());

    final reviewEntry = find.text('免费预审并获取报价');
    await tester.scrollUntilVisible(
      reviewEntry,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(reviewEntry);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('This is a game or anime character I like'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Without applicable rights'), findsOneWidget);
    expect(find.text('Submit a character wish'), findsOneWidget);
  });
}
