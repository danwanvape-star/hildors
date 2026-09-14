import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';

const _order = CustomizationOrder(
    id: 'sla',
    characterName: 'SLA character',
    sourceType: '原创角色',
    status: '制作中',
    productionDueAt: '2020-01-01T00:00:00Z');

class _Orders extends MemoryCustomizationOrderRepository {
  _Orders() : super(initialOrders: [_order]);
  final pending = Completer<void>();
  int extensions = 0;
  bool failRead = false;
  @override
  Future<List<CustomizationOrder>> loadOrders() {
    if (failRead) return Future.error(StateError('private load failure'));
    return super.loadOrders();
  }

  @override
  Future<void> extendProductionDeadline(
      {required String orderId,
      required int additionalDays,
      required String reason,
      String operatorId = 'platform-operator-local'}) async {
    extensions++;
    await pending.future;
    await super.extendProductionDeadline(
        orderId: orderId,
        additionalDays: additionalDays,
        reason: reason,
        operatorId: operatorId);
  }
}

Future<void> _open(WidgetTester tester, _Orders repository,
    {bool narrow = false}) async {
  if (narrow) {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(narrow ? 2 : 1)),
          child: child!),
      home: PlatformProductionSlaPage(order: _order, repository: repository)));
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester) async {
  await tester.scrollUntilVisible(
      find.byKey(const Key('delivery-extension-reason')), 200,
      scrollable: find.byType(Scrollable).first);
  await tester.enterText(
      find.byKey(const Key('delivery-extension-reason')), '保留延期说明');
  await tester.scrollUntilVisible(find.text('确认延期并通知用户'), 150,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('extension submits once and preserves inputs on failure',
      (tester) async {
    final repository = _Orders();
    await _open(tester, repository);
    await _fill(tester);
    final submit = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, '确认延期并通知用户'))
        .onPressed!;
    submit();
    submit();
    await tester.pump();
    expect(repository.extensions, 1);
    expect(
        tester
            .widget<TextField>(
                find.byKey(const Key('delivery-extension-reason')))
            .enabled,
        isFalse);
    repository.pending.completeError(StateError('private extension failure'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('result could not be confirmed'), findsOneWidget);
    expect(find.text('保留延期说明'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, '确认延期并通知用户'))
            .onPressed,
        isNotNull);
  });

  testWidgets('refresh failure hides stale actions and retry keeps draft',
      (tester) async {
    final repository = _Orders();
    await _open(tester, repository);
    await _fill(tester);
    repository.failRead = true;
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(find.text('Content could not be loaded'), findsOneWidget);
    expect(find.text('确认延期并通知用户'), findsNothing);
    repository.failRead = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const Key('delivery-extension-reason')), 150,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('保留延期说明'), findsOneWidget);
    expect(repository.extensions, 0);
  });

  testWidgets('dark narrow page validates extension range with enlarged text',
      (tester) async {
    final repository = _Orders();
    await _open(tester, repository, narrow: true);
    await _fill(tester);
    final days = find.byKey(const Key('delivery-extension-days'));
    await tester.ensureVisible(days);
    await tester.enterText(days, '31');
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(days)).brightness, Brightness.dark);
    expect(
        find.text('Enter a whole number of days from 1 to 30'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('确认延期并通知用户'), 150,
        scrollable: find.byType(Scrollable).first);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, '确认延期并通知用户'))
            .onPressed,
        isNull);
    expect(tester.takeException(), isNull);
    expect(repository.extensions, 0);
  });

  testWidgets('late extension failure after leaving is handled',
      (tester) async {
    final repository = _Orders();
    await _open(tester, repository);
    await _fill(tester);
    await tester.tap(find.text('确认延期并通知用户'));
    await tester.pumpWidget(const SizedBox());
    repository.pending.completeError(StateError('late failure'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
