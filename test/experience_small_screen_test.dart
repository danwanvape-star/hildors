import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';
import 'package:hildors_cockpit/src/features/video/character_package_page.dart';
import 'package:hildors_cockpit/src/features/video/character_video_package.dart';
import 'package:hildors_cockpit/src/features/video/playlist_management_page.dart';
import 'package:hildors_cockpit/src/features/support/support_page.dart';
import 'p20_live_playlist_test.dart' show LiveClient, LiveSession;

void main() {
  for (final code in ['en', 'zh', 'de', 'es', 'ja']) {
    testWidgets(
        '$code small screen large text allows character selection and support',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final client = LiveClient()..online = true;
      final session = LiveSession(client);
      addTearDown(client.dispose);
      addTearDown(session.dispose);
      Widget app(Widget page) => MaterialApp(
          locale: Locale(code),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!),
          home: page);
      const package = CharacterVideoPackage(
          id: 'offline',
          title: 'A very long downloaded character name',
          downloaded: true,
          videos: [
            PackageVideo(
                id: 'one',
                title:
                    'A very long custom character video with multilingual title キャラクター',
                source: '/unused.mp4',
                durationSeconds: 120,
                asset: false)
          ]);
      for (final page in <Widget>[
        CharacterPackagePage(package: package, picking: true),
        CharacterPackagePage(package: package),
        PlaylistManagementPage(client: client, session: session),
        const SupportPage()
      ]) {
        await tester.pumpWidget(app(page));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: '$code ${page.runtimeType}');
        if (page is CharacterPackagePage && page.picking) {
          await tester.ensureVisible(find.byType(Checkbox));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(Checkbox));
          await tester.pumpAndSettle();
          final selected = tester.widget<Checkbox>(find.byType(Checkbox));
          expect(selected.value, isTrue);
        }
        final scroll = find.byType(Scrollable);
        if (scroll.evaluate().isNotEmpty) {
          await tester.drag(scroll.first, const Offset(0, -500));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull,
            reason: '$code ${page.runtimeType} scrolled');
      }
    });
  }
}
