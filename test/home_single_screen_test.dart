import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/device/p20_command_session.dart';
import 'package:hildors_cockpit/src/experience/projection_service.dart';
import 'package:hildors_cockpit/src/features/home/home_page.dart';
import 'package:hildors_cockpit/src/theme/hildors_theme.dart';

void main() {
  testWidgets('首页常用入口在手机一屏内可见', (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = P20DeviceClient();
    final session = P20CommandSession(client);
    addTearDown(client.dispose);
    addTearDown(session.dispose);
    await tester.pumpWidget(MaterialApp(
        theme: buildHildorsTheme(),
        home: Scaffold(
          bottomNavigationBar: const SizedBox(height: 72),
          body: HomePage(
              client: client,
              session: session,
              projection: P20ProjectionService(client, session)),
        )));
    expect(find.text('Character Portal'), findsOneWidget);
    for (final label in ['日常展示', '音乐联动', '定制你的专属全息角色']) {
      expect(find.text(label).hitTestable(), findsOneWidget);
    }
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scroll.position.maxScrollExtent, 0);
    expect(tester.takeException(), isNull);
  });
}
