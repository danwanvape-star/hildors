import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';
import 'package:hildors_cockpit/src/features/community/creator_content_page.dart';
import 'package:hildors_cockpit/src/features/community/creator_content_repository.dart';
import 'creator_content_pricing_test.dart' as fixture;

void main() {
  test('translated tags retain their stable identifier', () {
    final tag=CreatorContentTag.fromJson({'id':'genre-1','name':'幻想','active':true,'translations':{'en':{'name':'Fantasy'}}});
    expect(tag.id,'genre-1');expect(tag.name,'幻想');expect(tag.displayName('en'),'Fantasy');expect(tag.displayName('zh'),'幻想');
  });
  testWidgets('English free submission editor fits large text', (tester) async {
    tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(locale:const Locale('en'),
      localizationsDelegates:AppLocalizations.localizationsDelegates,supportedLocales:AppLocalizations.supportedLocales,
      builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:const TextScaler.linear(2)),child:child!),
      home:CreatorContentEditorPage(repository:RemoteCreatorContentRepository(fixture.Transport()),availableTags:const [],initial:CreatorContent.fromJson(fixture.content)),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Submit for review'),300,scrollable:find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('Submit for review').hitTestable(),findsOneWidget);
    expect(find.text('Set price'),findsNothing);
    expect(tester.takeException(),isNull);
  });
}
