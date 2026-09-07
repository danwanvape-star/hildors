import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/experience/experience_pack_manifest.dart';
import 'package:hildors_cockpit/src/experience/projection_service.dart';
import 'package:hildors_cockpit/src/features/explore/explore_page.dart';

class _OfflineProjection implements ProjectionService {
  @override
  bool get deviceConnected => false;

  @override
  Future<ExperiencePackStatus> inspectPack(
    ExperiencePackManifest manifest, {
    bool forceRefresh = false,
  }) async =>
      ExperiencePackStatus(
        deviceConnected: false,
        totalFiles: manifest.files.length,
        missingFiles: manifest.files.map((file) => file.path).toList(),
      );

  @override
  Future<ProjectionOutcome> present(ExperienceResult result) async =>
      ProjectionOutcome.phoneOnly;
}

void main() {
  testWidgets('opens the two-path HOLOPET hub from Explore', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ExplorePage(projection: _OfflineProjection()),
    ));

    expect(find.text('HOLOPET'), findsOneWidget);
    await tester.tap(find.text('HOLOPET'));
    await tester.pumpAndSettle();

    expect(find.text('领养全息宠物'), findsOneWidget);
    expect(find.text('定制我的宠物'), findsOneWidget);
  });
}
