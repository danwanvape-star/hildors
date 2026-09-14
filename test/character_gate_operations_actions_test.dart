import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';

class _Orders extends MemoryCustomizationOrderRepository {
  _Orders(CustomizationOrder order) : super(initialOrders: [order]);
  final request = Completer<void>();
  int payouts = 0;
  int failures = 0;
  final assignments = <String>[];
  bool failRead = false;
  bool ignoreAssignment = false;

  @override
  Future<List<CustomizationOrder>> loadOrders() {
    if (failRead) return Future.error(StateError('private read failure'));
    return super.loadOrders();
  }

  @override
  Future<void> recordCreatorPayout(
      {required String orderId,
      required String payoutReference,
      required String payoutAccountVerificationReference}) async {
    payouts++;
    await request.future;
    await super.recordCreatorPayout(
        orderId: orderId,
        payoutReference: payoutReference,
        payoutAccountVerificationReference: payoutAccountVerificationReference);
  }

  @override
  Future<void> recordCreatorPayoutFailure(
      {required String orderId,
      required String failureCode,
      required String payoutAccountVerificationReference}) async {
    failures++;
    await super.recordCreatorPayoutFailure(
        orderId: orderId,
        failureCode: failureCode,
        payoutAccountVerificationReference: payoutAccountVerificationReference);
  }

  @override
  Future<void> assignCreator(
      {required String orderId, required String creatorId}) async {
    assignments.add(creatorId);
    if (ignoreAssignment) return;
    await request.future;
    await super.assignCreator(orderId: orderId, creatorId: creatorId);
  }
}

const _payout = CustomizationOrder(
    id: 'payout',
    characterName: 'Payout',
    sourceType: '原创角色',
    status: '已交付',
    settlementStatus: '待结算',
    creatorPayoutCents: 10000,
    creatorPayoutCurrency: 'USD',
    payoutEligibleAt: '2020-01-01T00:00:00Z');
const _assignment = CustomizationOrder(
    id: 'assignment',
    characterName: 'Assignment',
    sourceType: '原创角色',
    status: '待创作者申请',
    applicantCreatorIds: ['a', 'b']);

Future<void> _open(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(MaterialApp(
      home: Builder(
          builder: (context) => Scaffold(
              body: TextButton(
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => page)),
                  child: const Text('Open'))))));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester) async {
  await tester.enterText(
      find.byKey(const Key('payout-account-verification')), 'verified-token');
  await tester.enterText(
      find.byKey(const Key('payout-transaction-reference')), 'transaction-123');
  await tester.scrollUntilVisible(find.text('登记本次放款失败'), 150,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'payout success and failure cannot run together and errors preserve fields',
      (tester) async {
    final repository = _Orders(_payout);
    await _open(tester,
        PlatformPayoutReviewPage(order: _payout, repository: repository));
    await _fill(tester);
    final success = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, '确认支付服务商已放款'))
        .onPressed!;
    final failure = tester
        .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '登记本次放款失败'))
        .onPressed!;
    success();
    success();
    failure();
    await tester.pump();
    expect(repository.payouts, 1);
    expect(repository.failures, 0);
    repository.request.completeError(StateError('private payment detail'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('result could not be confirmed'), findsOneWidget);
    expect(find.text('transaction-123'), findsOneWidget);
    expect(find.text('verified-token'), findsOneWidget);
    failure();
    await tester.pumpAndSettle();
    expect(repository.failures, 1);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('payout read recovery never repeats a recorded payout',
      (tester) async {
    final repository = _Orders(_payout)..failRead = true;
    await _open(tester,
        PlatformPayoutReviewPage(order: _payout, repository: repository));
    await _fill(tester);
    await tester.tap(find.text('确认支付服务商已放款'));
    repository.request.complete();
    await tester.pumpAndSettle();
    expect(find.text('Content could not be loaded'), findsOneWidget);
    repository.failRead = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(repository.payouts, 1);
    expect(find.text('确认支付服务商已放款'), findsNothing);
    expect((await repository.loadOrders()).single.settlementStatus, '已结算');
  });

  testWidgets('assignment serializes candidates and unlocks after failure',
      (tester) async {
    final repository = _Orders(_assignment);
    await _open(
        tester,
        PlatformAssignmentReviewPage(
            order: _assignment, repository: repository));
    final buttons =
        tester.widgetList<FilledButton>(find.byType(FilledButton)).toList();
    buttons[0].onPressed!();
    buttons[1].onPressed!();
    await tester.pump();
    expect(repository.assignments, ['a']);
    repository.request.completeError(StateError('private assignment failure'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('result could not be confirmed'), findsOneWidget);
    expect(
        tester
            .widgetList<FilledButton>(find.byType(FilledButton))
            .every((button) => button.onPressed != null),
        isTrue);
  });

  testWidgets('assignment no-op remains open with an unconfirmed result',
      (tester) async {
    final repository = _Orders(_assignment)..ignoreAssignment = true;
    await _open(
        tester,
        PlatformAssignmentReviewPage(
            order: _assignment, repository: repository));
    await tester.tap(find.text('选择').first);
    await tester.pumpAndSettle();
    expect(find.text('平台选择创作者'), findsOneWidget);
    expect(
        find.textContaining('result could not be confirmed'), findsOneWidget);
    expect((await repository.loadOrders()).single.assignedCreatorId, isNull);
  });
}
