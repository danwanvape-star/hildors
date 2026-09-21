import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/localization/locale_controller.dart';

class MemoryLocaleStorage implements LocaleStorage {
  String? value;
  bool fail = false;
  @override Future<String?> read() async => value;
  @override Future<void> write(String next) async {
    if (fail) throw StateError('write failed');
    value = next;
  }
}

void main() {
  test('system locale normalizes Chinese variants and defaults unsupported to English', () {
    for (final locale in [const Locale('zh'), const Locale('zh','TW'), const Locale.fromSubtags(languageCode:'zh',scriptCode:'Hant')]) {
      expect(resolveAppLocale([locale]),const Locale('zh'));
    }
    expect(resolveAppLocale([const Locale('en','US')]),const Locale('en'));
    expect(resolveAppLocale([const Locale('fr')]),const Locale('en'));
    expect(resolveAppLocale(null),const Locale('en'));
  });
  test('manual choice survives restart and system choice restores dynamic resolution', () async {
    final storage=MemoryLocaleStorage();final first=LocaleController(storage:storage);
    await first.load(); expect(first.locale,isNull);
    await first.setChoice(LanguageChoice.chinese);
    final restarted=LocaleController(storage:storage);await restarted.load();
    expect(restarted.locale,const Locale('zh'));
    await restarted.setChoice(LanguageChoice.system);expect(restarted.locale,isNull);
    final third=LocaleController(storage:storage);await third.load();expect(third.locale,isNull);
  });
  test('bad persisted data falls back to system and failed writes keep previous choice', () async {
    final storage=MemoryLocaleStorage()..value='ja';final controller=LocaleController(storage:storage);await controller.load();
    expect(controller.choice,LanguageChoice.system);
    storage.fail=true;await expectLater(controller.setChoice(LanguageChoice.english),throwsStateError);
    expect(controller.choice,LanguageChoice.system);
  });
  test('rapid changes persist the most recent selection in order', () async {
    final storage=MemoryLocaleStorage();final controller=LocaleController(storage:storage);
    await Future.wait([controller.setChoice(LanguageChoice.chinese),controller.setChoice(LanguageChoice.english),controller.setChoice(LanguageChoice.system)]);
    expect(storage.value,'system');expect(controller.locale,isNull);
  });
}
