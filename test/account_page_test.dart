import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';
import 'package:hildors_cockpit/src/features/profile/account_page.dart';
import 'package:hildors_cockpit/src/features/customization/cloud_business_intake.dart';

class _Service extends CloudBusinessIntake {
  _Service(this.verified);
  final bool verified;
  bool signedIn = true;
  int calls = 0;
  @override
  Future<({String? email, bool signedIn, bool verified})>
      accountSummary() async => (
            email: signedIn && verified ? 'test@example.com' : null,
            signedIn: signedIn,
            verified: verified
          );
  @override
  Future<void> signOutAllDevices() async {
    calls++;
    signedIn = false;
  }
}

void main() {
  for (final verified in [true, false]) {
    testWidgets('account confirmed logout; verified=$verified; large English',
        (tester) async {
      final service = _Service(verified);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!),
          home: AccountPage(service: service)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final button =
          find.widgetWithText(OutlinedButton, 'Sign out on all devices');
      expect(button, findsOneWidget);
      if (!verified) {
        expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
        expect(service.calls, 0);
        return;
      }
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(service.calls, 0);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(service.calls, 0);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester
          .tap(find.widgetWithText(FilledButton, 'Sign out on all devices'));
      await tester.pumpAndSettle();
      expect(service.calls, 1);
      expect(find.text('Not signed in'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
