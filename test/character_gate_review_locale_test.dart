import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';

Widget _reviewApp(Locale locale, {String type = '原创手办'}) => MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('zh'), Locale('en'), Locale('ja')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: PrototypeReviewPage(type: type),
    );

Widget _sourceApp(Locale locale) => MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('zh'), Locale('en'), Locale('ja')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const CharacterSourcePage(),
    );

void main() {
  for (final language in ['zh', 'en', 'ja']) {
    testWidgets('authorization remains reachable at large text in $language',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: const [Locale('zh'), Locale('en'), Locale('ja')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const UnsupportedIpPage(),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final action = find.byType(FilledButton);
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(action.hitTestable(), findsOneWidget);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.byType(IpWishPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('free review entry renders its English catalog', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_reviewApp(const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Free review'), findsOneWidget);
    expect(
        find.text('First, let us confirm we can create it safely and reliably'),
        findsOneWidget);
    expect(find.text('Selected: Original figure'), findsOneWidget);
    expect(find.text('Choose photos'), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(TextField), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('Character name'), findsOneWidget);
    expect(find.text('角色名称'), findsNothing);
  });

  testWidgets('free review entry renders its Japanese catalog', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_reviewApp(const Locale('ja'), type: '原创角色'));
    await tester.pumpAndSettle();

    expect(find.text('無料事前審査'), findsOneWidget);
    expect(find.text('安全かつ安定して制作できるか、まず確認します'), findsOneWidget);
    expect(find.text('選択済み：オリジナルキャラクター'), findsOneWidget);
    expect(find.text('写真を選択'), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(TextField), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('キャラクター名'), findsOneWidget);
    expect(find.text('免费预审'), findsNothing);
  });

  testWidgets('character source and rights diversion render in English',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_sourceApp(const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Custom character'), findsOneWidget);
    expect(find.text('Where does this character come from?'), findsOneWidget);
    expect(find.text('This is the character I want'), findsOneWidget);
    expect(find.text('I represent the brand or rights holder'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('This is a game or anime character I like'));
    await tester.pumpAndSettle();
    expect(find.text('Character rights'), findsOneWidget);
    expect(find.textContaining('Without applicable rights'), findsOneWidget);
    expect(find.text('Submit a character wish'), findsOneWidget);
  });

  testWidgets('rights diversion and wish form render in Japanese',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_sourceApp(const Locale('ja')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('好きなゲーム・アニメのキャラクター'));
    await tester.pumpAndSettle();
    expect(find.text('キャラクターの権利'), findsOneWidget);
    await tester.tap(find.text('キャラクターをリクエスト'));
    await tester.pumpAndSettle();
    expect(find.text('キャラクターリクエスト'), findsOneWidget);
    expect(find.text('作品・ゲーム名'), findsOneWidget);
    expect(find.text('キャラクター名'), findsOneWidget);
    expect(find.textContaining('権利取得や提供開始を保証'), findsOneWidget);
  });
}
