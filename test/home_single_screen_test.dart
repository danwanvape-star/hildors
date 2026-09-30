import 'package:hildors_cockpit/src/localization/locale_controller.dart';
import 'package:hildors_cockpit/src/device/p20_device_profile.dart';
import 'package:hildors_cockpit/src/config/launch_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/device/p20_command_session.dart';
import 'package:hildors_cockpit/src/experience/projection_service.dart';
import 'package:hildors_cockpit/src/features/home/home_page.dart';
import 'package:hildors_cockpit/src/theme/hildors_theme.dart';

class MemoryLanguageStorage implements LocaleStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
  }
}

void main() {
  testWidgets('home language menu saves selection using shared controller',
      (tester) async {
    final storage = MemoryLanguageStorage();
    final locale = LocaleController(storage: storage);
    final client = P20DeviceClient();
    final session = P20CommandSession(client);
    addTearDown(locale.dispose);
    addTearDown(client.dispose);
    addTearDown(session.dispose);
    await tester.pumpWidget(LocaleScope(
        controller: locale,
        child: MaterialApp(
            home: HomePage(
                client: client,
                session: session,
                projection: P20ProjectionService(client, session)))));
    await tester.tap(find.byKey(const Key('home-language')));
    await tester.pumpAndSettle();
    for (final label in ['简体中文', 'English', 'Deutsch', 'Español', '日本語']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();
    expect(locale.choice, LanguageChoice.german);
    expect(storage.value, 'german');
    expect(tester.takeException(), isNull);
  });
  testWidgets('首页常用入口在手机一屏内可见', (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = P20DeviceClient(preference: P20DevicePreference.dual);
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
    expect(find.text('角色之门'), findsNWidgets(LaunchConfig.usFree ? 1 : 2));
    expect(find.text('定制你的专属全息角色'),
        LaunchConfig.usFree ? findsNothing : findsOneWidget);
    for (final label in [
      '日常展示',
      '音乐联动',
      if (!LaunchConfig.usFree) '定制你的专属全息角色'
    ]) {
      expect(find.text(label).hitTestable(), findsOneWidget);
    }
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scroll.position.maxScrollExtent, 0);
    expect(tester.takeException(), isNull);
  });
}
