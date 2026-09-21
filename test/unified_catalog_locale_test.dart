import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';
import 'package:hildors_cockpit/src/features/community/creator_content_media.dart';
import 'package:hildors_cockpit/src/features/community/creator_content_repository.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_page.dart';

class UnavailableMedia implements CreatorContentMediaRepository {
  @override
  Future<CreatorContentMediaAccess> mediaAccess(CreatorContent item, CreatorContentClip clip, {bool refreshIdentity=false}) async => throw StateError('private internal failure');
}
Widget english(Widget child) => MaterialApp(locale: const Locale('en'), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body:child));
void main() {
  testWidgets('merged catalog retry remains English', (tester) async {
    await tester.pumpWidget(english(RemoteCatalogPage(load: () async => throw StateError('offline'))));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton,'Retry'),findsOneWidget);
    expect(find.text('重试'),findsNothing);
  });
  testWidgets('latest creator preview retains English label and safe failure', (tester) async {
    const clip=CreatorContentClip(id:'clip',title:'Robot',hasMedia:true,inspectionStatus:'checked');
    const item=CreatorContent(id:'item',title:'Robot',format:'single',status:'draft',submissionStatus:'draft',version:1,description:'',tags:[],clips:[clip]);
    await tester.pumpWidget(english(CreatorContentThumbnail(item:item,clip:clip,repository:UnavailableMedia())));
    await tester.pumpAndSettle();
    expect(find.text('Preview video'),findsOneWidget);
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.text('Unable to open this video. Refresh your submissions and try again.'),findsOneWidget);
    expect(find.textContaining('private internal'),findsNothing);
  });
}
