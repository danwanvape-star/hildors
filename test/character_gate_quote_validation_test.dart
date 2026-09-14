import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';

class _Orders extends MemoryCustomizationOrderRepository {
  int calls = 0;
  int? amount;
  String? currency;
  @override
  Future<void> publishPlatformQuote(
      {required String orderId,
      required int amountCents,
      required String currency,
      String taxTreatment = 'calculated_at_checkout',
      String? currencyOverrideReason,
      required int includedRevisions,
      required int estimatedDeliveryDays}) async {
    calls++;
    amount = amountCents;
    this.currency = currency;
    throw StateError('controlled write failure');
  }
}

Future<void> _open(WidgetTester tester, _Orders repository,
    {String region = 'us'}) async {
  await tester.pumpWidget(MaterialApp(
      home: PlatformQuoteReviewPage(
          order: CustomizationOrder(
              id: 'quote',
              characterName: 'Quote',
              sourceType: '原创角色',
              status: '平台审核报价',
              marketRegion: region,
              creatorSuggestedAmountCents: 10000,
              creatorSuggestedCurrency: region == 'jp' ? 'JPY' : 'USD',
              estimatedDeliveryDays: 7),
          repository: repository)));
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String key, String value) async {
  final field = find.byKey(Key(key));
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> _publish(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.text('发布平台最终报价'), 150,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('发布平台最终报价'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'nonfinite prices show inline error without a write or conversion exception',
      (tester) async {
    final repository = _Orders();
    await _open(tester, repository);
    for (final value in ['Infinity', 'NaN', '1e309']) {
      await _enter(tester, 'platform-final-amount', value);
      await _publish(tester);
      final field = tester
          .widget<TextField>(find.byKey(const Key('platform-final-amount')));
      expect(field.decoration!.errorText,
          'Enter a valid amount greater than zero');
      expect(field.focusNode!.hasFocus, isTrue);
      expect(repository.calls, 0);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'existing minimum estimate and integer requirements identify their fields',
      (tester) async {
    final repository = _Orders();
    await _open(tester, repository);
    await _enter(tester, 'platform-final-amount', '99');
    await _enter(tester, 'platform-included-revisions', '-1');
    await _enter(tester, 'platform-delivery-days', '1.5');
    await _publish(tester);
    for (final key in [
      'platform-final-amount',
      'platform-included-revisions',
      'platform-delivery-days'
    ]) {
      expect(
          tester.widget<TextField>(find.byKey(Key(key))).decoration!.errorText,
          isNotNull);
    }
    expect(repository.calls, 0);
  });

  testWidgets('currency override requires a reason and focuses that input',
      (tester) async {
    final repository = _Orders();
    await _open(tester, repository);
    tester
        .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>).first)
        .onChanged!('EUR');
    await tester.pumpAndSettle();
    await _publish(tester);
    final field = tester
        .widget<TextField>(find.byKey(const Key('currency-override-reason')));
    expect(field.decoration!.errorText,
        'Explain why the settlement currency is changing');
    expect(field.focusNode!.hasFocus, isTrue);
    expect(repository.calls, 0);
  });

  testWidgets('JPY and USD keep their original minor-unit conversion',
      (tester) async {
    for (final region in ['jp', 'us']) {
      final repository = _Orders();
      await tester.pumpWidget(const SizedBox());
      await _open(tester, repository, region: region);
      await _enter(
          tester, 'platform-final-amount', region == 'jp' ? '12345' : '123.45');
      await _publish(tester);
      expect(repository.calls, 1);
      expect(repository.amount, 12345);
      expect(repository.currency, region == 'jp' ? 'JPY' : 'USD');
    }
  });
}
