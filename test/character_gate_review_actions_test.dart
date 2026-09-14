import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';

class _Orders extends MemoryCustomizationOrderRepository {
  final pending = Completer<void>();
  int approvals = 0;
  int rejections = 0;
  int cleanups = 0;
  int releases = 0;
  final resolutions = <DisputeResolution>[];
  @override
  Future<void> approveForCreatorMatching(String orderId,
      {required List<String> reviewChecks,
      String reviewerId = 'platform-reviewer-local',
      String reviewPolicyVersion = 'customization-review-v1'}) async {
    approvals++;
    throw StateError('private review failure');
  }

  @override
  Future<void> rejectReview(
      {required String orderId,
      required String reason,
      String reasonCode = 'other',
      String reviewerId = 'platform-reviewer-local',
      String reviewPolicyVersion = 'customization-review-v1'}) async {
    rejections++;
    throw StateError('private rejection failure');
  }

  @override
  Future<void> resolveDispute(
      {required String orderId, required DisputeResolution resolution}) async {
    resolutions.add(resolution);
    await pending.future;
  }

  @override
  Future<int> processDueMaterialDeletions({DateTime? now}) async {
    cleanups++;
    await pending.future;
    return 0;
  }

  @override
  Future<int> processExpiredCreatorAssignments({DateTime? now}) async {
    releases++;
    return 0;
  }
}

const _review = CustomizationOrder(
    id: 'review', characterName: 'Review', sourceType: '原创角色', status: '免费预审中');

Future<void> _open(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(MaterialApp(home: page));
  await tester.pumpAndSettle();
}

Future<void> _scroll(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 180,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'review opens one dialog and retains checks after failed approval',
      (tester) async {
    final repository = _Orders();
    await _open(
        tester, PlatformPreReviewPage(order: _review, repository: repository));
    await _scroll(tester, '通过预审并开放匹配');
    final approve = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, '通过预审并开放匹配'))
        .onPressed!;
    approve();
    approve();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    for (final key in [
      'rights_verified',
      'materials_safe',
      'content_allowed',
      'device_compatible'
    ]) {
      final check = find.byKey(Key('review-check-$key'));
      await tester.ensureVisible(check);
      await tester.tap(check);
      await tester.pump();
    }
    await tester.tap(find.text('确认通过'));
    await tester.pumpAndSettle();
    expect(repository.approvals, 1);
    expect(
        find.textContaining('result could not be confirmed'), findsOneWidget);
    approve();
    await tester.pumpAndSettle();
    expect(
        tester
            .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
            .every((item) => item.value == true),
        isTrue);
  });

  testWidgets('failed rejection restores the explanation on reopening',
      (tester) async {
    final repository = _Orders();
    await _open(
        tester, PlatformPreReviewPage(order: _review, repository: repository));
    await _scroll(tester, '预审不通过');
    await tester.tap(find.text('预审不通过'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('review-rejection-reason')), '请补充授权范围');
    await tester.tap(find.text('确认拒绝'));
    await tester.pumpAndSettle();
    expect(repository.rejections, 1);
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    await tester.tap(find.text('预审不通过'));
    await tester.pumpAndSettle();
    expect(find.text('请补充授权范围'), findsOneWidget);
  });

  testWidgets('opposing dispute decisions are serialized and recover on error',
      (tester) async {
    final repository = _Orders();
    await _open(tester,
        PlatformDisputeReviewPage(order: _review, repository: repository));
    final resume = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, '恢复原订单流程'))
        .onPressed!;
    final refund = tester
        .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '批准进入退款处理'))
        .onPressed!;
    resume();
    refund();
    await tester.pump();
    expect(repository.resolutions, [DisputeResolution.resumeOrder]);
    repository.pending.completeError(StateError('private dispute error'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('result could not be confirmed'), findsOneWidget);
    expect(
        tester
            .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, '批准进入退款处理'))
            .onPressed,
        isNotNull);
  });

  testWidgets('batch actions cannot overlap and unlock after failure',
      (tester) async {
    final repository = _Orders();
    await _open(tester, PlatformOperationsPage(repository: repository));
    await _scroll(tester, '执行到期素材清理');
    final cleanup = tester
        .widget<ActionChip>(find.widgetWithText(ActionChip, '执行到期素材清理'))
        .onPressed!;
    final release =
        tester.widgetList<ActionChip>(find.byType(ActionChip)).first.onPressed!;
    cleanup();
    cleanup();
    release();
    await tester.pump();
    expect(repository.cleanups, 1);
    expect(repository.releases, 0);
    repository.pending.completeError(StateError('private cleanup error'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('result could not be confirmed'), findsOneWidget);
    expect(
        tester
            .widget<ActionChip>(find.widgetWithText(ActionChip, '执行到期素材清理'))
            .onPressed,
        isNotNull);
  });
}
