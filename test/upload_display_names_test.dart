import 'package:hildors_cockpit/src/features/video/playlist_management_page.dart';
import 'p20_live_playlist_test.dart' show LiveClient, LiveSession;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';
import 'package:hildors_cockpit/src/features/video/upload_display_names.dart';
import 'package:hildors_cockpit/src/features/video/upload_name_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('upload-names-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => directory.path);
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await directory.delete(recursive: true);
  });
  test('Chinese labels persist with unique compatible short filenames',
      () async {
    final names = await Future.wait([
      UploadDisplayNames.reserve('中文角色'),
      UploadDisplayNames.reserve('中文角色')
    ]);
    expect(names.toSet(), hasLength(2));
    for (final name in names) {
      expect(RegExp(r'^[a-f0-9]{8}$').hasMatch(name), isTrue);
      expect('$name.mp4'.codeUnits, hasLength(12));
    }
    expect(await UploadDisplayNames.load(),
        {for (final name in names) '$name.mp4': '中文角色'});
  });
  testWidgets(
      'device row uses local label but deletion sends original filename',
      (tester) async {
    final base =
        await tester.runAsync(() => UploadDisplayNames.reserve('我的角色'));
    final client = LiveClient()..online = true;
    final session = LiveSession(client);
    session.files[0] = ['$base.mp4'];
    addTearDown(client.dispose);
    addTearDown(session.dispose);
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(
          home: PlaylistManagementPage(client: client, session: session)));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.text('我的角色'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('从设备永久删除'));
    await tester.pumpAndSettle();
    expect(find.text('$base.mp4'), findsOneWidget);
    await tester.tap(find.text('永久删除'));
    await tester.pumpAndSettle();
    expect(session.calls, contains('delete:0:$base.mp4'));
    expect(find.text('我的角色'), findsNothing);
  });
  testWidgets('name dialog rejects blank and returns Chinese title',
      (tester) async {
    String? result;
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
            builder: (context) => TextButton(
                onPressed: () async {
                  result = await chooseUploadDisplayName(context, 'Original');
                },
                child: const Text('open')))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.enterText(find.byType(TextField), '我的角色');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(result, '我的角色');
    expect(tester.takeException(), isNull);
  });
}
