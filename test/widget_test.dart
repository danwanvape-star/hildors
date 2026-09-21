import 'package:hildors_cockpit/src/config/launch_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/app.dart';

void main() {
  testWidgets('shows the playlist-first cockpit shell', (tester) async {
    tester.binding.platformDispatcher.localesTestValue = [const Locale('zh')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
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

    if (LaunchConfig.usFree) {
      expect(find.text('定制你的专属全息角色'), findsNothing);
    } else {
      await tester.scrollUntilVisible(
        find.text('定制你的专属全息角色'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('定制你的专属全息角色'), findsOneWidget);
    }
    expect(find.text('角色之门'), findsNWidgets(LaunchConfig.usFree ? 1 : 2));

    await tester.tap(find.text('发现'));
    await tester.pump();
    expect(
        find.text('专属定制'), LaunchConfig.usFree ? findsNothing : findsOneWidget);
    expect(
        find.text('角色许愿'), LaunchConfig.usFree ? findsNothing : findsOneWidget);
    expect(find.text('创作者中心'), findsOneWidget);
    expect(find.text('Holo Roulette'), findsNothing);
  });
}
