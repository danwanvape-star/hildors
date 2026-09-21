import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/app.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_ui.dart';

void main() {
  testWidgets('Chinese system keeps the Chinese UI and legacy copy',
      (tester) async {
    tester.binding.platformDispatcher.localesTestValue = [const Locale('zh')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const CockpitApp());
    final context = tester.element(find.byType(Navigator).first);
    expect(Localizations.localeOf(context), const Locale('zh'));
    expect(GateCopy.text(context, 'quoteEstimateMissing'), '创作者建议制作费尚未提供');
    expect(GateCopy.text(context, 'actionUnconfirmed'), contains('刷新状态'));
  });

  testWidgets('only implemented English and Chinese locales are declared',
      (tester) async {
    await tester.pumpWidget(const CockpitApp());
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.supportedLocales.toSet(), {const Locale('zh'), const Locale('en')});
  });
}
