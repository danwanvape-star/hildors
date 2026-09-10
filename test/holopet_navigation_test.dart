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
  testWidgets('removes HOLOPET entry and presents character companion',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ExplorePage(projection: _OfflineProjection()),
    ));

    expect(find.text('HOLOPET'), findsNothing);
    expect(find.text('养成系宠物'), findsNothing);
    expect(find.text('角色陪伴'), findsOneWidget);
    expect(find.text('角色互动'), findsOneWidget);
    expect(find.text('派对玩法'), findsNothing);
    expect(find.text('Holo Roulette'), findsNothing);
  });
}
