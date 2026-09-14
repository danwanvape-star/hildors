import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';

class _Orders extends MemoryCustomizationOrderRepository {
  int writes = 0;
  @override
  Future<void> publishPlatformQuote(
      {required String orderId,
      required int amountCents,
      required String currency,
      String taxTreatment = 'calculated_at_checkout',
      String? currencyOverrideReason,
      required int includedRevisions,
      required int estimatedDeliveryDays}) async {
    writes++;
  }
}

Future<void> _open(
    WidgetTester tester, _Orders repository, double width, double scale,
    {String region = 'us'}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = const FakeViewPadding(bottom: 300);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: PlatformQuoteReviewPage(
          order: CustomizationOrder(
              id: 'keyboard',
              characterName: 'Keyboard',
              sourceType: '原创角色',
              status: '平台审核报价',
              marketRegion: region,
              estimatedDeliveryDays: 7),
          repository: repository)));
  await tester.pumpAndSettle();
}

Finder _field(String key) => find.byKey(Key(key));

void main() {
  for (final scenario in [(320.0, 1.0), (390.0, 1.5)]) {
    testWidgets(
        'quote next and done actions preserve draft without publishing at $scenario',
        (tester) async {
      final repository = _Orders();
      await _open(tester, repository, scenario.$1, scenario.$2);
      final amount = _field('platform-final-amount');
      await tester.scrollUntilVisible(amount, 150,
          scrollable: find.byType(Scrollable).first);
      await tester.enterText(amount, '125.50');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      final revisions = _field('platform-included-revisions');
      expect(tester.widget<TextField>(revisions).focusNode!.hasFocus, isTrue);
      await tester.enterText(revisions, '3');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      final days = _field('platform-delivery-days');
      expect(tester.widget<TextField>(days).focusNode!.hasFocus, isTrue);
      expect(tester.getBottomLeft(days).dy, lessThanOrEqualTo(544));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(days).focusNode!.hasFocus, isFalse);
      expect(repository.writes, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('invalid price is brought above keyboard with its error',
      (tester) async {
    final repository = _Orders();
    await _open(tester, repository, 320, 1.5);
    await tester.scrollUntilVisible(find.text('发布平台最终报价'), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('发布平台最终报价'));
    await tester.pumpAndSettle();
    final amount = _field('platform-final-amount');
    expect(tester.widget<TextField>(amount).focusNode!.hasFocus, isTrue);
    final error = find.text('Enter a valid amount greater than zero');
    expect(error, findsOneWidget);
    expect(tester.getTopLeft(amount).dy, greaterThanOrEqualTo(56));
    expect(tester.getBottomLeft(error).dy, lessThanOrEqualTo(544));
    expect(repository.writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('JPY price requests an integer keypad', (tester) async {
    final repository = _Orders();
    await _open(tester, repository, 390, 1, region: 'jp');
    final amount = _field('platform-final-amount');
    await tester.scrollUntilVisible(amount, 150,
        scrollable: find.byType(Scrollable).first);
    expect(tester.widget<TextField>(amount).keyboardType.decimal, isFalse);
    expect(repository.writes, 0);
  });
}
