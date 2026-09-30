import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_command_session.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/device/p20_device_profile.dart';
import 'package:hildors_cockpit/src/experience/projection_service.dart';
import 'package:hildors_cockpit/src/features/dashboard/dashboard_page.dart';
import 'package:hildors_cockpit/src/features/home/home_page.dart';
import 'package:hildors_cockpit/src/features/settings/settings_page.dart';
import 'package:hildors_cockpit/src/theme/hildors_theme.dart';

// Replace only network connection attempts; retain the real disconnect policy.
class _CountingClient extends P20DeviceClient {
  int attempts = 0;
  @override
  Future<void> connect({String host = '192.168.4.1', int port = 8900}) async {
    attempts++;
  }
}

void main() {
  test('Network loss still reconnects and explicit connect resumes after stop',
      () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final peers = <Socket>[];
    final accepted = Completer<Socket>();
    final subscription = server.listen((socket) {
      peers.add(socket);
      if (!accepted.isCompleted) accepted.complete(socket);
    });
    final client = P20DeviceClient();
    try {
      await client.connect(host: '127.0.0.1', port: server.port);
      final firstPeer = await accepted.future;
      final reconnected = client.connectionStates
          .firstWhere((state) => state == DeviceConnectionState.connected);
      firstPeer.destroy();
      await reconnected.timeout(const Duration(seconds: 5));
      expect(client.isConnected, isTrue);
      expect(client.autoConnectAllowed, isTrue);
      await client.disconnect();
      expect(client.autoConnectAllowed, isFalse);
      await client.connect(host: '127.0.0.1', port: server.port);
      expect(client.isConnected, isTrue);
      expect(client.autoConnectAllowed, isTrue);
    } finally {
      await client.dispose();
      for (final peer in peers) {
        peer.destroy();
      }
      await subscription.cancel();
      await server.close();
    }
  });
  testWidgets('Dashboard stops automatic attempts after explicit disconnect',
      (tester) async {
    final client = _CountingClient();
    final session = P20CommandSession(client);
    await tester.pumpWidget(MaterialApp(
      theme: buildHildorsTheme(),
      home: DashboardPage(client: client, session: session),
    ));
    await tester.pump();
    expect(client.attempts, 1);
    await client.disconnect();
    await tester.pump(const Duration(seconds: 11));
    expect(client.attempts, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
    await client.dispose();
  });

  for (final preference in P20DevicePreference.values) {
    testWidgets('Offline $preference only offers music for selected PORTAL',
        (tester) async {
      final client = P20DeviceClient(preference: preference);
      final session = P20CommandSession(client);
      addTearDown(client.dispose);
      addTearDown(session.dispose);
      await tester.pumpWidget(MaterialApp(
        theme: buildHildorsTheme(),
        home: HomePage(
          client: client,
          session: session,
          projection: P20ProjectionService(client, session),
        ),
      ));
      expect(
          find.text('音乐联动'),
          preference == P20DevicePreference.dual
              ? findsOneWidget
              : findsNothing);
      expect(find.text('设备未连接'), findsWidgets);
      expect(client.isConnected, isFalse);
    });
  }

  testWidgets('Settings identifies the supported P20 family without P11',
      (tester) async {
    final client = P20DeviceClient();
    final session = P20CommandSession(client);
    addTearDown(client.dispose);
    addTearDown(session.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: buildHildorsTheme(),
      home: SettingsPage(client: client, session: session),
    ));
    await tester.drag(find.byType(ListView), const Offset(0, -220));
    await tester.pump();
    expect(find.text('P20 / P11'), findsNothing);
  });
}
