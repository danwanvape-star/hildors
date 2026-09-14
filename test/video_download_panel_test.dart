import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/verified_video_download.dart';
import 'package:hildors_cockpit/src/features/community/video_download_controller.dart';
import 'package:hildors_cockpit/src/features/community/video_download_panel.dart';

void main() {
  testWidgets('download panel gates access and does not expose auth errors',
      (tester) async {
    final controller = VideoDownloadController(
        VerifiedVideoDownload(
            Uri.parse('https://example.test'), Directory.systemTemp),
        packageId: 'p',
        clipId: 'c');
    addTearDown(controller.dispose);
    var calls = 0;
    Future<String?> auth() async {
      calls++;
      return null;
    }

    Widget page(bool enabled) => MaterialApp(
        home: Scaffold(
            body: VideoDownloadPanel(
                controller: controller,
                getSessionToken: auth,
                enabled: enabled)));
    await tester.pumpWidget(page(false));
    expect(find.text('下载暂未开放'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(calls, 0);
    await tester.pumpWidget(page(true));
    await tester.tap(find.text('登录后下载'));
    await tester.pumpAndSettle();
    expect(find.text('请先登录后下载'), findsOneWidget);
    expect(controller.status, VideoDownloadStatus.idle);
    expect(calls, 1);
  });
}
