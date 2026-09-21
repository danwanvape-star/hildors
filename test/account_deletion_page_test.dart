import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';
import 'package:hildors_cockpit/src/features/profile/account_deletion_page.dart';
import 'package:hildors_cockpit/src/features/customization/cloud_business_intake.dart';

class _Service extends CloudBusinessIntake {
  Map<String, dynamic>? request;
  int writes = 0, revision = 0;
  @override
  int get identityRevision => revision;
  @override
  Future<CloudBusinessResponse> contentRequest(String method, String path,
      {Map<String, dynamic>? document,
      String? filePath,
      String? contentType,
      int? ifMatch}) async {
    if (method == 'POST') {
      writes++;
      request = {
        'id': 'request-1',
        'version': writes,
        'status': path.endsWith('/cancel') ? 'cancelled' : 'received',
        'message': ''
      };
    }
    return CloudBusinessResponse(200, {'request': request});
  }
}

void main() {
  testWidgets(
      'deletion request requires confirmation, persists status and cancels; large English',
      (tester) async {
    final service = _Service();
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
        home: AccountDeletionPage(service: service)));
    await tester.pumpAndSettle();
    final submit =
        find.widgetWithText(FilledButton, 'Request account deletion');
    await tester.scrollUntilVisible(submit, 200);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(service.writes, 0);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.writes, 0);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
    await tester.pumpAndSettle();
    expect(find.text('Request received'), findsOneWidget);
    expect(service.writes, 1);
    final cancel = find.text('Cancel deletion request');
    await tester.scrollUntilVisible(cancel, 200);
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(find.text('Request cancelled'), findsOneWidget);
    expect(service.writes, 2);
    expect(tester.takeException(), isNull);
    service.revision++;
    final refresh = find.text('Refresh status');
    await tester.scrollUntilVisible(refresh, -200);
    await tester.tap(refresh);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(submit, 200);
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    expect(service.writes, 2);
  });
}
