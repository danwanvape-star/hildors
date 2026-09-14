import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_entitlement_repository.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';

void main() {
  testWidgets('empty collection opens library and refreshes after returning',
      (tester) async {
    final repository = MemoryCharacterEntitlementRepository();
    await tester.pumpWidget(MaterialApp(
        home: MyCharactersPage(
      repository: repository,
      orderRepository: MemoryCustomizationOrderRepository(),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore free characters'));
    await tester.pumpAndSettle();
    expect(find.byType(FreeOriginalCharactersPage), findsOneWidget);
    await repository.claim('celestial-mage');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Your collection starts here'), findsNothing);
    expect(find.text('查看包内视频'), findsOneWidget);
  });

  testWidgets('empty collection opens source selection without creating order',
      (tester) async {
    final orders = MemoryCustomizationOrderRepository();
    await tester.pumpWidget(MaterialApp(
        home: MyCharactersPage(
      repository: MemoryCharacterEntitlementRepository(),
      orderRepository: orders,
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start a free commission review'));
    await tester.pumpAndSettle();
    expect(find.byType(CharacterSourcePage), findsOneWidget);
    expect(await orders.loadOrders(), isEmpty);
  });
}
