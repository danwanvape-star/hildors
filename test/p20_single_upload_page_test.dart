import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/device/p20_device_profile.dart';
import 'package:hildors_cockpit/src/device/p20_command_session.dart';
import 'package:hildors_cockpit/src/features/video/p20_upload_page.dart';
import 'package:hildors_cockpit/src/features/video/p20_media_upload_flow.dart';
import 'package:hildors_cockpit/src/features/video/fan_framing_page.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';

class SingleClient extends P20DeviceClient {
  int epoch = 1;
  int uploads = 0;
  @override
  bool get isConnected => true;
  @override
  int get generation => epoch;
  @override
  P20DeviceProfile get profile =>
      const P20DeviceProfile.forKind(P20DeviceKind.single);
  @override
  Future<void> uploadFile(File file, int id, List<int> name,
      {void Function(int, int)? onProgress}) async {
    uploads++;
  }
}

void main() {
  test('destination rejects upload prepared for an older device', () async {
    final client = SingleClient();
    final session = P20CommandSession(client);
    final destination = P20DeviceDestination(client, session, (_, __) {});
    client.epoch++;
    await expectLater(
        destination.upload(File('x'), 0, 'x.bin'), throwsStateError);
    expect(client.uploads, 0);
    await client.dispose();
    await session.dispose();
  });
  testWidgets('verified single device exposes upload action', (tester) async {
    final client = SingleClient();
    final session = P20CommandSession(client);
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: P20UploadPage(
            client: client,
            session: session,
            source: 'source.mp4',
            asset: false,
            list: P20MediaList.daily,
            framing: const FanFraming())));
    expect(
        find.text(
            'Video upload for this device is awaiting hardware validation.'),
        findsNothing);
    expect(
        tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
        isNotNull);
    await tester.pumpWidget(const SizedBox());
    await client.dispose();
    await session.dispose();
  });
}
