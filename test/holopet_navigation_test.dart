import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/experience/experience_pack_manifest.dart';
import 'package:hildors_cockpit/src/experience/projection_service.dart';
import 'package:hildors_cockpit/src/features/explore/explore_page.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';
import 'package:hildors_cockpit/src/features/customization/customization_page.dart';

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
  testWidgets('discovery keeps customization entries above navigation, originals move to collection',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: ExplorePage(projection: _OfflineProjection()),
      bottomNavigationBar: const SizedBox(height: 88),
    )));
    await tester.pumpAndSettle();
    expect(find.text('原创角色馆'), findsNothing);
    for (final title in ['专属定制', '角色许愿', '创作者中心']) {
      expect(find.text(title).hitTestable(), findsOneWidget);
      expect(tester.getBottomLeft(find.text(title)).dy, lessThan(756));
    }
    final primary =
        find.ancestor(of: find.text('专属定制'), matching: find.byType(InkWell));
    final secondary =
        find.ancestor(of: find.text('角色许愿'), matching: find.byType(InkWell));
    expect(tester.getSize(primary).height,
        greaterThan(tester.getSize(secondary).height * 2));
    expect(tester.takeException(), isNull);
  });

  for (final entry in [
    ('专属定制', CharacterSourcePage),
    ('角色许愿', IpWishPage),
    ('创作者中心', CreatorHubPage),
  ]) {
    testWidgets('discovery opens ${entry.$1} directly on a narrow screen',
        (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: ExplorePage(projection: _OfflineProjection()),
      ));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(entry.$1), 220,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(entry.$1));
      // Finish the route animation without waiting for platform-backed storage.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(entry.$2), findsOneWidget);
      expect(find.byType(CustomizationPage), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('hides undeveloped companion and pet entries', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ExplorePage(projection: _OfflineProjection()),
    ));

    expect(find.text('HOLOPET'), findsNothing);
    expect(find.text('养成系宠物'), findsNothing);
    expect(find.text('角色陪伴'), findsNothing);
    expect(find.text('角色互动'), findsNothing);
    expect(find.text('派对玩法'), findsNothing);
    expect(find.text('Holo Roulette'), findsNothing);
  });
}
