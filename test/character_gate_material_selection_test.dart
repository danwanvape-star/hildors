import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';

const _draft = CustomizationOrder(
    id: 'draft',
    characterName: 'My character',
    sourceType: '原创角色',
    status: '预审未通过',
    marketRegion: 'us',
    requestedFeatures: ['待机动作']);

Future<void> _open(WidgetTester tester, MaterialPicker picker,
    {bool prefill = false}) async {
  await tester.pumpWidget(MaterialApp(
      home: PrototypeReviewPage(
          type: '原创角色',
          initialOrder: prefill ? _draft : null,
          orderRepository: MemoryCustomizationOrderRepository(),
          materialPicker: picker)));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('Choose photos'), 150,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'photo batches append up to eight without replacing earlier photos',
      (tester) async {
    var calls = 0;
    await _open(
        tester,
        () async => ++calls == 1
            ? ['front.jpg']
            : List.generate(9, (index) => 'angle-$index.jpg'));
    await tester.tap(find.text('Choose photos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1/8 photos · Add more'));
    await tester.pumpAndSettle();
    expect(find.textContaining('front.jpg、angle-0.jpg'), findsOneWidget);
    expect(find.byType(InputChip), findsNWidgets(8));
    expect(find.textContaining('angle-7.jpg'), findsNothing);
    final fullButton = tester.widget<OutlinedButton>(find.widgetWithText(
        OutlinedButton, '8 photos selected · Limit reached'));
    expect(fullButton.onPressed, isNull);
    tester
        .widget<InputChip>(find.byKey(const ValueKey('review-material-0')))
        .onDeleted!();
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, '7/8 photos · Add more'))
            .onPressed,
        isNotNull);
  });

  testWidgets(
      'photo selection serializes and retains previous photos on error or cancellation',
      (tester) async {
    final pending = Completer<List<String>>();
    int calls = 0;
    await _open(tester, () {
      calls++;
      if (calls == 1) return Future.value(['front.png', 'side.png']);
      if (calls == 2) return pending.future;
      return Future.value([]);
    });
    await tester.tap(find.text('Choose photos'));
    await tester.pumpAndSettle();
    final picker = tester
        .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, '2/8 photos · Add more'))
        .onPressed!;
    picker();
    picker();
    await tester.pump();
    expect(calls, 2);
    expect(find.text('Selecting photos…'), findsOneWidget);
    pending.completeError(StateError('private file path'));
    await tester.pumpAndSettle();
    expect(find.text('front.png、side.png'), findsOneWidget);
    expect(find.textContaining('Your previous selection was kept'),
        findsOneWidget);
    expect(find.textContaining('private file'), findsNothing);
    picker();
    await tester.pumpAndSettle();
    expect(calls, 3);
    expect(find.text('front.png、side.png'), findsOneWidget);
  });

  testWidgets('removing a photo updates requirements and disables submission',
      (tester) async {
    await _open(tester, () async => ['front.png', 'side.png'], prefill: true);
    await tester.tap(find.text('Choose photos'));
    await tester.pumpAndSettle();
    final remove = tester
        .widget<InputChip>(find.byKey(const ValueKey('review-material-1')))
        .onDeleted!;
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
    final consentTiles = tester
        .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
        .toList();
    expect(consentTiles, hasLength(2));
    for (final tile in consentTiles) {
      tile.onChanged!(true);
      await tester.pump();
    }
    await tester.scrollUntilVisible(find.text('Submit free review'), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Submit free review'))
            .onPressed,
        isNotNull);
    remove();
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Submit free review'))
            .onPressed,
        isNull);
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.textContaining('At least 2 photos'), findsOneWidget);
  });

  testWidgets('leaving the page ignores a late photo picker failure',
      (tester) async {
    final pending = Completer<List<String>>();
    await _open(tester, () => pending.future);
    await tester.tap(find.text('Choose photos'));
    await tester.pumpWidget(const SizedBox());
    pending.completeError(StateError('late failure'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('incomplete review explains every existing requirement',
      (tester) async {
    await _open(tester, () async => []);
    await tester.scrollUntilVisible(
        find.byKey(const Key('review-missing-fields')), 300,
        scrollable: find.byType(Scrollable).first);
    final message = tester
        .widget<Text>(find.byKey(const Key('review-missing-fields')))
        .data!;
    for (final requirement in [
      'At least 2 photos',
      'Character name',
      'Requested features',
      'Region of residence',
      'Rights confirmation',
      'Material processing consent'
    ]) {
      expect(message, contains(requirement));
    }
    expect(tester.takeException(), isNull);
  });
}
