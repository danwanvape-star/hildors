import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';
import 'package:hildors_cockpit/src/device/p20_v2_connection.dart';
import 'package:hildors_cockpit/src/features/video/p20_upload_strings.dart';
import 'package:hildors_cockpit/src/features/video/p20_media_upload_flow.dart';
import 'package:hildors_cockpit/src/features/video/p20_upload_page.dart';
import 'package:hildors_cockpit/src/features/video/fan_framing_page.dart';
import 'package:hildors_cockpit/src/features/video/playlist_management_page.dart';
import 'p20_live_playlist_test.dart' show LiveClient, LiveSession;

Widget localized(Widget child, {String language = 'en', double scale = 1}) =>
    MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: child,
    );

void main() {
  for (final language in ['en', 'zh']) {
    testWidgets(
        '$language upload stages and errors use resources without raw errors',
        (tester) async {
      late P20UploadStrings text;
      await tester.pumpWidget(localized(Builder(builder: (context) {
        text = P20UploadStrings(context);
        return const SizedBox();
      }), language: language));
      await tester.pumpAndSettle();
      final messages = [
        for (final stage in P20MediaStage.values) text.stage(stage),
        for (final status in [0x80, 0x81, 0x82, 0x85, 0x8a, 0x99])
          text.error(
              P20DeviceUploadRejected(status), P20MediaStage.uploadingVideo),
        text.error(
            TimeoutException('SECRET_PROTOCOL'), P20MediaStage.uploadingVideo),
        text.error(TimeoutException('SECRET_PROTOCOL'),
            P20MediaStage.transcodingVideo),
        text.error(const SocketException('SECRET_PROTOCOL'),
            P20MediaStage.uploadingAudio),
        text.error(
            const FileSystemException('SECRET_PROTOCOL'), P20MediaStage.idle),
        text.error(const FormatException('SECRET_PROTOCOL'),
            P20MediaStage.uploadingVideo),
        text.error(StateError('SECRET_PROTOCOL'), P20MediaStage.idle),
        text.transferDetails(const P20UploadSnapshot(
            P20UploadPhase.awaitingCompletion, 100, 50, 100)),
      ];
      expect(messages.any((message) => message.contains('SECRET_PROTOCOL')),
          isFalse);
      expect(messages.every((message) => message.isNotEmpty), isTrue);
      if (language == 'en') {
        expect(
            messages
                .any((message) => RegExp(r'[\u3400-\u9fff]').hasMatch(message)),
            isFalse);
      }
      expect(text.settings, contains('298 × 298'));
      expect(text.settings, contains('20'));
      expect(text.bluetooth,
          contains(language == 'en' ? 'source audio is ignored' : '不读取原视频音频'));
      expect(text.daily,
          contains(language == 'en' ? 'with or without sound' : '有声和无声'));
    });
  }
  testWidgets(
      'English live A/B lists and rejected changes remain readable at large text',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = LiveClient()..online = true;
    final session = LiveSession(client)..reject = true;
    addTearDown(session.dispose);
    addTearDown(client.dispose);
    await tester.pumpWidget(localized(
        PlaylistManagementPage(client: client, session: session),
        scale: 2));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('a.mp4'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('a.mp4'), findsOneWidget);
    expect(find.textContaining('Awaiting protocol support'), findsNothing);
    final down =
        find.widgetWithIcon(OutlinedButton, Icons.arrow_downward).first;
    await tester.ensureVisible(down);
    await tester.pumpAndSettle();
    await tester.tap(down);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.textContaining('did not confirm'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('did not confirm'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('B Bluetooth'), -300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('B Bluetooth'));
    await tester.pumpAndSettle();
    expect(session.calls, contains('read:1'));
    await tester.scrollUntilVisible(find.text('bluetooth.mp4'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('bluetooth.mp4'), findsOneWidget);
    expect(find.text('a.mp4'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('English upload actions remain accessible at large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = LiveClient();
    final session = LiveSession(client);
    addTearDown(session.dispose);
    addTearDown(client.dispose);
    await tester.pumpWidget(localized(
        P20UploadPage(
            client: client,
            session: session,
            source: '/unused.mp4',
            asset: false,
            list: P20MediaList.daily,
            framing: const FanFraming()),
        scale: 2));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Prepare and upload'), 200);
    expect(find.text('Prepare and upload').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
