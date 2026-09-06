import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/app.dart';

void main() {
  testWidgets('shows the cockpit controller shell', (tester) async {
    await tester.pumpWidget(const CockpitApp());

    expect(find.text('HILDORS'), findsOneWidget);
    expect(find.text('定制你的专属全息角色'), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('探索'), findsOneWidget);
    expect(find.text('内容库'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });
}
