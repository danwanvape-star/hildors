import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/video/playlist_management_page.dart';
import 'p20_live_playlist_test.dart' show LiveClient, LiveSession;

void main() {
  testWidgets('one-line device rows pin to top and omit framing',
      (tester) async {
    final client = LiveClient()..online = true;
    final session = LiveSession(client);
    session.files[0] = ['a.mp4', 'b.mp4', 'long_video_filename_c.mp4'];
    addTearDown(session.dispose);
    addTearDown(client.dispose);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: PlaylistManagementPage(client: client, session: session)));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const ValueKey('device-video-0'))).height,
        lessThanOrEqualTo(64));
    expect(find.byIcon(Icons.crop), findsNothing);
    expect(
        tester
            .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.vertical_align_top).first)
            .onPressed,
        isNull);
    await tester.tap(find.byTooltip('置顶').last);
    await tester.pumpAndSettle();
    expect(session.calls, contains('move:0:3:2:0'));
    expect(session.files[0]!.first, 'long_video_filename_c.mp4');
    expect(tester.getTopLeft(find.text('long_video_filename_c.mp4')).dy,
        lessThan(tester.getTopLeft(find.text('a.mp4')).dy));
    expect(tester.takeException(), isNull);
  });
  testWidgets('delete confirmation cannot delete a replacement device file',
      (tester) async {
    final client = LiveClient()..online = true;
    final session = LiveSession(client);
    await tester.pumpWidget(MaterialApp(
        home: PlaylistManagementPage(client: client, session: session)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('从设备永久删除'));
    await tester.pumpAndSettle();
    client.setOnline(false);
    await tester.pump();
    client.setOnline(true);
    await tester.pumpAndSettle();
    await tester.tap(find.text('永久删除'));
    await tester.pumpAndSettle();
    expect(session.calls.where((s) => s.startsWith('delete:')), isEmpty);
    expect(find.text('a.mp4'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await session.dispose();
    await client.dispose();
  });
  testWidgets('long list scrolls independently of fixed controls',
      (tester) async {
    final client = LiveClient()..online = true;
    final session = LiveSession(client);
    session.files[0] = List.generate(30, (i) => ['video_', i, '.mp4'].join());
    addTearDown(session.dispose);
    addTearDown(client.dispose);
    await tester.pumpWidget(MaterialApp(
        home: PlaylistManagementPage(client: client, session: session)));
    await tester.pumpAndSettle();
    final tabs = find.text('A 日常播放');
    final before = tester.getTopLeft(tabs);
    expect(find.text('video_0.mp4'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(tabs), before);
    expect(find.text('video_0.mp4'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('device delete requires confirmation and add remains pinned',
      (tester) async {
    final client = LiveClient()..online = true;
    final session = LiveSession(client);
    addTearDown(session.dispose);
    addTearDown(client.dispose);
    await tester.pumpWidget(MaterialApp(
        home: PlaylistManagementPage(client: client, session: session)));
    await tester.pumpAndSettle();
    final add = find.byIcon(Icons.playlist_add);
    final position = tester.getTopLeft(add);
    final headerPosition = tester.getTopLeft(find.text('A 日常播放'));
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('从设备永久删除'));
    await tester.pumpAndSettle();
    expect(session.calls.where((s) => s.startsWith('delete:')), isEmpty);
    await tester.tap(find.text('永久删除'));
    await tester.pumpAndSettle();
    expect(session.calls, contains('delete:0:a.mp4'));
    expect(find.text('a.mp4'), findsNothing);
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(add), position);
    expect(tester.getTopLeft(find.text('A 日常播放')), headerPosition);
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
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('下移'));
    await tester.pumpAndSettle();
    expect(session.calls, contains('move:0:2:0:1'));
    client.setOnline(false);
    await tester.pumpAndSettle();
    expect(find.text('a.mp4'), findsNothing);
    expect(find.text('b.mp4'), findsNothing);
  });
}
