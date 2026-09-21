import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';
import 'package:hildors_cockpit/src/localization/locale_controller.dart';
import 'package:hildors_cockpit/src/localization/language_settings_tile.dart';

class _Storage implements LocaleStorage {
  String? value;
  @override Future<String?> read() async => value;
  @override Future<void> write(String value) async { this.value = value; }
}

void main() {
  testWidgets('system changes apply only in system mode; selection survives restart', (tester) async {
    final storage = _Storage();
    final controller = LocaleController(storage: storage);
    addTearDown(controller.dispose);
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    Widget app(LocaleController state) => LocaleScope(controller: state,
      child: ListenableBuilder(listenable: state, builder: (context, _) => MaterialApp(
        locale: state.locale,
        localeListResolutionCallback: (locales, _) => resolveAppLocale(locales),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) => Scaffold(body: Column(children: [
          Text(context.l10n.coreHome), const LanguageSettingsTile(),
        ]))),
      )),
    );
    tester.binding.platformDispatcher.localesTestValue = [const Locale('fr')];
    await tester.pumpWidget(app(controller));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    tester.binding.platformDispatcher.localesTestValue = [const Locale('zh', 'TW')];
    await tester.pumpAndSettle();
    expect(find.text('首页'), findsOneWidget);
    await controller.setChoice(LanguageChoice.english);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    final restarted = LocaleController(storage: storage);
    addTearDown(restarted.dispose);
    await restarted.load();
    await tester.pumpWidget(app(restarted));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    await restarted.setChoice(LanguageChoice.system);
    await tester.pumpAndSettle();
    expect(find.text('首页'), findsOneWidget);
    tester.binding.platformDispatcher.localesTestValue = [const Locale('en')];
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
