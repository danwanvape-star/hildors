import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/video/playlist_management_page.dart';
import 'p20_live_playlist_test.dart' show LiveClient, LiveSession;

void main() {
  testWidgets('device delete requires confirmation and add remains pinned', (tester) async {
    final client = LiveClient()..online = true;
    final session = LiveSession(client);
    addTearDown(session.dispose); addTearDown(client.dispose);
    await tester.pumpWidget(MaterialApp(home: PlaylistManagementPage(client: client, session: session)));
    await tester.pumpAndSettle();
    final add = find.byIcon(Icons.playlist_add);
    final position = tester.getTopLeft(add);
    await tester.ensureVisible(find.byIcon(Icons.delete_outline).first);
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(session.calls.where((s) => s.startsWith('delete:')), isEmpty);
    await tester.tap(find.text('永久删除'));
    await tester.pumpAndSettle();
    expect(session.calls, contains('delete:0:a.mp4'));
    expect(find.text('a.mp4'), findsNothing);
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(add), position);
  });
  testWidgets('offline page has no fabricated device videos', (tester) async {
    final client = LiveClient();
    final session = LiveSession(client);
    addTearDown(session.dispose);
    addTearDown(client.dispose);
    await tester.pumpWidget(MaterialApp(
        home: PlaylistManagementPage(client: client, session: session)));
    await tester.pumpAndSettle();
    expect(find.text('showcase_01.mp4'), findsNothing);
    expect(find.text('showcase_02.mp4'), findsNothing);
    expect(find.text('连接设备后显示机器内的播放列表'), findsOneWidget);
  });
  testWidgets(
      'connected page reads and reorders actual list; disconnect clears it',
      (tester) async {
    final client = LiveClient()..online = true;
    final session = LiveSession(client);
    addTearDown(session.dispose);
    addTearDown(client.dispose);
    await tester.pumpWidget(MaterialApp(
        home: PlaylistManagementPage(client: client, session: session)));
    await tester.pumpAndSettle();
    expect(find.text('a.mp4'), findsOneWidget);
    expect(find.text('b.mp4'), findsOneWidget);
    await tester.ensureVisible(find.text('下移').first);
    await tester.tap(find.text('下移').first);
    await tester.pumpAndSettle();
    expect(session.calls, contains('move:0:2:0:1'));
    client.setOnline(false);
    await tester.pumpAndSettle();
    expect(find.text('a.mp4'), findsNothing);
    expect(find.text('b.mp4'), findsNothing);
  });
}
