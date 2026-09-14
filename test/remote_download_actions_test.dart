import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/remote_download_actions.dart';
import 'package:hildors_cockpit/src/features/community/verified_video_download.dart';

void main() {
  testWidgets('route-owned actions show sign-in guidance without download',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: RemoteDownloadActions(
                service: VerifiedVideoDownload(
                    Uri.parse('https://example.test'), Directory.systemTemp),
                packageId: 'p',
                clipId: 'c',
                getSessionToken: () async => null))));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('登录后可查看下载权限'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    await tester.tap(find.text('重新检查'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('登录后可查看下载权限'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
