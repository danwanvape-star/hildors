import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_command_session.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/features/video/video_page.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';
import 'p20_live_playlist_test.dart' show LiveClient, LiveSession;

class VideoClient extends LiveClient {
  @override
  DeviceConnectionState get connectionState => online
      ? DeviceConnectionState.connected
      : DeviceConnectionState.disconnected;
}

class VideoSession extends LiveSession {
  VideoSession(super.client);
  @override
  Future<P20CurrentVideo> queryCurrentVideo() async =>
      const P20CurrentVideo(index: 0, playing: false);
}

void main() {
  testWidgets('legacy video page rejects old-device delete confirmation',
      (tester) async {
    final client = VideoClient()..online = true;
    final session = VideoSession(client);
    final text = lookupAppLocalizations(const Locale('zh'));
    await tester.pumpWidget(
        MaterialApp(home: VideoPage(client: client, session: session)));
    await tester.tap(find.byIcon(Icons.sync));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text.deviceDeleteFrom));
    await tester.pumpAndSettle();
    client.setOnline(false);
    await tester.pump();
    client.setOnline(true);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text.deviceDelete));
    await tester.pumpAndSettle();
    expect(session.calls.where((s) => s.startsWith('delete:')), isEmpty);
    await tester.pumpWidget(const SizedBox());
    await session.dispose();
    await client.dispose();
  });
}
