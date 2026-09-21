import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';
import 'package:hildors_cockpit/src/features/customization/creator_application_page.dart';
import 'package:hildors_cockpit/src/features/customization/creator_application_repository.dart';
import 'creator_application_test.dart' as fixture;

void main() {
  testWidgets('English creator application remains usable with enlarged text', (tester) async {
    tester.view.physicalSize=const Size(390,844);
    tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(locale:const Locale('en'),
      localizationsDelegates:AppLocalizations.localizationsDelegates,
      supportedLocales:AppLocalizations.supportedLocales,
      builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:const TextScaler.linear(2)),child:child!),
      home:CreatorApplicationPage(repository:CreatorApplicationRepository(transport:fixture.PageTransport(null))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Creator verification'),findsOneWidget);
    expect(find.text('Simple actions'),findsOneWidget);
    await tester.scrollUntilVisible(find.text('Submit application'),400,scrollable:find.byType(Scrollable).first);
    expect(find.text('Submit application').hitTestable(),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
}
