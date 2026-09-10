import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_command_session.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/features/profile/profile_page.dart';
import 'package:hildors_cockpit/src/theme/hildors_theme.dart';

void main() {
  testWidgets('玩家档案页在窄屏显示核心入口且无布局异常', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final client = P20DeviceClient();
    final session = P20CommandSession(client);
    addTearDown(session.dispose);
    addTearDown(client.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildHildorsTheme(),
        home: ProfilePage(client: client, session: session),
      ),
    );

    expect(find.text('玩家档案'), findsOneWidget);
    expect(find.text('设备'), findsOneWidget);
    expect(find.text('播放列表'), findsOneWidget);
    expect(find.text('设备内容'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Character Portal'),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Character Portal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
