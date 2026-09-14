import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';

class _Orders extends MemoryCustomizationOrderRepository {
  _Orders(CustomizationOrder order) : super(initialOrders: [order]);
  final request = Completer<void>();
  int accepts = 0;
  int declines = 0;
  int approvals = 0;
  bool failRead = false;

  @override
  Future<void> acceptQuote(String orderId) async {
    accepts++;
    await request.future;
    await super.acceptQuote(orderId);
  }

  @override
  Future<void> declineQuote(String orderId) async {
    declines++;
    await super.declineQuote(orderId);
  }

  @override
  Future<void> approveDelivery(String orderId) async {
    approvals++;
    await request.future;
    await super.approveDelivery(orderId);
  }

  @override
  Future<void> requestRevision(String orderId, {required String note}) async {
    throw StateError('private backend detail');
  }

  @override
  Future<List<CustomizationOrder>> loadOrders() {
    if (failRead) return Future.error(StateError('read unavailable'));
    return super.loadOrders();
  }
}

CustomizationOrder _order(String status) => CustomizationOrder(
      id: 'action-order',
      characterName: 'Action character',
      sourceType: '原创角色',
      status: status,
      includedRevisions: 2,
      previewVersion: 1,
    );

Future<void> _open(
    WidgetTester tester, CustomizationOrder order, _Orders repository) async {
  await tester.pumpWidget(MaterialApp(
      home:
          CustomizationOrderDetailPage(order: order, repository: repository)));
  await tester.pumpAndSettle();
}

Future<void> _scroll(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 200,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('quote actions are mutually exclusive and recover after failure',
      (tester) async {
    final order = _order('待确认报价');
    final repository = _Orders(order);
    await _open(tester, order, repository);
    await _scroll(tester, '确认报价，前往支付');
    final accept = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, '确认报价，前往支付'))
        .onPressed!;
    await _scroll(tester, '拒绝报价并结束订单');
    final decline = tester
        .widget<TextButton>(find.widgetWithText(TextButton, '拒绝报价并结束订单'))
        .onPressed!;
    accept();
    accept();
    decline();
    await tester.pump();
    expect(repository.accepts, 1);
    expect(repository.declines, 0);
    repository.request.completeError(StateError('private backend detail'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('result could not be confirmed'), findsOneWidget);
    expect(find.textContaining('private backend'), findsNothing);
    decline();
    await tester.pumpAndSettle();
    expect(repository.declines, 1);
    expect((await repository.loadOrders()).single.status, '已拒绝报价');
  });

  testWidgets('successful quote with failed refresh offers read-only recovery',
      (tester) async {
    final order = _order('待确认报价');
    final repository = _Orders(order)..failRead = true;
    await _open(tester, order, repository);
    await _scroll(tester, '确认报价，前往支付');
    await tester.tap(find.text('确认报价，前往支付'));
    repository.request.complete();
    await tester.pumpAndSettle();
    expect(find.text('Content could not be loaded'), findsOneWidget);
    expect(find.text('确认报价，前往支付'), findsNothing);
    repository.failRead = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(repository.accepts, 1);
    expect((await repository.loadOrders()).single.status, '待支付');
  });

  testWidgets('failed revision preserves the note when reopening its dialog',
      (tester) async {
    final order = _order('待用户验收');
    final repository = _Orders(order);
    await _open(tester, order, repository);
    await _scroll(tester, '要求修改（0/2）');
    await tester.tap(find.text('要求修改（0/2）'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('revision-note')), '保留这条修改意见');
    await tester.tap(find.text('提交修改意见'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('result could not be confirmed'), findsOneWidget);
    await tester.tap(find.text('要求修改（0/2）'));
    await tester.pumpAndSettle();
    expect(find.text('保留这条修改意见'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late approval failure after leaving does not update disposed UI',
      (tester) async {
    final order = _order('待用户验收');
    final repository = _Orders(order);
    await _open(tester, order, repository);
    await _scroll(tester, '确认验收并交付');
    final approve = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, '确认验收并交付'))
        .onPressed!;
    approve();
    approve();
    await tester.pumpWidget(const SizedBox());
    repository.request.completeError(StateError('late failure'));
    await tester.pumpAndSettle();
    expect(repository.approvals, 1);
    expect(tester.takeException(), isNull);
  });
}
