import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/app.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_ui.dart';

void main() {
  testWidgets('shipped app keeps current Chinese UI copy in one language',
      (tester) async {
    await tester.pumpWidget(const CockpitApp());
    final context = tester.element(find.byType(Navigator).first);
    expect(Localizations.localeOf(context), const Locale('zh'));
    expect(GateCopy.text(context, 'quoteEstimateMissing'), '创作者建议制作费尚未提供');
    expect(GateCopy.text(context, 'actionUnconfirmed'), contains('刷新状态'));
  });

  testWidgets('declared expansion locales include English and Japanese',
      (tester) async {
    await tester.pumpWidget(const CockpitApp());
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.supportedLocales,
        containsAll(const [Locale('zh'), Locale('en'), Locale('ja')]));
  });
}
