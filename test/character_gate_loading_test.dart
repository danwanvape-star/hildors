import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_entitlement_repository.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';
import 'package:hildors_cockpit/src/features/customization/creator_profile_repository.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';

const _order = CustomizationOrder(
  id: 'loading-check',
  characterName: '恢复后的角色',
  sourceType: '原创角色',
  status: '免费预审中',
  assignedCreatorId: 'local-certified-creator',
);

class _Orders extends MemoryCustomizationOrderRepository {
  _Orders() : super(initialOrders: const [_order]);
  Future<List<CustomizationOrder>> Function()? read;
  int reads = 0;

  @override
  Future<List<CustomizationOrder>> loadOrders() {
    reads++;
    return read?.call() ?? super.loadOrders();
  }
}

class _Collection extends MemoryCharacterEntitlementRepository {
  _Collection() : super(['celestial-mage']);
  Future<Set<String>> Function()? read;

  @override
  Future<Set<String>> loadClaimedCharacterIds() =>
      read?.call() ?? super.loadClaimedCharacterIds();
}

class _Profile extends MemoryCreatorProfileRepository {
  Future<CreatorProfile?> Function()? read;

  @override
  Future<CreatorProfile?> loadProfile() => read?.call() ?? super.loadProfile();
}

Future<void> _recover(
  WidgetTester tester,
  Widget page,
  VoidCallback fail,
  VoidCallback restore,
  String expected,
) async {
  await tester.pumpWidget(MaterialApp(home: page));
  expect(find.text('Loading content'), findsOneWidget);
  expect(find.text('当前没有待处理订单'), findsNothing);
  expect(find.text('暂无可申请的合规任务'), findsNothing);
  fail();
  await tester.pumpAndSettle();
  expect(find.text('Content could not be loaded'), findsOneWidget);
  expect(find.textContaining('private-storage-path'), findsNothing);
  expect(tester.takeException(), isNull);
  restore();
  await tester.tap(find.text('Try again'));
  await tester.pumpAndSettle();
  expect(find.text('Content could not be loaded'), findsNothing);
  expect(find.text(expected), findsOneWidget);
  expect(tester.takeException(), isNull);
}

void main() {
  for (final surface in ['tasks', 'operations', 'collection']) {
    testWidgets('$surface distinguishes loading, failure and successful retry',
        (tester) async {
      final repository = _Orders();
      final pending = Completer<List<CustomizationOrder>>();
      repository.read = () => pending.future;
      final Widget page = switch (surface) {
        'tasks' => CreatorTaskBoardPage(orderRepository: repository),
        'operations' => PlatformOperationsPage(repository: repository),
        _ => MyCharactersPage(
            repository: MemoryCharacterEntitlementRepository(),
            orderRepository: repository),
      };
      await _recover(
          tester,
          page,
          () => pending.completeError(StateError('private-storage-path')),
          () => repository.read = null,
          _order.characterName);
      expect(repository.reads, 2);
      expect((await repository.loadOrders()).single.status, _order.status);
    });
  }

  testWidgets(
      'free library retries entitlement lookup without claiming content',
      (tester) async {
    final repository = _Collection();
    final pending = Completer<Set<String>>();
    repository.read = () => pending.future;
    await _recover(
        tester,
        FreeOriginalCharactersPage(repository: repository),
        () => pending.completeError(StateError('private-storage-path')),
        () => repository.read = null,
        'Celestial Mage');
    expect(await repository.loadClaimedCharacterIds(), {'celestial-mage'});
  });

  testWidgets('creator profile can recover instead of spinning indefinitely',
      (tester) async {
    final repository = _Profile();
    final pending = Completer<CreatorProfile?>();
    repository.read = () => pending.future;
    await _recover(
        tester,
        CreatorHubPage(profileRepository: repository),
        () => pending.completeError(StateError('private-storage-path')),
        () => repository.read = null,
        '先完成创作者认证');
    expect(await repository.loadProfile(), isNull);
  });

  testWidgets('failed refresh hides stale operations and recovers on retry',
      (tester) async {
    final repository = _Orders();
    await tester.pumpWidget(
        MaterialApp(home: PlatformOperationsPage(repository: repository)));
    await tester.pumpAndSettle();
    expect(find.text(_order.characterName), findsOneWidget);
    repository.read = () => Future.error(StateError('private-storage-path'));
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(find.text(_order.characterName), findsNothing);
    expect(find.text('Content could not be loaded'), findsOneWidget);
    repository.read = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text(_order.characterName), findsOneWidget);
  });

  for (final fails in [false, true]) {
    testWidgets(
        'leaving a loading route ignores late ${fails ? 'failure' : 'success'}',
        (tester) async {
      final repository = _Orders();
      final pending = Completer<List<CustomizationOrder>>();
      repository.read = () => pending.future;
      await tester.pumpWidget(
          MaterialApp(home: CreatorTaskBoardPage(orderRepository: repository)));
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      if (fails) {
        pending.completeError(StateError('private-storage-path'));
      } else {
        pending.complete([_order]);
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'empty task filter can be cleared without another repository read',
      (tester) async {
    final repository = _Orders();
    await tester.pumpWidget(
        MaterialApp(home: CreatorTaskBoardPage(orderRepository: repository)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('In production'));
    await tester.tap(find.text('In production'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Clear filters'));
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text(_order.characterName), findsOneWidget);
    expect(repository.reads, 1);
  });
}
