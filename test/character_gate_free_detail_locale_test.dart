import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_entitlement_repository.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';

void main() {
  testWidgets('catalog lists credits and protects anonymous creator names',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: FreeOriginalCharactersPage(
      repository: MemoryCharacterEntitlementRepository(),
      credits: {
        'celestial-mage': CharacterCatalogCredit(
            creatorName: 'Studio Aurora', publishedAt: DateTime(2026, 9, 11)),
        'neon-dancer': const CharacterCatalogCredit(
            creatorName: 'Private name', anonymous: true),
      },
    )));
    await tester.pumpAndSettle();
    expect(find.text('Celestial Mage').hitTestable(), findsOneWidget);
    expect(find.text('Neon Dancer').hitTestable(), findsOneWidget);
    expect(find.text('Creator: Studio Aurora'), findsOneWidget);
    expect(find.text('Creator: Anonymous creator'), findsOneWidget);
    expect(find.textContaining('Private name'), findsNothing);
    final context = tester.element(find.byType(FreeOriginalCharactersPage));
    final date = MaterialLocalizations.of(context)
        .formatMediumDate(DateTime(2026, 9, 11));
    expect(find.text('Published: $date'), findsOneWidget);
    expect(find.text('Publish date not provided'), findsWidgets);
    final thumbnail = tester.widgetList<Image>(find.byType(Image)).first;
    expect(thumbnail.width, lessThanOrEqualTo(80));
    expect(thumbnail.fit, BoxFit.contain);
    expect(tester.takeException(), isNull);
  });

  for (final scenario in [
    ('zh', '免费领取', '已加入收藏'),
    ('en', 'Claim for free', 'Added to collection'),
    ('ja', '無料で入手', 'コレクションに追加済み'),
  ]) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets(
          'free library accommodates large text in ${scenario.$1} at $width',
          (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository =
            MemoryCharacterEntitlementRepository(['celestial-mage']);
        await tester.pumpWidget(MaterialApp(
          locale: Locale(scenario.$1),
          supportedLocales: const [Locale('zh'), Locale('en'), Locale('ja')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: FreeOriginalCharactersPage(repository: repository),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final expectedName = switch (scenario.$1) {
          'zh' => '星穹术士',
          'ja' => '星穹の魔術師',
          _ => 'Celestial Mage',
        };
        final expectedCategory = switch (scenario.$1) {
          'zh' => '幻想神话',
          'ja' => 'ファンタジー・神話',
          _ => 'Fantasy & mythology',
        };
        expect(find.text(expectedName), findsOneWidget);
        expect(find.text(expectedCategory), findsOneWidget);
        final status = find.text(scenario.$3);
        await tester.ensureVisible(status);
        await tester.pumpAndSettle();
        expect(status.hitTestable(), findsOneWidget);
        final card = find.ancestor(of: status, matching: find.byType(Card));
        final bounds = tester.getRect(card);
        final textBounds = tester.getRect(status);
        expect(textBounds.bottom, lessThanOrEqualTo(bounds.bottom));
        expect(textBounds.right, lessThanOrEqualTo(bounds.right));
        await tester.tap(status);
        await tester.pumpAndSettle();
        expect(find.byType(FreeCharacterDetailPage), findsOneWidget);
        final detail = tester.widget<FreeCharacterDetailPage>(
            find.byType(FreeCharacterDetailPage));
        expect(detail.name, expectedName);
        expect(detail.category, expectedCategory);
        expect(detail.characterId, 'celestial-mage');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('free detail claim remains reachable in ${scenario.$1}',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = MemoryCharacterEntitlementRepository();
      await tester.pumpWidget(MaterialApp(
        locale: Locale(scenario.$1),
        supportedLocales: const [Locale('zh'), Locale('en'), Locale('ja')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: FreeCharacterDetailPage(
          characterId: 'celestial-mage',
          name: '星の守護者 / Collector Edition',
          category: 'Fantasy',
          imagePath: 'assets/images/content_thumbnails/celestial_mage.jpg',
          repository: repository,
        ),
      ));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(scenario.$2), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(scenario.$2));
      await tester.pumpAndSettle();
      expect(find.text(scenario.$3), findsOneWidget);
      expect(await repository.loadClaimedCharacterIds(), {'celestial-mage'});
      expect(await repository.loadDeviceCharacterIds(), isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}
