import 'package:hildors_cockpit/src/localization/localization.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/device/p20_command_session.dart';
import 'package:hildors_cockpit/src/device/p20_v2_connection.dart';
import 'package:hildors_cockpit/src/features/video/fan_framing_page.dart';
import 'package:hildors_cockpit/src/features/video/p20_media_upload_flow.dart';
import 'package:hildors_cockpit/src/features/video/p20_upload_page.dart';
import 'package:hildors_cockpit/src/features/video/p20_ffmpeg_preparation.dart';

class ConnectedClient extends P20DeviceClient {
  ConnectedClient() : super(modernProtocol: true);
  String? uploadedName;
  bool failUpload = false;
  @override
  bool get isConnected => true;
  @override
  Future<void> uploadFile(File file, int listId, List<int> name,
      {void Function(int, int)? onProgress}) async {
    if (failUpload) {
      lastUploadSnapshot = const P20UploadSnapshot(
          P20UploadPhase.awaitingCompletion, 100, 50, 100);
      onProgress?.call(50, 100);
      throw TimeoutException('P20 cmd=0x31 rx=0 valid=0 rejected=0');
    }
    uploadedName = String.fromCharCodes(name);
  }
}

class TestSession extends P20CommandSession {
  TestSession(super.client, this.failRefresh);
  final bool failRefresh;
  @override
  Future<List<P20VideoEntry>> queryVideos({int listId = 0}) async {
    if (failRefresh) throw StateError('offline');
    return [];
  }
}

class TestEngine implements P20MediaEngine {
  int calls = 0;
  @override
  bool get isIdle => true;
  @override
  Future<void> cancel() async {}
  @override
  Future<String> execute(List<String> args, {bool probe = false}) async {
    calls++;
    await File(args.last).writeAsBytes(List.filled(298 * 298 * 3, 0));
    return '';
  }
}

void main() {
  const paths = MethodChannel('plugins.flutter.io/path_provider');
  testWidgets('failed upload retains confirmed progress and a specific error',
      (tester) async {
    final temp = (await tester
        .runAsync(() => Directory.systemTemp.createTemp('p20-progress-')))!;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(paths, (_) async => temp.path);
    final client = ConnectedClient()..failUpload = true;
    final session = TestSession(client, false);
    addTearDown(session.dispose);
    addTearDown(client.dispose);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(paths, null);
    });
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: P20UploadPage(
            client: client,
            session: session,
            source: '${temp.path}/source.mp4',
            asset: false,
            list: P20MediaList.bluetooth,
            framing: const FanFraming(),
            engine: TestEngine())));
    await tester.runAsync(() async {
      await tester.tap(find.text('Prepare and upload'));
      for (var i = 0;
          i < 100 && find.text('Back to playlist').evaluate().isEmpty;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('P20 cmd=0x31 rx=0 valid=0 rejected=0'), findsOneWidget);
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        0.5);
    expect(find.textContaining('timed out'), findsOneWidget);
    expect(find.textContaining('Uploading video'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => temp.delete(recursive: true));
  });
  for (final systemBack in [false, true]) {
    testWidgets(
        'confirmed upload survives ${systemBack ? 'system' : 'toolbar'} back, including failed refresh',
        (tester) async {
      final temp = (await tester
          .runAsync(() => Directory.systemTemp.createTemp('p20-page-')))!;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(paths, (_) async => temp.path);
      final client = ConnectedClient();
      final session = TestSession(client, systemBack);
      final engine = TestEngine();
      String? result;
      await tester.pumpWidget(MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      child: const Text('open'),
                      onPressed: () async {
                        result = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                                builder: (_) => P20UploadPage(
                                    client: client,
                                    session: session,
                                    source: '${temp.path}/source.mp4',
                                    asset: false,
                                    list: P20MediaList.bluetooth,
                                    framing: const FanFraming(),
                                    engine: engine)));
                      })))));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Prepare and upload'));
        for (var i = 0;
            i < 100 && find.text('Back to playlist').evaluate().isEmpty;
            i++) {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          await tester.pump();
        }
      });
      await tester.pumpAndSettle();
      expect(client.uploadedName, isNotNull);
      if (systemBack) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.byType(BackButton));
      }
      await tester.pumpAndSettle();
      expect(result, client.uploadedName);
      await tester.pumpWidget(const SizedBox());
      addTearDown(session.dispose);
      addTearDown(client.dispose);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(paths, null);
      await tester.runAsync(() => temp.delete(recursive: true));
    });
  }
  testWidgets(
      'disposal while resolving temporary directory prevents processing',
      (tester) async {
    final temp = (await tester
        .runAsync(() => Directory.systemTemp.createTemp('p20-dispose-')))!;
    final resolve = Completer<String>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(paths, (_) => resolve.future);
    final engine = TestEngine();
    final client = ConnectedClient();
    final session = TestSession(client, false);
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: P20UploadPage(
            client: client,
            session: session,
            source: '${temp.path}/source.mp4',
            asset: false,
            list: P20MediaList.bluetooth,
            framing: const FanFraming(),
            engine: engine)));
    await tester.tap(find.text('Prepare and upload'));
    await tester.pumpWidget(const SizedBox());
    resolve.complete(temp.path);
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump();
    }
    expect(engine.calls, 0);
    expect(client.uploadedName, isNull);
    addTearDown(session.dispose);
    addTearDown(client.dispose);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(paths, null);
    await tester.runAsync(() => temp.delete(recursive: true));
  });
  testWidgets('disconnected device cannot start transcoding or upload',
      (tester) async {
    final client = P20DeviceClient(modernProtocol: true);
    final session = P20CommandSession(client);
    addTearDown(session.dispose);
    addTearDown(client.dispose);
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: P20UploadPage(
          client: client,
          session: session,
          source: '/not-accessed.mp4',
          asset: false,
          list: P20MediaList.bluetooth,
          framing: const FanFraming(),
        )));
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(find.textContaining('video only'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
