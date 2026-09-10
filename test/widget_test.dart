import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/app.dart';

void main() {
  testWidgets('shows the playlist-first cockpit shell', (tester) async {
    await tester.pumpWidget(const CockpitApp());

    expect(find.text('HILDORS'), findsOneWidget);
    expect(find.text('设备播放列表'), findsOneWidget);
    expect(find.text('日常展示'), findsOneWidget);
    expect(find.text('音乐联动'), findsOneWidget);
    expect(find.text('当前角色'), findsNothing);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('藏品'), findsOneWidget);
    expect(find.text('发现'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('定制你的专属全息角色'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('定制你的专属全息角色'), findsOneWidget);
    expect(find.text('CHARACTER PORTAL'), findsOneWidget);

    await tester.tap(find.text('发现'));
    await tester.pump();
    expect(find.text('定制你的专属全息角色'), findsOneWidget);
    expect(find.text('Holo Roulette'), findsNothing);
  });
}
