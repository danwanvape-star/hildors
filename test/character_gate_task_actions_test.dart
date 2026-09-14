import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';

class _Orders extends MemoryCustomizationOrderRepository {
  _Orders(CustomizationOrder order) : super(initialOrders: [order]);
  int proposals = 0;
  int previews = 0;
  bool ignorePreview = false;
  final pending = Completer<void>();

  @override
  Future<void> submitCreatorProposal(
      {required String orderId,
      required String creatorId,
      required int suggestedAmountCents,
      String creatorMarketRegion = 'other',
      required int estimatedDeliveryDays}) async {
    proposals++;
    throw StateError('private proposal failure');
  }

  @override
  Future<void> submitCreatorPreview(
      {required String orderId,
      required String creatorId,
      required String previewReference}) async {
    previews++;
    if (ignorePreview) return;
    await pending.future;
    await super.submitCreatorPreview(
        orderId: orderId,
        creatorId: creatorId,
        previewReference: previewReference);
  }
}

CustomizationOrder _order(String status) => CustomizationOrder(
    id: 'task-a',
    characterName: 'Task A',
    sourceType: '原创角色',
    status: status,
    assignedCreatorId: 'local-certified-creator');

Future<void> _open(WidgetTester tester, _Orders repository,
    {PreviewPicker? picker}) async {
  await tester.pumpWidget(MaterialApp(
      home: CreatorTaskBoardPage(
          orderRepository: repository, previewPicker: picker)));
  await tester.pumpAndSettle();
}

Future<void> _scroll(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 200,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('proposal validates in place and retains failed draft',
      (tester) async {
    final repository = _Orders(_order('创作者评估中'));
    await _open(tester, repository);
    await _scroll(tester, '填写工作量与建议报价');
    await tester.tap(find.text('填写工作量与建议报价'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('creator-proposal-amount')), 'Infinity');
    await tester.enterText(find.byKey(const Key('creator-proposal-days')), '0');
    await tester.tap(find.text('提交平台审核'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Enter a valid amount greater than zero'), findsOneWidget);
    expect(repository.proposals, 0);
    await tester.enterText(
        find.byKey(const Key('creator-proposal-amount')), '125.50');
    await tester.enterText(find.byKey(const Key('creator-proposal-days')), '7');
    await tester.tap(find.text('提交平台审核'));
    await tester.pumpAndSettle();
    expect(repository.proposals, 1);
    expect(
        find.textContaining('result could not be confirmed'), findsOneWidget);
    await tester.tap(find.text('填写工作量与建议报价'));
    await tester.pumpAndSettle();
    expect(find.text('125.50'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('preview picker and write are serialized and recover on failure',
      (tester) async {
    final repository = _Orders(_order('制作中'));
    final selected = Completer<bool>();
    int picks = 0;
    await _open(tester, repository, picker: () {
      picks++;
      return selected.future;
    });
    await _scroll(tester, '提交受控预览');
    final submit = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, '提交受控预览'))
        .onPressed!;
    submit();
    submit();
    expect(picks, 1);
    selected.complete(true);
    await tester.pump();
    submit();
    expect(repository.previews, 1);
    repository.pending.completeError(StateError('private path failure'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('result could not be confirmed'), findsOneWidget);
    expect(find.textContaining('已提交受控预览'), findsNothing);
    expect(
        tester
            .widget<AbsorbPointer>(find.byWidgetPredicate((widget) =>
                widget is AbsorbPointer && widget.child is ListView))
            .absorbing,
        isFalse);
  });

  testWidgets('unconfirmed preview never reports success', (tester) async {
    final repository = _Orders(_order('制作中'))..ignorePreview = true;
    await _open(tester, repository, picker: () async => true);
    await _scroll(tester, '提交受控预览');
    await tester.tap(find.text('提交受控预览'));
    await tester.pumpAndSettle();
    expect(repository.previews, 1);
    expect(find.textContaining('已提交受控预览'), findsNothing);
    expect(
        find.textContaining('result could not be confirmed'), findsOneWidget);
  });

  testWidgets('leaving during file selection prevents a later preview write',
      (tester) async {
    final repository = _Orders(_order('制作中'));
    final selected = Completer<bool>();
    await _open(tester, repository, picker: () => selected.future);
    await _scroll(tester, '提交受控预览');
    await tester.tap(find.text('提交受控预览'));
    await tester.pumpWidget(const SizedBox());
    selected.complete(true);
    await tester.pumpAndSettle();
    expect(repository.previews, 0);
    expect(tester.takeException(), isNull);
  });
}
