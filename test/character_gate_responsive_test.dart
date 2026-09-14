import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_entitlement_repository.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_ui.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';
import 'package:hildors_cockpit/src/features/customization/customization_page.dart';

void main() {
  const order = CustomizationOrder(
    id: 'responsive-order',
    characterName: 'Starlight / 星光の守護者',
    sourceType: '原创角色',
    status: '待支付',
    quoteAmountCents: 19800,
    quoteCurrency: 'JPY',
    includedRevisions: 2,
    estimatedDeliveryDays: 12,
    assignedCreatorId: 'local-certified-creator',
    creatorPayoutCents: 10000,
    creatorPayoutCurrency: 'USD',
    settlementStatus: '已结算',
  );

  for (final width in [320.0, 768.0, 1440.0]) {
    testWidgets('gate routes fit width $width with enlarged text',
        (tester) async {
      tester.view.reset();
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pages = <Widget>[
        const CustomizationPage(),
        const CharacterSourcePage(),
        FreeOriginalCharactersPage(
            repository: MemoryCharacterEntitlementRepository()),
        const CheckoutReviewPage(order: order),
        CreatorTaskBoardPage(
            orderRepository: MemoryCustomizationOrderRepository(
                initialOrders: const [order])),
        const CreatorSettlementStatementPage(
            orders: [order],
            creatorId: 'local-certified-creator',
            settlementCurrency: 'USD'),
        PlatformOperationsPage(
            repository: MemoryCustomizationOrderRepository(
                initialOrders: const [order])),
      ];
      for (final page in pages) {
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: page,
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: '${page.runtimeType} at $width');
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -650));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: '${page.runtimeType} scrolled at $width');
        }
      }
    });
  }

  testWidgets('task filters preserve repository data and empty state',
      (tester) async {
    final repository =
        MemoryCustomizationOrderRepository(initialOrders: const [order]);
    await tester.pumpWidget(
        MaterialApp(home: CreatorTaskBoardPage(orderRepository: repository)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Available'));
    await tester.tap(find.text('Available'));
    await tester.pumpAndSettle();
    expect(find.text(order.characterName), findsNothing);
    expect(await repository.loadOrders(), hasLength(1));
    await tester.tap(find.text('All tasks'));
    await tester.pumpAndSettle();
    expect(find.text(order.characterName), findsOneWidget);
  });

  testWidgets('presentation vocabulary supports Japanese and English',
      (tester) async {
    for (final locale in [const Locale('en'), const Locale('ja')]) {
      await tester.pumpWidget(MaterialApp(
          home: Localizations(
        locale: locale,
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Builder(
            builder: (context) => Text(GateCopy.text(context, 'brief'))),
      )));
      expect(find.text(locale.languageCode == 'ja' ? '依頼内容' : 'Your brief'),
          findsOneWidget);
    }
  });

  testWidgets('optional gate visual review capture', (tester) async {
    if (!const bool.fromEnvironment('GATE_CAPTURE')) return;
    await tester.runAsync(() async {
      final fontPath = const String.fromEnvironment('GATE_CAPTURE_FONT');
      if (fontPath.isNotEmpty) {
        final font = FontLoader('Roboto');
        font.addFont(File(fontPath)
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)));
        await font.load();
      }
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: const MaterialApp(
            debugShowCheckedModeBanner: false, home: CustomizationPage())));
    await tester.runAsync(() => precacheImage(
          const AssetImage(
              'assets/images/content_thumbnails/celestial_mage.jpg'),
          tester.element(find.byType(CustomizationPage)),
        ));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/gate-ui').create(recursive: true);
      await File('build/gate-ui/entrance.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
