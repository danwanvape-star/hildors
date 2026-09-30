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
  int playMode = 1;
  @override
  DeviceConnectionState get connectionState => DeviceConnectionState.connected;
  @override
  bool get isConnected => true;
  @override
  Future<P20Frame> requestFrame(P20Command command,
      [List<int> data = const []]) async {
    calls.add((command, data));
    List<int> reply;
    if (command == P20Command.setPlayMode) playMode = data.single;
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
        P20Command.queryPlayMode => [playMode],
        P20Command.setPlayMode => [playMode, 1],
        P20Command.setBrightness => [data.single, 1],
        P20Command.setAngle => [...data, 1],
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
  testWidgets('console only exposes brightness and angle without extra queries',
      (tester) async {
    final client = ConnectedClient();
    addTearDown(client.dispose);
    await tester.pumpWidget(app(ControlPage(client: client)));
    await tester.pumpAndSettle();
    expect(find.text('Control panel'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(2));
    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.pause), findsNothing);
    expect(client.calls.map((c) => c.$1),
        [P20Command.queryPlayMode, P20Command.queryStatus]);
    tester
        .widget<DropdownButtonFormField<P20PlayMode>>(
            find.byType(DropdownButtonFormField<P20PlayMode>))
        .onChanged!(P20PlayMode.randomLoop);
    await tester.pumpAndSettle();
    expect(client.playMode, 3);
    expect(
        tester
            .widget<DropdownButtonFormField<P20PlayMode>>(
                find.byType(DropdownButtonFormField<P20PlayMode>))
            .initialValue,
        P20PlayMode.randomLoop);
    tester.widget<Slider>(find.byType(Slider).first).onChangeEnd!(45);
    await tester.pumpAndSettle();
    expect(
        client.calls
            .any((c) => c.$1 == P20Command.setBrightness && c.$2.single == 45),
        isTrue);
    tester.widget<Slider>(find.byType(Slider).last).onChangeEnd!(90);
    await tester.pumpAndSettle();
    expect(
        client.calls.any(
            (c) => c.$1 == P20Command.setAngle && c.$2.join(',') == '0,90'),
        isTrue);
  });
  testWidgets('offline console disables both adjustments', (tester) async {
    await tester.pumpWidget(app(const ControlPage()));
    await tester.pumpAndSettle();
    for (final slider in tester.widgetList<Slider>(find.byType(Slider))) {
      expect(slider.onChanged, isNull);
    }
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
