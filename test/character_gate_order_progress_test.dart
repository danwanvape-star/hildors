import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_entitlement_repository.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_order_progress.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_ui.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';

CustomizationOrder _order(String status) => CustomizationOrder(
      id: 'progress-order',
      characterName: '阶段检查角色',
      sourceType: '原创角色',
      status: status,
      previewVersion: 2,
      includedRevisions: 2,
      revisionsUsed: 2,
    );

class _Orders extends MemoryCustomizationOrderRepository {
  _Orders(CustomizationOrder order) : super(initialOrders: [order]);
  bool fail = false;
  @override
  Future<List<CustomizationOrder>> loadOrders() {
    if (fail) return Future.error(StateError('read failed'));
    return super.loadOrders();
  }
}

Finder _selectedStages() => find.descendant(
    of: find.byType(GateJourney),
    matching: find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.selected == true));

void main() {
  test('平台质检保持制作阶段且不提前显示用户验收', () {
    final progress = GateOrderProgress.fromStatus('待平台质检');
    expect(progress.stage, 2);
    expect(progress.hintKey, 'stepQuality');
    expect(progress.reviewPassed, isTrue);
    expect(progress.complete, isFalse);
  });
  test('matching and quote preparation never imply user acceptance', () {
    for (final status in ['待创作者申请', '创作者评估中', '平台审核报价', '待确认报价']) {
      final progress = GateOrderProgress.fromStatus(status);
      expect(progress.stage, 1, reason: status);
      expect(progress.quoteKey, isNot('quoteAccepted'), reason: status);
      expect(progress.complete, isFalse);
    }
  });

  test('closed, paused and unknown orders have no active creation stage', () {
    for (final status in [
      '已撤回',
      '预审未通过',
      '已拒绝报价',
      '争议处理中',
      '退款处理中',
      '已退款',
      'future-status'
    ]) {
      final progress = GateOrderProgress.fromStatus(status);
      expect(progress.stage, -1, reason: status);
      expect(progress.complete, isFalse, reason: status);
    }
    expect(GateOrderProgress.fromStatus('future-status').reviewPassed, isFalse);
  });

  testWidgets('collection and details agree on the current stage',
      (tester) async {
    for (final status in ['待创作者申请', '修改中', '待平台质检', '待用户验收', '已撤回']) {
      final order = _order(status);
      final repository =
          MemoryCustomizationOrderRepository(initialOrders: [order]);
      await tester.pumpWidget(MaterialApp(
          home: MyCharactersPage(
              key: ValueKey('collection-$status'),
              repository: MemoryCharacterEntitlementRepository(),
              orderRepository: repository)));
      await tester.pumpAndSettle();
      final collectionProgress =
          tester.widget<GateJourney>(find.byType(GateJourney));
      await tester.pumpWidget(MaterialApp(
          home: CustomizationOrderDetailPage(
              key: ValueKey(status), order: order, repository: repository)));
      await tester.pumpAndSettle();
      final detailProgress =
          tester.widget<GateJourney>(find.byType(GateJourney));
      expect(detailProgress.stage, collectionProgress.stage, reason: status);
      expect(
          _selectedStages(), status == '已撤回' ? findsNothing : findsOneWidget);
      expect((await repository.loadOrders()).single.status, status);
    }
  });

  testWidgets('ended orders show no future payment or approval action',
      (tester) async {
    for (final status in [
      '已撤回',
      '已拒绝报价',
      '争议处理中',
      '退款处理中',
      '已退款',
      'future-status'
    ]) {
      final order = _order(status);
      await tester.pumpWidget(MaterialApp(
          home: CustomizationOrderDetailPage(
              key: ValueKey(status),
              order: order,
              repository:
                  MemoryCustomizationOrderRepository(initialOrders: [order]))));
      await tester.pumpAndSettle();
      expect(_selectedStages(), findsNothing, reason: status);
      await tester.drag(find.byType(ListView), const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(find.text('付款尚未开放'), findsNothing, reason: status);
      expect(find.text('确认报价，前往支付'), findsNothing);
      expect(find.text('确认验收并交付'), findsNothing);
      expect(find.text('Quote accepted'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('delivered timeline is complete rather than awaiting approval',
      (tester) async {
    final order = _order('已交付');
    await tester.pumpWidget(MaterialApp(
        home: CustomizationOrderDetailPage(
            order: order,
            repository:
                MemoryCustomizationOrderRepository(initialOrders: [order]))));
    await tester.pumpAndSettle();
    expect(
        tester.widget<GateJourney>(find.byType(GateJourney)).complete, isTrue);
    expect(_selectedStages(), findsNothing);
    expect(
        find.descendant(
            of: find.byType(GateJourney), matching: find.byIcon(Icons.check)),
        findsNWidgets(4));
    expect(
        find.textContaining('Approved. Find your character'), findsOneWidget);
  });

  testWidgets('approval describes preview availability and exhausted revisions',
      (tester) async {
    final order = _order('待用户验收');
    await tester.pumpWidget(MaterialApp(
        home: CustomizationOrderDetailPage(
            order: order,
            repository:
                MemoryCustomizationOrderRepository(initialOrders: [order]))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('已用完本次报价包含的修改次数。'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('真实受控播放尚未接入'), findsOneWidget);
    final revise = find.ancestor(
        of: find.text('要求修改（2/2）'), matching: find.byType(OutlinedButton));
    expect(tester.widget<OutlinedButton>(revise).onPressed, isNull);
    expect(find.text('确认验收并交付'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('details can refresh into a closed state and recover from errors',
      (tester) async {
    final repository = _Orders(_order('已退款'));
    await tester.pumpWidget(MaterialApp(
        home: CustomizationOrderDetailPage(
            order: _order('制作中'), repository: repository)));
    await tester.pumpAndSettle();
    expect(tester.widget<GateJourney>(find.byType(GateJourney)).stage, 2);
    repository.fail = true;
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(find.byType(GateJourney), findsNothing);
    expect(find.text('Content could not be loaded'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('已退款'), findsOneWidget);
    expect(_selectedStages(), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Japanese progress hints fit a small screen with enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final status in ['待创作者申请', '待用户验收', '已交付', '争议处理中', 'future-status']) {
      await tester.pumpWidget(MaterialApp(
          home: Localizations(
        locale: const Locale('ja'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: GateScaffold(
              body: ListView(padding: const EdgeInsets.all(20), children: [
            GateJourney.forStatus(status),
            GateOrderHint(status: status),
          ])),
        ),
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: status);
      expect(find.textContaining('step'), findsNothing);
    }
  });
}
