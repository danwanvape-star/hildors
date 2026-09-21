import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

enum LanguageChoice { system, english, chinese }
Locale resolveAppLocale(List<Locale>? preferred) =>
    preferred?.isNotEmpty == true && preferred!.first.languageCode == 'zh'
        ? const Locale('zh') : const Locale('en');

abstract interface class LocaleStorage {
  Future<String?> read();
  Future<void> write(String value);
}
class FileLocaleStorage implements LocaleStorage {
  Future<File> _file() async => File('${(await getApplicationSupportDirectory()).path}/language-preference.txt');
  @override Future<String?> read() async {
    final file = await _file();
    return await file.exists() ? (await file.readAsString()).trim() : null;
  }
  @override Future<void> write(String value) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(value, flush: true);
  }
}
class LocaleController extends ChangeNotifier {
  LocaleController({LocaleStorage? storage}) : _storage = storage ?? FileLocaleStorage();
  final LocaleStorage _storage;
  LanguageChoice _choice = LanguageChoice.system;
  Future<void> _pending = Future.value();
  LanguageChoice get choice => _choice;
  Locale? get locale => switch (_choice) {
    LanguageChoice.system => null,
    LanguageChoice.english => const Locale('en'),
    LanguageChoice.chinese => const Locale('zh'),
  };
  Future<void> load() async {
    try {
      final stored = await _storage.read();
      _choice = LanguageChoice.values.where((x) => x.name == stored).firstOrNull ?? LanguageChoice.system;
    } catch (_) { _choice = LanguageChoice.system; }
    notifyListeners();
  }
  Future<void> setChoice(LanguageChoice value) {
    final operation = _pending.then((_) async {
      await _storage.write(value.name);
      _choice = value;
      notifyListeners();
    });
    _pending = operation.catchError((Object _) {});
    return operation;
  }
}
class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({required LocaleController controller, required super.child, super.key}) : super(notifier: controller);
  static LocaleController? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<LocaleScope>()?.notifier;
}
