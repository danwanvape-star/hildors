import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_device_profile.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/device/p20_command_session.dart';
import 'package:hildors_cockpit/src/protocol/p20_protocol.dart';
import 'package:hildors_cockpit/src/features/video/playlist_management_page.dart';
import 'package:hildors_cockpit/src/features/control/control_page.dart';
import 'package:hildors_cockpit/src/features/settings/settings_page.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';
import 'p20_live_playlist_test.dart' show LiveClient, LiveSession;

class SingleLiveClient extends LiveClient {
  @override
  P20DeviceProfile get profile =>
      const P20DeviceProfile.forKind(P20DeviceKind.single);
  @override
  bool get modernProtocol => false;
  @override
  DeviceConnectionState get connectionState => DeviceConnectionState.connected;
  final calls = <int>[];
  List<int> reply = [0, 0];
  @override
  Future<P20Frame> requestFrame(P20Command cmd,
      [List<int> data = const []]) async {
    calls.add(cmd.code);
    return P20Frame(command: cmd.code, data: Uint8List.fromList(reply));
  }
}

void main() {
  testWidgets('single playlist has no second list switch', (tester) async {
    final client = SingleLiveClient()..online = true;
    final session = LiveSession(client);
    await tester.pumpWidget(MaterialApp(
        home: PlaylistManagementPage(client: client, session: session)));
    await tester.pumpAndSettle();
    expect(find.text('B 蓝牙音乐'), findsNothing);
    expect(find.text('设备视频'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await session.dispose();
    await client.dispose();
  });
  testWidgets('single control hides bluetooth controls', (tester) async {
    final client = SingleLiveClient()..online = true;
    await tester.pumpWidget(MaterialApp(home: ControlPage(client: client)));
    await tester.pumpAndSettle();
    expect(client.calls, isNot(contains(0x73)));
    expect(find.byIcon(Icons.bluetooth), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await client.dispose();
  });
  testWidgets('settings exposes explicit device preference', (tester) async {
    final client = SingleLiveClient();
    final session = LiveSession(client);
    await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: SettingsPage(client: client, session: session)));
    expect(find.text('Device type'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await session.dispose();
    await client.dispose();
  });
  test('single rejects mismatched and excessive list metadata', () async {
    final client = SingleLiveClient();
    final session = P20CommandSession(client);
    for (final reply in [
      [51, 0, 120],
      [1, 1, 120],
      [1, 0],
      [1, 0, ...List.filled(33, 120)]
    ]) {
      client.reply = reply;
      await expectLater(
          session.queryVideo(0), throwsA(isA<P20CommandException>()));
    }
    client.reply = [0, 0];
    expect(await session.queryVideos(), isEmpty);
    await expectLater(session.queryVideos(listId: 1), throwsA(anything));
    await session.dispose();
    await client.dispose();
  });
  test('single blocks unsupported commands before any wire request', () async {
    final client = SingleLiveClient();
    final session = P20CommandSession(client);
    for (final command in [
      P20Command.factoryReset,
      P20Command.formatStorage,
      P20Command.queryBluetoothSpeakerName,
      P20Command.switchPlaylist
    ]) {
      await expectLater(
          session.request(command), throwsA(isA<P20CommandException>()));
    }
    expect(client.calls, isEmpty);
    await session.dispose();
    await client.dispose();
  });
}
