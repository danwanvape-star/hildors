import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/localization/locale_controller.dart';

class Storage implements LocaleStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String next) async {
    value = next;
  }
}

void main() {
  test('new language regional variants resolve to supported base locales', () {
    for (final locale in [
      Locale('de', 'DE'),
      Locale('de', 'AT'),
      Locale('es', 'MX'),
      Locale('es', 'ES'),
      Locale('ja', 'JP')
    ]) {
      expect(resolveAppLocale([locale]), Locale(locale.languageCode));
    }
  });
  test('all added manual choices survive restart', () async {
    for (final entry
        in {'german': 'de', 'spanish': 'es', 'japanese': 'ja'}.entries) {
      final storage = Storage();
      final choice =
          LanguageChoice.values.where((v) => v.name == entry.key).firstOrNull;
      expect(choice, isNotNull);
      final controller = LocaleController(storage: storage);
      await controller.setChoice(choice!);
      final restarted = LocaleController(storage: storage);
      await restarted.load();
      expect(restarted.locale, Locale(entry.value));
      controller.dispose();
      restarted.dispose();
    }
  });
}
