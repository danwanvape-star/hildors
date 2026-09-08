import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/experience/experience_pack_manifest.dart';
import 'package:hildors_cockpit/src/experience/projection_service.dart';
import 'package:hildors_cockpit/src/features/explore/explore_page.dart';
import 'package:hildors_cockpit/src/features/interaction/roulette/roulette_demo_player.dart';

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
  testWidgets('opens Holo Roulette from the social party section',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ExplorePage(projection: _OfflineProjection()),
    ));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Holo Roulette'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Holo Roulette'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('派对挑战轮盘'), findsOneWidget);
    expect(find.byType(RouletteDemoPlayer), findsOneWidget);
  });
}
