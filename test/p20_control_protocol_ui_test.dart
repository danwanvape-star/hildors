import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_command_session.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/protocol/p20_protocol.dart';
import 'package:hildors_cockpit/src/features/control/control_page.dart';
import 'package:hildors_cockpit/src/features/video/video_page.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';

class ConnectedClient extends P20DeviceClient {
  ConnectedClient() : super(modernProtocol: true);
  final calls = <(P20Command, List<int>)>[];
  int playerStatus = 1;
  bool rejectPlayback = false;
  @override
  DeviceConnectionState get connectionState => DeviceConnectionState.connected;
  @override
  bool get isConnected => true;
  @override
  Future<P20Frame> requestFrame(P20Command command,
      [List<int> data = const []]) async {
    calls.add((command, data));
    List<int> reply;
    if (command == P20Command.playback) {
      if (rejectPlayback) {
        reply = [3, 2];
      } else {
        playerStatus = data.single;
        reply = [playerStatus, 1];
      }
    } else {
      reply = switch (command) {
        P20Command.queryStatus => [1, playerStatus, 0, 0, 0, 1, 0, 1],
        P20Command.queryCurrentVideo => [1, 0, playerStatus],
        P20Command.queryBluetoothSpeakerName => [0],
        P20Command.queryVideoList => [0, 1, 0, ...'a.mp4'.codeUnits],
        _ => [1],
      };
    }
    return P20Frame(command: command.code, data: Uint8List.fromList(reply));
  }
}

Widget app(Widget child) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child);
void main() {
  testWidgets('connected controls query actual playback and toggle both ways',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = ConnectedClient();
    addTearDown(client.dispose);
    await tester.pumpWidget(app(ControlPage(client: client)));
    await tester.pumpAndSettle();
    expect(client.calls.any((call) => call.$1 == P20Command.queryCurrentVideo),
        isTrue);
    await tester.ensureVisible(find.byIcon(Icons.pause));
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();
    expect(
        client.calls
            .where((call) => call.$1 == P20Command.playback)
            .map((call) => call.$2.single),
        [2, 1]);
  });
  testWidgets('playback rejection is visible and does not claim pause',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = ConnectedClient()..rejectPlayback = true;
    addTearDown(client.dispose);
    await tester.pumpWidget(app(ControlPage(client: client)));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(ControlPage));
    expect(find.text(context.l10n.errorNetwork), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(client.playerStatus, 1);
  });
  testWidgets('modern brightness permits zero', (tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = ConnectedClient();
    addTearDown(client.dispose);
    await tester.pumpWidget(app(ControlPage(client: client)));
    await tester.pumpAndSettle();

    expect(tester.widget<Slider>(find.byType(Slider).first).min, 0);
  });
  testWidgets('already connected library reads A without marking B playback',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = ConnectedClient();
    final session = P20CommandSession(client);
    addTearDown(session.dispose);
    addTearDown(client.dispose);
    await tester.pumpWidget(app(VideoPage(client: client, session: session)));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.sync));
    await tester.pumpAndSettle();
    expect(find.text('a.mp4'), findsOneWidget);
    expect(find.text('Playing'), findsNothing);
  });
}
