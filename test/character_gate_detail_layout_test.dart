import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_entitlement_repository.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_ui.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';

const _name = '星の守護者 / Atelier des constellations — Collector Edition';
const _creator = 'creator-international-studio-012345678901234567890123456789';
const _reference =
    'provider-transaction-0123456789012345678901234567890123456789';
const _assignment = CustomizationOrder(
    id: 'layout-assignment',
    characterName: _name,
    sourceType: '原创角色',
    status: '待创作者申请',
    applicantCreatorIds: [_creator]);
const _settled = CustomizationOrder(
    id: 'international-order-01234567890123456789',
    characterName: _name,
    sourceType: '原创角色',
    status: '已交付',
    assignedCreatorId: _creator,
    creatorPayoutCurrency: 'USD',
    creatorPayoutCents: 999999999,
    settlementStatus: '已结算',
    payoutReference: _reference,
    settledAt: '2026-09-10T00:00:00Z');

Future<void> _open(
    WidgetTester tester, Widget page, double width, double scale) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: page));
  await tester.pumpAndSettle();
}

void _checkTile(WidgetTester tester, bool stacked, {bool longTitle = true}) {
  final tile = find.byType(GateDetailTile);
  final widget = tester.widget<GateDetailTile>(tile);
  final title = find.byWidget(widget.title);
  final trailing = find.byWidget(widget.trailing);
  final subtitle = find.byWidget(widget.subtitle);
  if (longTitle) {
    expect(tester.getSize(title).width, greaterThan(100));
  }
  if (stacked) {
    expect(tester.getTopLeft(trailing).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(subtitle).dy));
  } else {
    expect(tester.getTopLeft(trailing).dx,
        greaterThan(tester.getTopRight(title).dx));
  }
  final tileBounds = tester.getRect(tile);
  expect(tester.getRect(trailing).right, lessThanOrEqualTo(tileBounds.right));
  expect(tester.getRect(title).right, lessThanOrEqualTo(tileBounds.right));
  expect(tester.takeException(), isNull);
}

void main() {
  for (final scenario in [
    (320.0, 2.0, true),
    (768.0, 1.3, true),
    (1440.0, 1.0, false)
  ]) {
    testWidgets('free detail permits claiming with enlarged text at $scenario',
        (tester) async {
      final repository = MemoryCharacterEntitlementRepository();
      await _open(
          tester,
          FreeCharacterDetailPage(
            characterId: 'celestial-mage',
            name: _name,
            category: '幻想神話 / Fantasy collection',
            imagePath: 'assets/images/content_thumbnails/celestial_mage.jpg',
            repository: repository,
          ),
          scenario.$1,
          scenario.$2);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Claim for free'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(find.text('Claim for free').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Claim for free'));
      await tester.pumpAndSettle();
      expect(find.text('Added to collection'), findsOneWidget);
      expect(await repository.loadClaimedCharacterIds(), {'celestial-mage'});
      expect(await repository.loadDeviceCharacterIds(), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('free collection keeps device action readable at $scenario',
        (tester) async {
      final entitlements = MemoryCharacterEntitlementRepository();
      await entitlements.claim('celestial-mage');
      await _open(
          tester,
          MyCharactersPage(
              repository: entitlements,
              orderRepository: MemoryCustomizationOrderRepository()),
          scenario.$1,
          scenario.$2);
      await tester.scrollUntilVisible(find.text('查看包内视频'), 150,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      _checkTile(tester, scenario.$3, longTitle: false);
      expect(find.text('查看包内视频').hitTestable(), findsOneWidget);
      expect(await entitlements.loadDeviceCharacterIds(), isEmpty);
    });

    testWidgets(
        'delivered collection keeps device action readable at $scenario',
        (tester) async {
      await _open(
          tester,
          MyCharactersPage(
              repository: MemoryCharacterEntitlementRepository(),
              orderRepository: MemoryCustomizationOrderRepository(
                  initialOrders: [_settled])),
          scenario.$1,
          scenario.$2);
      await tester.scrollUntilVisible(find.text('查看包内视频'), 150,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(find.text(_name), findsOneWidget);
      _checkTile(tester, scenario.$3);
      expect(find.text('查看包内视频').hitTestable(), findsOneWidget);
    });

    testWidgets(
        'assignment retains long creator details and action at $scenario',
        (tester) async {
      final repository =
          MemoryCustomizationOrderRepository(initialOrders: [_assignment]);
      await _open(
          tester,
          PlatformAssignmentReviewPage(
              order: _assignment,
              repository: repository,
              creatorDisplayNames: const {_creator: _name}),
          scenario.$1,
          scenario.$2);
      await tester.scrollUntilVisible(find.text('选择'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      _checkTile(tester, scenario.$3);
      expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, '选择'))
              .onPressed,
          isNotNull);
      expect(find.text('内部编号：$_creator'), findsOneWidget);
      expect((await repository.loadOrders()).single.assignedCreatorId, isNull);
    });

    testWidgets('settlement retains long references and amount at $scenario',
        (tester) async {
      await _open(
          tester,
          const CreatorSettlementStatementPage(
              orders: [_settled],
              creatorId: _creator,
              settlementCurrency: 'USD'),
          scenario.$1,
          scenario.$2);
      await tester.scrollUntilVisible(find.byType(GateDetailTile), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      _checkTile(tester, scenario.$3);
      final tile = tester.widget<GateDetailTile>(find.byType(GateDetailTile));
      expect((tile.subtitle as Text).data, contains(_reference));
      expect((tile.trailing as Text).data, contains('9999999.99'));
    });
  }
}
