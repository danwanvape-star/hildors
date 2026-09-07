import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/app.dart';

void main() {
  testWidgets('shows the cockpit controller shell', (tester) async {
    await tester.pumpWidget(const CockpitApp());

    expect(find.text('HILDORS'), findsOneWidget);
    expect(find.text('当前角色'), findsOneWidget);
    expect(find.text('日常展示'), findsWidgets);
    expect(find.text('音乐联动'), findsOneWidget);
    expect(find.text('定制你的专属全息角色'), findsNothing);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('藏品'), findsOneWidget);
    expect(find.text('发现'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    await tester.tap(find.text('发现'));
    await tester.pump();
    expect(find.text('定制你的专属全息角色'), findsOneWidget);
  });
}
