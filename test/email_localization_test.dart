import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';
import 'package:hildors_cockpit/src/features/customization/cloud_business_intake.dart';
import 'package:hildors_cockpit/src/features/customization/cloud_email_identity.dart';

void main() {
  testWidgets('English sign-in safely handles service errors at large text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = CloudBusinessIntake(emailRequest: (method, path, {document, token}) async {
      throw const FormatException('PRIVATE_SERVER_EXCEPTION');
    });
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Builder(builder: (context) => Scaffold(body: TextButton(
        onPressed: () => showCloudEmailSignIn(context, service: service),
        child: const Text('open'),
      ))),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Email sign-in'), findsOneWidget);
    expect(find.textContaining('PRIVATE_SERVER_EXCEPTION'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Email sign-in'), findsNothing);
  });
}
