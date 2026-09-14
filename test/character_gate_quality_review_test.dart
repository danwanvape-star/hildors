import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_quality_review.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';

class _UnconfirmedQualityRepository extends MemoryCustomizationOrderRepository {
  _UnconfirmedQualityRepository(List<CustomizationOrder> superOrders)
      : super(initialOrders: superOrders);
  bool ignoreSubmission = true;
  @override
  Future<void> submitContentQualityReview({
    required String orderId,
    required int expectedPreviewVersion,
    required CharacterQualityReview review,
  }) async {
    if (!ignoreSubmission) {
      await super.submitContentQualityReview(
          orderId: orderId,
          expectedPreviewVersion: expectedPreviewVersion,
          review: review);
    }
  }
}

void main() {
  testWidgets('质检逾期仍进入交付超期统计且保留质检入口', (tester) async {
    final orders = MemoryCustomizationOrderRepository(initialOrders: const [
      CustomizationOrder(
        id: 'overdue-quality',
        characterName: '逾期质检角色',
        sourceType: '原创角色',
        status: '待平台质检',
        productionDueAt: '2020-01-01T00:00:00Z',
      ),
    ]);
    await tester.pumpWidget(
        MaterialApp(home: PlatformOperationsPage(repository: orders)));
    await tester.pumpAndSettle();
    expect(find.text('交付逾期 1'), findsOneWidget);
    final entry = find.text('逾期质检角色');
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.text('平台内容质检'), findsOneWidget);
    expect((await orders.loadOrders()).single.productionDueAt,
        '2020-01-01T00:00:00Z');
  });

  for (final alreadyInRepair in [false, true]) {
    testWidgets('返工提交核验本次记录：旧修改状态=$alreadyInRepair', (tester) async {
      const order = CustomizationOrder(
        id: 'repair-confirmation',
        characterName: '返工提交角色',
        sourceType: '原创角色',
        status: '待平台质检',
      );
      final orders = _UnconfirmedQualityRepository([
        alreadyInRepair ? order.copyWith(status: '修改中') : order,
      ]);
      await tester.pumpWidget(MaterialApp(
          home: Builder(
        builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => PlatformQualityReviewPage(
                      order: order, repository: orders),
                )),
            child: const Text('打开质检')),
      )));
      await tester.tap(find.text('打开质检'));
      await tester.pumpAndSettle();
      final version = find.byKey(const Key('quality-package-version'));
      await tester.ensureVisible(version);
      await tester.enterText(version, '2.0.0');
      final picker = find.byKey(const Key('quality-failed-check'));
      await tester.ensureVisible(picker);
      await tester.pumpAndSettle();
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('媒体文件完整且可解码').last);
      await tester.pumpAndSettle();
      final note = find.byKey(const Key('quality-failure-note'));
      await tester.ensureVisible(note);
      await tester.enterText(note, '文件无法解码，请重新编码');
      final submit = find.text('退回创作者返工');
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('平台内容质检'), findsOneWidget);
      expect(find.text('未确认质检返工，已保留填写内容，请核对订单状态后重试'), findsOneWidget);
      expect(tester.widget<TextField>(note).controller!.text, '文件无法解码，请重新编码');
      if (!alreadyInRepair) {
        orders.ignoreSubmission = false;
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(find.text('平台内容质检'), findsNothing);
        expect((await orders.loadOrders()).single.qualityReview.failureNote,
            '文件无法解码，请重新编码');
      }
    });
  }

  testWidgets('未保存的质检放行不会关闭表单且可以重试', (tester) async {
    const order = CustomizationOrder(
      id: 'unconfirmed-quality',
      characterName: '提交确认角色',
      sourceType: '原创角色',
      status: '待平台质检',
    );
    final orders = _UnconfirmedQualityRepository([order]);
    await tester.pumpWidget(MaterialApp(
        home: Builder(
      builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) =>
                    PlatformQualityReviewPage(order: order, repository: orders),
              )),
          child: const Text('打开质检')),
    )));
    await tester.tap(find.text('打开质检'));
    await tester.pumpAndSettle();
    for (final check in requiredCharacterQualityChecks) {
      final checkbox = find.byKey(Key('quality-check-$check'));
      await tester.ensureVisible(checkbox);
      await tester.pumpAndSettle();
      await tester.tap(checkbox);
    }
    final version = find.byKey(const Key('quality-package-version'));
    await tester.ensureVisible(version);
    await tester.enterText(version, '2.0.0');
    final submit = find.text('全部通过并提交用户验收');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('平台内容质检'), findsOneWidget);
    expect(find.text('未确认质检放行，已保留填写内容，请核对订单状态后重试'), findsOneWidget);
    expect(tester.widget<TextField>(version).controller!.text, '2.0.0');
    expect((await orders.loadOrders()).single.status, '待平台质检');
    orders.ignoreSubmission = false;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('平台内容质检'), findsNothing);
    expect((await orders.loadOrders()).single.status, '待用户验收');
  });

  testWidgets('创作者可看到平台返工原因和受检版本', (tester) async {
    final orders = MemoryCustomizationOrderRepository(initialOrders: const [
      CustomizationOrder(
        id: 'repair-visible',
        characterName: '返工说明角色',
        sourceType: '原创角色',
        status: '修改中',
        assignedCreatorId: 'local-certified-creator',
        qualityReview: CharacterQualityReview(
          results: {'device_playback': CharacterQualityCheckResult.failed},
          failureNote: '黑屏，请修复编码',
          deviceModel: 'P20',
          packageVersion: 'v2',
        ),
      ),
    ]);
    await tester.pumpWidget(MaterialApp(
      home: CreatorTaskBoardPage(orderRepository: orders),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('quality-repair-note-repair-visible')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('平台质检返工：黑屏，请修复编码'), findsOneWidget);
    expect(find.text('受检内容包：v2 · 设备：P20'), findsOneWidget);
  });

  test('平台返工不扣用户修改次数且新预览必须重新质检', () async {
    final orders = MemoryCustomizationOrderRepository(initialOrders: const [
      CustomizationOrder(
        id: 'repair',
        characterName: '返工角色',
        sourceType: '原创角色',
        status: '待平台质检',
        assignedCreatorId: 'creator',
        previewVersion: 1,
        revisionsUsed: 1,
      ),
    ]);
    await orders.submitContentQualityReview(
      orderId: 'repair',
      expectedPreviewVersion: 1,
      review: const CharacterQualityReview(
        results: {'device_playback': CharacterQualityCheckResult.failed},
        failureNote: '播放时黑屏，请修复编码',
        reviewerId: 'reviewer',
        deviceModel: 'P20',
        packageVersion: '1',
        reviewedAt: '2026-09-10T10:00:00Z',
      ),
    );
    var order = (await orders.loadOrders()).single;
    expect(order.status, '修改中');
    expect(order.revisionsUsed, 1);
    expect(order.qualityReview.failureNote, '播放时黑屏，请修复编码');
    await orders.submitCreatorPreview(
      orderId: 'repair',
      creatorId: 'creator',
      previewReference: 'v2',
    );
    order = (await orders.loadOrders()).single;
    expect(order.status, '待平台质检');
    expect(order.previewVersion, 2);
    expect(order.qualityReview.results, isEmpty);
    expect(order.qualityReview.canRelease, isFalse);
    expect(order.revisionsUsed, 1);
    final validReview = CharacterQualityReview(
      results: {
        for (final check in requiredCharacterQualityChecks)
          check: CharacterQualityCheckResult.passed
      },
      reviewerId: 'reviewer',
      deviceModel: 'P20',
      packageVersion: 'v2',
      reviewedAt: '2026-09-10T11:00:00Z',
    );
    await orders.submitContentQualityReview(
      orderId: 'repair',
      expectedPreviewVersion: 1,
      review: validReview,
    );
    expect((await orders.loadOrders()).single.status, '待平台质检');
    expect((await orders.loadOrders()).single.qualityReview.results, isEmpty);
    await orders.submitContentQualityReview(
      orderId: 'repair',
      expectedPreviewVersion: 1,
      review: const CharacterQualityReview(
        results: {'device_playback': CharacterQualityCheckResult.failed},
        failureNote: '旧页面的失败结论',
      ),
    );
    expect((await orders.loadOrders()).single.status, '待平台质检');
    await orders.submitContentQualityReview(
      orderId: 'repair',
      expectedPreviewVersion: 2,
      review: validReview,
    );
    expect((await orders.loadOrders()).single.status, '待用户验收');
  });

  test('损坏的质检元数据不会导致读取崩溃或允许放行', () {
    final valid = {
      'results': {
        for (final check in requiredCharacterQualityChecks) check: 'passed',
      },
      'reviewerId': 'reviewer-1',
      'deviceModel': 'P20',
      'packageVersion': '1.0.0',
      'reviewedAt': '2026-09-10T10:00:00Z',
    };
    for (final field in [
      'reviewerId',
      'deviceModel',
      'packageVersion',
      'reviewedAt',
    ]) {
      for (final damaged in [null, 42, false, <String>[], '', '   ']) {
        final review = CharacterQualityReview.fromJson({
          ...valid,
          field: damaged,
        });
        expect(review.canRelease, isFalse, reason: '$field=$damaged');
      }
    }
    expect(
      CharacterQualityReview.fromJson({
        ...valid,
        'reviewedAt': 'not-a-date',
      }).canRelease,
      isFalse,
    );
    expect(
      CharacterQualityReview.fromJson({...valid, 'failureNote': 42})
          .failureNote,
      isNull,
    );
  });

  test('质检缺少任一必检项时不能放行', () {
    final review = CharacterQualityReview(
      results: {
        for (final check in requiredCharacterQualityChecks)
          if (check != 'device_recovery')
            check: CharacterQualityCheckResult.passed,
      },
      reviewerId: 'reviewer-1',
      deviceModel: 'P20',
      packageVersion: '1.0.0',
      reviewedAt: '2026-09-10T10:00:00Z',
    );

    expect(review.canRelease, isFalse);
    expect(review.missingChecks, {'device_recovery'});
  });

  test('质检失败时不能放行', () {
    final review = CharacterQualityReview(
      results: {
        for (final check in requiredCharacterQualityChecks)
          check: check == 'audio_sync'
              ? CharacterQualityCheckResult.failed
              : CharacterQualityCheckResult.passed,
      },
      reviewerId: 'reviewer-1',
      deviceModel: 'P20',
      packageVersion: '1.0.0',
      reviewedAt: '2026-09-10T10:00:00Z',
      failureNote: '音画不同步',
    );

    expect(review.hasFailure, isTrue);
    expect(review.canRelease, isFalse);
  });

  test('全部检查和真机证据齐全后才能放行', () {
    final review = CharacterQualityReview(
      results: {
        for (final check in requiredCharacterQualityChecks)
          check: CharacterQualityCheckResult.passed,
      },
      reviewerId: 'reviewer-1',
      deviceModel: 'P20',
      packageVersion: '1.0.0',
      reviewedAt: '2026-09-10T10:00:00Z',
    );

    expect(review.canRelease, isTrue);
    expect(review.missingChecks, isEmpty);
    expect(
      CharacterQualityReview.fromJson(review.toJson()).canRelease,
      isTrue,
    );
  });

  test('未知或损坏的检查结果按未测试处理', () {
    final restored = CharacterQualityReview.fromJson({
      'results': {
        'media_integrity': 'unexpected',
        'unknown_check': 'passed',
      },
    });

    expect(
      restored.results['media_integrity'],
      CharacterQualityCheckResult.notTested,
    );
    expect(restored.results.containsKey('unknown_check'), isFalse);
    expect(restored.canRelease, isFalse);
  });

  test('订单必须通过平台质检后才能进入用户验收', () async {
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [
        CustomizationOrder(
          id: 'quality-gate-order',
          characterName: '质检闸门角色',
          sourceType: '原创角色',
          status: '待平台质检',
          previewReference: 'protected-preview-v1',
        ),
      ],
    );
    await orders.approveDelivery('quality-gate-order');
    expect((await orders.loadOrders()).single.status, '待平台质检');

    final passed = CharacterQualityReview(
      results: {
        for (final check in requiredCharacterQualityChecks)
          check: CharacterQualityCheckResult.passed,
      },
      reviewerId: 'quality-reviewer-1',
      deviceModel: 'P20',
      packageVersion: '1.0.0',
      reviewedAt: '2026-09-10T10:00:00Z',
    );
    await orders.submitContentQualityReview(
      orderId: 'quality-gate-order',
      expectedPreviewVersion: 0,
      review: passed,
    );

    final reviewed = (await orders.loadOrders()).single;
    expect(reviewed.status, '待用户验收');
    expect(reviewed.qualityReview.canRelease, isTrue);
    expect(
      CustomizationOrder.fromJson(reviewed.toJson())?.qualityReview.canRelease,
      isTrue,
    );
  });

  testWidgets('平台质检表单完成全部检查后开放提交', (tester) async {
    const order = CustomizationOrder(
      id: 'quality-form-order',
      characterName: '质检表单角色',
      sourceType: '原创角色',
      status: '待平台质检',
      previewReference: 'protected-preview-v1',
    );
    final orders = MemoryCustomizationOrderRepository(
      initialOrders: const [order],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PlatformQualityReviewPage(order: order, repository: orders),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('全部通过并提交用户验收'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final submit = find.widgetWithText(FilledButton, '全部通过并提交用户验收');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    for (final check in requiredCharacterQualityChecks) {
      final checkbox = find.byKey(Key('quality-check-$check'));
      await tester.ensureVisible(checkbox);
      await tester.pumpAndSettle();
      await tester.tap(checkbox);
    }
    final version = find.byKey(const Key('quality-package-version'));
    await tester.ensureVisible(version);
    await tester.enterText(version, '1.0.0');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

    final failurePicker = find.byKey(const Key('quality-failed-check'));
    await tester.ensureVisible(failurePicker);
    await tester.pumpAndSettle();
    await tester.tap(failurePicker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('媒体文件完整且可解码').last);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.tap(failurePicker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('未标记失败（撤销失败选择）').last);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(submit).onPressed, isNull,
        reason: '撤销失败不能自动把该检查改为通过');
    final mediaCheck = find.byKey(const Key('quality-check-media_integrity'));
    await tester.ensureVisible(mediaCheck);
    await tester.pumpAndSettle();
    await tester.tap(mediaCheck);
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

    await tester.tap(submit);
    await tester.pumpAndSettle();
    final reviewed = (await orders.loadOrders()).single;
    expect(reviewed.status, '待用户验收');
    expect(reviewed.qualityReview.canRelease, isTrue);
  });
}
