import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';
import 'package:hildors_cockpit/src/features/support/support_page.dart';

void main() {
  for (final locale in ['en', 'zh', 'de', 'es', 'ja']) {
    testWidgets('support mail fallback and clipboard $locale', (tester) async {
      Uri? opened;
      String? copied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = call.arguments['text'] as String;
        }
        return null;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      await tester.pumpWidget(MaterialApp(
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: SupportPage(openMail: (uri) async {
          opened = uri;
          return false;
        }),
      ));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(opened!.scheme, 'mailto');
      expect(opened!.path, 'support@marketing.hildors.com');
      expect(opened!.queryParameters, {'subject': 'Hildors App support'});
      expect(
          find.textContaining(
              lookupAppLocalizations(Locale(locale)).supportNoMailApp),
          findsOneWidget);
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      expect(copied, supportEmail);
      expect(tester.takeException(), isNull);
    });
  }
}
