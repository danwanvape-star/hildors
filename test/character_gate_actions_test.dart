import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_entitlement_repository.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_ui.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';

class _Entitlements extends MemoryCharacterEntitlementRepository {
  _Entitlements([super.initialIds]);
  Completer<void>? claimRequest;
  Completer<void>? sendRequest;
  bool ignoreSend = false;
  int claimCalls = 0;
  final sends = <String>[];

  @override
  Future<void> claim(String id) async {
    claimCalls++;
    if (claimRequest != null) await claimRequest!.future;
    await super.claim(id);
  }

  @override
  Future<void> sendToDevice(String id) async {
    sends.add(id);
    if (sendRequest != null) await sendRequest!.future;
    if (!ignoreSend) await super.sendToDevice(id);
  }
}

class _Orders extends MemoryCustomizationOrderRepository {
  final review = Completer<bool>();
  final quote = Completer<void>();
  int reviewCalls = 0;
  int quoteCalls = 0;

  @override
  Future<bool> submitReview(
      {required String characterName,
      required String sourceType,
      List<String> requestedFeatures = const [],
      String? privacyConsentVersion,
      int materialCount = 0,
      String marketRegion = 'unspecified',
      String? resubmissionOfOrderId,
      String? resubmissionReason}) {
    reviewCalls++;
    return review.future;
  }

  @override
  Future<void> publishPlatformQuote(
      {required String orderId,
      required int amountCents,
      required String currency,
      String taxTreatment = 'calculated_at_checkout',
      String? currencyOverrideReason,
      required int includedRevisions,
      required int estimatedDeliveryDays}) {
    quoteCalls++;
    return quote.future;
  }
}

const _order = CustomizationOrder(
    id: 'draft',
    characterName: '保留我的角色草稿',
    sourceType: '原创角色',
    status: '平台审核报价',
    marketRegion: 'us',
    requestedFeatures: ['待机动作'],
    creatorSuggestedAmountCents: 11000,
    creatorSuggestedCurrency: 'USD',
    estimatedDeliveryDays: 10);

Widget _detail(_Entitlements repository) => FreeCharacterDetailPage(
    characterId: 'celestial-mage',
    name: '星穹术士',
    category: '幻想神话',
    imagePath: 'assets/images/content_thumbnails/celestial_mage.jpg',
    repository: repository);

Finder _button(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(FilledButton))
    .first;

void _expectUnconfirmed(WidgetTester tester) {
  expect(
      find.textContaining('The result could not be confirmed'), findsOneWidget);
  expect(find.textContaining('private-backend-error'), findsNothing);
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('claim blocks queued duplicates and recovers after an error',
      (tester) async {
    final repository = _Entitlements()..claimRequest = Completer<void>();
    await tester.pumpWidget(MaterialApp(home: _detail(repository)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Claim for free'), 300,
        scrollable: find.byType(Scrollable).first);
    final callback =
        tester.widget<FilledButton>(_button('Claim for free')).onPressed!;
    callback();
    callback();
    await tester.pump();
    expect(repository.claimCalls, 1);
    expect(
        tester.widget<FilledButton>(_button('Confirming')).onPressed, isNull);
    repository.claimRequest!.completeError(StateError('private-backend-error'));
    await tester.pumpAndSettle();
    _expectUnconfirmed(tester);
    expect(tester.widget<FilledButton>(_button('Claim for free')).onPressed,
        isNotNull);
    expect(await repository.loadClaimedCharacterIds(), isEmpty);
    repository.claimRequest = null;
    tester.widget<FilledButton>(_button('Claim for free')).onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('Added to collection'), findsOneWidget);
    expect(await repository.loadClaimedCharacterIds(), {'celestial-mage'});
  });

  testWidgets('leaving during claim does not show an error on the next page',
      (tester) async {
    final repository = _Entitlements()..claimRequest = Completer<void>();
    await tester.pumpWidget(MaterialApp(home: _detail(repository)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Claim for free'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Claim for free'));
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('other page'))));
    repository.claimRequest!.completeError(StateError('private-backend-error'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening a package never sends the role or changes device state',
      (tester) async {
    final repository = _Entitlements(['celestial-mage', 'neon-dancer']);
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: MyCharactersPage(
            repository: repository,
            orderRepository: MemoryCustomizationOrderRepository())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看包内视频').first);
    await tester.pumpAndSettle();
    expect(find.text('此角色暂未提供可用视频，待内容包交付后选择。'), findsOneWidget);
    expect(repository.sends, isEmpty);
    expect(await repository.loadDeviceCharacterIds(), isEmpty);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('查看包内视频'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing clip manifest never displays device delivery success',
      (tester) async {
    final repository = _Entitlements(['celestial-mage'])..ignoreSend = true;
    await tester.pumpWidget(MaterialApp(
        home: MyCharactersPage(
            repository: repository,
            orderRepository: MemoryCustomizationOrderRepository())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看包内视频'));
    await tester.pumpAndSettle();
    expect(find.text('角色视频包 · 0 个视频'), findsOneWidget);
    expect(repository.sends, isEmpty);
    expect(find.text('已在设备'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed review submission keeps materials, consent and draft',
      (tester) async {
    final repository = _Orders();
    await tester.pumpWidget(MaterialApp(
        home: PrototypeReviewPage(
            type: '原创角色',
            initialOrder: _order,
            orderRepository: repository,
            materialPicker: () async => ['front.png', 'side.png'])));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Choose photos'));
    await tester.tap(find.text('Choose photos'));
    await tester.pumpAndSettle();
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
    await tester.ensureVisible(find.text('Submit free review'));
    final callback =
        tester.widget<FilledButton>(_button('Submit free review')).onPressed!;
    callback();
    callback();
    await tester.pump();
    expect(repository.reviewCalls, 1);
    repository.review.completeError(StateError('private-backend-error'));
    await tester.pumpAndSettle();
    _expectUnconfirmed(tester);
    expect(tester.widget<FilledButton>(_button('Submit free review')).onPressed,
        isNotNull);
    position.jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('2/8 photos · Add more'), findsOneWidget);
    position.jumpTo(position.maxScrollExtent / 2);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        _order.characterName);
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(
        tester
            .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
            .every((tile) => tile.value == true),
        isTrue);
    expect(await repository.loadOrders(), isEmpty);
  });

  testWidgets(
      'failed quote publication keeps entered numbers and unlocks action',
      (tester) async {
    final repository = _Orders();
    await tester.pumpWidget(MaterialApp(
        home: PlatformQuoteReviewPage(order: _order, repository: repository)));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('platform-final-amount')), '129');
    await tester.ensureVisible(find.text('发布平台最终报价'));
    final callback =
        tester.widget<FilledButton>(_button('发布平台最终报价')).onPressed!;
    callback();
    callback();
    await tester.pump();
    expect(repository.quoteCalls, 1);
    repository.quote.completeError(StateError('private-backend-error'));
    await tester.pumpAndSettle();
    _expectUnconfirmed(tester);
    expect(
        tester.widget<FilledButton>(_button('发布平台最终报价')).onPressed, isNotNull);
    expect(
        tester
            .widget<TextField>(find.byKey(const Key('platform-final-amount')))
            .controller!
            .text,
        '129');
    expect(
        tester
            .widget<TextField>(find.byKey(const Key('platform-delivery-days')))
            .controller!
            .text,
        '10');
  });

  testWidgets('module dialog stays dark and scrolls above a phone keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.light(),
        home: Builder(
            builder: (context) => Scaffold(
                    body: FilledButton(
                  child: const Text('open'),
                  onPressed: () => showGateDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      scrollable: true,
                      title: const Text('确认制作范围'),
                      content:
                          Column(mainAxisSize: MainAxisSize.min, children: [
                        for (var i = 0; i < 4; i++)
                          TextField(
                              decoration: InputDecoration(labelText: '范围 $i')),
                      ]),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('返回编辑'))
                      ],
                    ),
                  ),
                )))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(AlertDialog))).brightness,
        Brightness.dark);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('返回编辑'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
