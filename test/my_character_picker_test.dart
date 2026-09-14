import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_entitlement_repository.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';
import 'package:hildors_cockpit/src/features/video/character_package_picker.dart';
import 'package:hildors_cockpit/src/features/video/character_video_package.dart';
import 'package:hildors_cockpit/src/features/video/pending_playlist_store.dart';
import 'package:hildors_cockpit/src/features/video/device_playlist_draft.dart';

void main() {
  for (final scenario in [(390.0, 1.0, 3), (320.0, 2.0, 2)]) {
    testWidgets('我的角色网格适配 $scenario', (tester) async {
      tester.view.physicalSize = Size(scenario.$1, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scenario.$2)),
              child: child!),
          home: CharacterPackagePicker(
              picking: false,
              repository: MemoryCharacterEntitlementRepository(
                  ['celestial-mage', 'neon-dancer']),
              orderRepository: MemoryCustomizationOrderRepository())));
      await tester.pumpAndSettle();
      final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
      expect(
          (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
              .crossAxisCount,
          scenario.$3);
      expect(find.text('我的收藏'), findsNothing);
      expect(find.text('加入播放列表'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('从我的角色选片后加入指定列表，保留原记录且不上传', (tester) async {
    DevicePlaylistKind? target;
    Map<String, PendingVideo>? saved;
    final package = officialVideoPackages.first;
    await tester.pumpWidget(MaterialApp(
        home: CharacterPackagePicker(
            picking: false,
            saveToPlaylist: (kind, entries) async {
              target = kind;
              saved = entries;
            },
            repository: MemoryCharacterEntitlementRepository([package.id]),
            orderRepository: MemoryCustomizationOrderRepository())));
    await tester.pumpAndSettle();
    await tester.tap(find.text(package.title));
    await tester.pumpAndSettle();
    await tester.tap(find.text('展示视频'));
    await tester.pump();
    await tester.tap(find.text('添加 1 个视频到待处理区'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('音乐联动'));
    await tester.pumpAndSettle();
    expect(
        saved!.keys,
        containsAll(
            [PackageVideoSelection(package, package.videos.first).key]));
    expect(target, DevicePlaylistKind.bluetooth);
    await tester.pump();
    expect(find.textContaining('尚未上传设备'), findsOneWidget);
  });
  testWidgets('未收藏时不展示公共 Demo，提供内容库入口', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: CharacterPackagePicker(
            repository: MemoryCharacterEntitlementRepository(),
            orderRepository: MemoryCustomizationOrderRepository())));
    await tester.pumpAndSettle();
    expect(find.text('还没有可选择的角色'), findsOneWidget);
    expect(find.text('浏览内容库'), findsOneWidget);
    expect(find.textContaining('HILDORS 全息展示'), findsNothing);
  });
  testWidgets('只展示收藏角色，包内无视频时不虚构文件', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: CharacterPackagePicker(
            repository:
                MemoryCharacterEntitlementRepository(['celestial-mage']),
            orderRepository: MemoryCustomizationOrderRepository())));
    await tester.pumpAndSettle();
    expect(find.text('星穹术士'), findsOneWidget);
    expect(find.text('霓虹舞者'), findsNothing);
    expect(find.textContaining('HILDORS 全息展示'), findsNothing);
    await tester.tap(find.text('星穹术士'));
    await tester.pumpAndSettle();
    expect(find.text('此角色暂未提供可用视频，待内容包交付后选择。'), findsOneWidget);
    final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '添加 0 个视频到待处理区'));
    expect(button.onPressed, isNull);
  });
  testWidgets('只有已交付定制角色可出现，待交付角色不出现', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: CharacterPackagePicker(
            repository: MemoryCharacterEntitlementRepository(),
            orderRepository:
                MemoryCustomizationOrderRepository(initialOrders: const [
              CustomizationOrder(
                  id: 'ready',
                  characterName: '已交付角色',
                  sourceType: '原创角色',
                  status: '已交付'),
              CustomizationOrder(
                  id: 'pending',
                  characterName: '制作中角色',
                  sourceType: '原创角色',
                  status: '制作中'),
            ]))));
    await tester.pumpAndSettle();
    expect(find.text('已交付角色'), findsOneWidget);
    expect(find.text('制作中角色'), findsNothing);
  });
}
