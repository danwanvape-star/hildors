import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';
import 'package:hildors_cockpit/src/localization/locale_controller.dart';
import 'package:hildors_cockpit/src/localization/language_settings_tile.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_ui.dart';
import 'package:hildors_cockpit/src/features/customization/customization_page.dart';
import 'package:hildors_cockpit/src/features/video/p20_upload_page.dart';
import 'package:hildors_cockpit/src/features/video/fan_framing_page.dart';
import 'package:hildors_cockpit/src/features/video/playlist_management_page.dart';
import 'package:hildors_cockpit/src/features/video/p20_media_upload_flow.dart';
import 'p20_live_playlist_test.dart' show LiveClient, LiveSession;
import 'new_languages_test.dart' show Storage;

void main() {
  test('every locale supplies every message and placeholder', () {
    Map<String, dynamic> read(String code) =>
        jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
            as Map<String, dynamic>;
    final en = read('en');
    final keys = en.keys.where((k) => !k.startsWith('@')).toSet();
    for (final code in ['zh', 'de', 'es', 'ja']) {
      final translated = read(code);
      expect(translated.keys.where((k) => !k.startsWith('@')).toSet(), keys,
          reason: code);
      for (final key in keys) {
        expect((translated[key] as String).trim(), isNotEmpty,
            reason: '$code:$key');
        final metadata = en['@$key'];
        if (metadata is Map && metadata['placeholders'] is Map) {
          for (final name in (metadata['placeholders'] as Map).keys) {
            expect(translated[key], matches('\\{$name(?:\\}|,)'),
                reason: '$code:$key:$name');
          }
        }
      }
    }
  });
  for (final code in ['de', 'es', 'ja']) {
    testWidgets(
        '$code manual selection, compact device pages and custom entry fit large text',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = LocaleController(storage: Storage());
      final client = LiveClient()..online = true;
      final session = LiveSession(client);
      addTearDown(controller.dispose);
      addTearDown(session.dispose);
      addTearDown(client.dispose);
      Widget app(Widget page) => LocaleScope(
          controller: controller,
          child: MaterialApp(
              locale: Locale(code),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.5)),
                  child: child!),
              home: page));
      await tester.pumpWidget(app(const Scaffold(
          body: SingleChildScrollView(child: LanguageSettingsTile()))));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('language-choice')));
      await tester.pumpAndSettle();
      final label = {'de': 'Deutsch', 'es': 'Español', 'ja': '日本語'}[code]!;
      await tester.ensureVisible(find.text(label).last);
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(controller.locale, Locale(code));
      expect(tester.takeException(), isNull);
      for (final page in <Widget>[
        PlaylistManagementPage(client: client, session: session),
        P20UploadPage(
            client: client,
            session: session,
            source: '/unused.mp4',
            asset: false,
            list: P20MediaList.daily,
            framing: const FanFraming()),
        const CustomizationPage(),
      ]) {
        await tester.pumpWidget(app(page));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: '$code ${page.runtimeType}');
        final scroll = find.byType(Scrollable);
        if (scroll.evaluate().isNotEmpty) {
          await tester.drag(scroll.first, const Offset(0, -400));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull,
            reason: '$code ${page.runtimeType} scrolled');
      }
      await tester.pumpWidget(app(Builder(
          builder: (context) =>
              Scaffold(body: Text(GateCopy.text(context, 'brief'))))));
      expect(find.text('Your brief'), findsNothing);
      expect(find.text('提交灵感'), findsNothing);
    });
  }
}
