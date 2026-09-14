import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';

void main() {
  testWidgets('missing creator estimate is not rendered as a zero quote',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: PlatformQuoteReviewPage(
            order: const CustomizationOrder(
                id: 'missing',
                characterName: 'Missing estimate',
                sourceType: '原创角色',
                status: '平台审核报价',
                marketRegion: 'jp'),
            repository: MemoryCustomizationOrderRepository())));
    await tester.pumpAndSettle();
    expect(find.text('Creator estimate has not been provided'), findsOneWidget);
    expect(find.textContaining('USD 0.00'), findsNothing);
    final amount = find.byKey(const Key('platform-final-amount'));
    expect(tester.widget<TextField>(amount).decoration!.prefixText, 'JPY ');
    tester
        .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>).first)
        .onChanged!('EUR');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(amount).decoration!.prefixText, 'EUR ');
  });

  testWidgets(
      'provided creator estimate retains its actual currency and amount',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: PlatformQuoteReviewPage(
            order: const CustomizationOrder(
                id: 'provided',
                characterName: 'Provided estimate',
                sourceType: '原创角色',
                status: '平台审核报价',
                marketRegion: 'jp',
                creatorSuggestedAmountCents: 12550,
                creatorSuggestedCurrency: 'USD'),
            repository: MemoryCustomizationOrderRepository())));
    await tester.pumpAndSettle();
    expect(find.text('创作者建议制作费：USD 125.50'), findsOneWidget);
    expect(find.text('Creator estimate has not been provided'), findsNothing);
    expect(
        tester
            .widget<TextField>(find.byKey(const Key('platform-final-amount')))
            .controller!
            .text,
        isEmpty);
  });
}
