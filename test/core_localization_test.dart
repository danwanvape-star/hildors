import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_command_session.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/experience/projection_service.dart';
import 'package:hildors_cockpit/src/features/home/home_page.dart';
import 'package:hildors_cockpit/src/features/profile/profile_page.dart';
import 'package:hildors_cockpit/src/features/settings/lan_connection_guide.dart';
import 'package:hildors_cockpit/src/features/settings/playback_mode_guide.dart';
import 'package:hildors_cockpit/src/features/settings/settings_page.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';

Widget localized(Widget page, Locale locale) => MaterialApp(
      key: ValueKey('${page.runtimeType}-$locale'),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: page,
    );

void main() {
  for (final locale in [const Locale('en'), const Locale('zh')]) {
    testWidgets('core pages render and navigate at large text in $locale',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final strings = lookupAppLocalizations(locale);
      final client = P20DeviceClient();
      final session = P20CommandSession(client);
      addTearDown(() {
        session.dispose();
        client.dispose();
      });

      await tester.pumpWidget(localized(
          HomePage(
            client: client,
            session: session,
            projection: P20ProjectionService(client, session),
          ),
          locale));
      await tester.pumpAndSettle();
      expect(find.text(strings.corePlaylists), findsOneWidget);
      expect(find.byTooltip(strings.coreDeviceControl), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
          localized(ProfilePage(client: client, session: session), locale));
      await tester.pumpAndSettle();
      expect(find.text(strings.corePlayerProfile), findsWidgets);
      await tester.scrollUntilVisible(
          find.text(strings.corePlaybackGuide), 200);
      await tester.ensureVisible(find.text(strings.corePlaybackGuide));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.corePlaybackGuide));
      await tester.pumpAndSettle();
      expect(find.byType(PlaybackModeGuide), findsOneWidget);
      expect(find.text(strings.coreLocalPlayback), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(localized(const LanConnectionGuide(), locale));
      await tester.pumpAndSettle();
      expect(find.text(strings.coreCheckWifi), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
          localized(SettingsPage(client: client, session: session), locale));
      await tester.pumpAndSettle();
      expect(find.text(strings.coreDeviceSettings), findsOneWidget);
      await tester.scrollUntilVisible(find.text(strings.coreLoopMode), 180);
      expect(find.text(strings.coreSingleLoop), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
