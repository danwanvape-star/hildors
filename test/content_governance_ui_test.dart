import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';
import 'package:hildors_cockpit/src/features/community/content_governance.dart';
import 'package:hildors_cockpit/src/features/customization/cloud_business_intake.dart';

void main() {
  testWidgets('copyright report submits details and shows a backend receipt', (tester) async {
    Map<String,dynamic>? submitted;
    final repo=ContentGovernanceRepository(request:(method,path,{document}) async {
      expect(method,'POST'); expect(path,'/v1/me/reports'); submitted=document;
      return const CloudBusinessResponse(201,{'id':'report-1','status':'received','resolution':''});
    });
    await tester.pumpWidget(MaterialApp(locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: ContentGovernanceActions(packageId:'package-1',repository:repo)),
    ));
    await tester.tap(find.byIcon(Icons.flag_outlined)); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField),'I own the original work.');
    await tester.tap(find.byType(FilledButton)); await tester.pumpAndSettle();
    expect(submitted, {'packageId':'package-1','reason':'copyright','details':'I own the original work.'});
    expect(find.textContaining('report-1'), findsOneWidget);
    expect(tester.takeException(),isNull);
  });
  test('failed block mutation never announces successful refresh', () async {
    final before=ContentGovernanceRepository.changes.value;
    final repo=ContentGovernanceRepository(request:(method,path,{document}) async => const CloudBusinessResponse(401,{}));
    await expectLater(repo.block('package-1'),throwsA(isA<GovernanceException>()));
    expect(ContentGovernanceRepository.changes.value,before);
  });
}
