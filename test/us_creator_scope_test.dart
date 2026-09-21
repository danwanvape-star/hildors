import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/config/launch_config.dart';
import 'package:hildors_cockpit/src/features/community/creator_content_page.dart';
import 'package:hildors_cockpit/src/features/community/creator_content_repository.dart';
import 'package:hildors_cockpit/src/features/customization/creator_workbench_page.dart';
import 'creator_content_pricing_test.dart' as fixture;

void main() {
  testWidgets('launch profile controls custom projects and partner pricing', (tester) async {
    final transport = fixture.Transport(tier:'partner');
    await tester.pumpWidget(MaterialApp(home:CreatorWorkbenchPage(repository:RemoteCreatorContentRepository(transport))));
    expect(find.text('定制任务'), LaunchConfig.usFree ? findsNothing : findsOneWidget);
    await tester.tap(find.text('上传内容 / 我的投稿'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Title'));
    await tester.pumpAndSettle();
    final editor = tester.widget<CreatorContentEditorPage>(find.byType(CreatorContentEditorPage));
    expect(editor.canSetPaid, !LaunchConfig.usFree);
    expect(tester.takeException(),isNull);
  });
}
