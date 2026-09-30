import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';
import 'package:hildors_cockpit/src/features/video/playlist_management_page.dart';
import 'package:hildors_cockpit/src/features/support/support_page.dart';
import 'package:hildors_cockpit/src/theme/hildors_theme.dart';
import 'p20_live_playlist_test.dart' show LiveClient, LiveSession;

void main() {
  testWidgets('optional five-language visual capture', (tester) async {
    if (!const bool.fromEnvironment('LOCALE_CAPTURE')) return;
    await tester.runAsync(() async {
      final latin = FontLoader('Poppins');
      latin.addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'));
      await latin.load();
      final cjk = FontLoader('ReviewCjk');
      cjk.addFont(File('C:/Windows/Fonts/YuGothR.ttc')
          .readAsBytes()
          .then((b) => ByteData.sublistView(b)));
      await cjk.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = LiveClient()..online = true;
    final session = LiveSession(client);
    addTearDown(client.dispose);
    addTearDown(session.dispose);
    for (final code in ['de', 'es', 'ja']) {
      for (final page in ['playlist', 'support']) {
        final key = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: Locale(code),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              theme: buildHildorsTheme().copyWith(
                  appBarTheme: buildHildorsTheme().appBarTheme.copyWith(
                      titleTextStyle: buildHildorsTheme()
                          .appBarTheme
                          .titleTextStyle
                          ?.copyWith(
                              fontFamily:
                                  code == 'ja' ? 'ReviewCjk' : 'Poppins')),
                  textTheme: buildHildorsTheme().textTheme.apply(
                      fontFamily: code == 'ja' ? 'ReviewCjk' : 'Poppins')),
              home: page == 'playlist'
                  ? PlaylistManagementPage(client: client, session: session)
                  : const SupportPage(),
            )));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final image = await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/locale-review').create(recursive: true);
          await File('build/locale-review/$code-$page.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
  });
}
