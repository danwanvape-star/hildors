import 'package:hildors_cockpit/src/features/customization/custom_plans_page.dart';
import 'package:hildors_cockpit/src/config/launch_config.dart';
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

    expect(find.text('玩家档案'), findsNWidgets(2));
    expect(find.text('设备'), findsOneWidget);
    expect(find.text('播放列表'), findsOneWidget);
    expect(find.text('设备内容'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text(LaunchConfig.usFree ? '定制视频套餐' : '定制订单'),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.pumpAndSettle();
    if (LaunchConfig.usFree) {
      expect(find.text('定制订单'), findsNothing);
      expect(find.text('定制视频套餐').hitTestable(), findsOneWidget);
      await tester.tap(find.text('定制视频套餐'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CustomPlansPage), findsOneWidget);
      expect(find.text('商店支付尚未接通，目前不会收款。'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    } else {
      expect(find.text('定制订单'), findsOneWidget);
      expect(find.text('定制视频套餐'), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });
}
