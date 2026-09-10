import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_command_session.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/features/settings/settings_page.dart';
import 'package:hildors_cockpit/src/theme/hildors_theme.dart';

void main() {
  testWidgets('设备设置页在窄屏展示清晰状态且无布局异常', (tester) async {
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
        home: SettingsPage(client: client, session: session),
      ),
    );

    expect(find.text('设备未连接'), findsOneWidget);
    expect(find.text('OFFLINE'), findsOneWidget);
    expect(find.text('单曲循环'), findsOneWidget);
    expect(find.text('顺序循环'), findsOneWidget);
    expect(find.textContaining('SocketException'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('局域网连接帮助'),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('局域网连接帮助'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
