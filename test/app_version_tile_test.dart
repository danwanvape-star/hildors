import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/profile/app_version_tile.dart';
void main() {
  testWidgets('version is read from installed app metadata', (tester) async {
    const channel = MethodChannel('hildors/app_info');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'version');
      return '0.1.84 (85)';
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AppVersionTile())));
    await tester.pumpAndSettle();
    expect(find.text('0.1.84 (85)'), findsOneWidget);
  });
}
