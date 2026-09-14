import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_ui.dart';

class _LoadHarness extends StatefulWidget {
  const _LoadHarness({super.key});

  @override
  State<_LoadHarness> createState() => _LoadHarnessState();
}

class _LoadHarnessState extends State<_LoadHarness>
    with GateLoadState<_LoadHarness> {
  String? result;

  Future<void> read(Future<String> pending) => loadGateData(
        () => pending,
        (value) => result = value,
      );

  @override
  Widget build(BuildContext context) => Text(result ?? 'pending');
}

void main() {
  for (final oldFails in [false, true]) {
    testWidgets(
        'late ${oldFails ? 'failure' : 'success'} cannot overwrite a newer result',
        (tester) async {
      final key = GlobalKey<_LoadHarnessState>();
      await tester.pumpWidget(MaterialApp(home: _LoadHarness(key: key)));
      final old = Completer<String>();
      final latest = Completer<String>();
      final firstLoad = key.currentState!.read(old.future);
      final secondLoad = key.currentState!.read(latest.future);
      latest.complete('latest');
      await secondLoad;
      if (oldFails) {
        old.completeError(StateError('old request'));
      } else {
        old.complete('stale');
      }
      await firstLoad;
      await tester.pump();
      expect(find.text('latest'), findsOneWidget);
      expect(key.currentState!.gateLoadFailed, isFalse);
      expect(key.currentState!.gateLoading, isFalse);
    });
  }

  testWidgets('failed request keeps existing data until a retry succeeds',
      (tester) async {
    final key = GlobalKey<_LoadHarnessState>();
    await tester.pumpWidget(MaterialApp(home: _LoadHarness(key: key)));
    await key.currentState!.read(Future.value('saved'));
    await key.currentState!.read(Future.error(StateError('read failed')));
    expect(key.currentState!.result, 'saved');
    expect(key.currentState!.gateLoadFailed, isTrue);
    await key.currentState!.read(Future.value('refreshed'));
    expect(key.currentState!.result, 'refreshed');
    expect(key.currentState!.gateLoadFailed, isFalse);
  });

  testWidgets(
      'error panel supports narrow large-text layouts and Japanese copy',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var retries = 0;
    await tester.pumpWidget(MaterialApp(
      home: Localizations(
        locale: const Locale('ja'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: GateScaffold(
              body: GateLoadPanel(failed: true, onRetry: () => retries++)),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('コンテンツを読み込めませんでした'), findsOneWidget);
    await tester.ensureVisible(find.text('再読み込み'));
    await tester.tap(find.text('再読み込み'));
    expect(retries, 1);
    expect(tester.takeException(), isNull);
  });
}
