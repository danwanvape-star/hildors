import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';
import 'package:hildors_cockpit/src/features/customization/creator_profile_repository.dart';
import 'package:hildors_cockpit/src/features/customization/customization_order_repository.dart';

class _Profiles extends MemoryCreatorProfileRepository {
  _Profiles([super.profile]);
  Completer<void>? request;
  int applications = 0;
  int payouts = 0;

  @override
  Future<void> submitApplication(
      {required String displayName,
      String email = '',
      required String portfolioUrl,
      required String agreementVersion,
      required List<String> skillTags,
      required String marketRegion}) async {
    applications++;
    if (request != null) await request!.future;
    await super.submitApplication(
        displayName: displayName,
        email: email,
        portfolioUrl: portfolioUrl,
        agreementVersion: agreementVersion,
        skillTags: skillTags,
        marketRegion: marketRegion);
  }

  @override
  Future<void> submitPayoutAccount(
      {required String payoutAccountReference,
      required String taxFormType}) async {
    payouts++;
    if (request != null) await request!.future;
    await super.submitPayoutAccount(
        payoutAccountReference: payoutAccountReference,
        taxFormType: taxFormType);
  }
}

const _certified = CreatorProfile(
    displayName: 'Studio',
    portfolioUrl: 'https://portfolio.example',
    status: '已认证',
    agreementVersion: 'creator-marketplace-v1',
    submittedAt: '2026-09-10',
    marketRegion: 'cn_mainland',
    skillTags: ['待机动作']);

Future<void> _open(WidgetTester tester, _Profiles profiles) async {
  await tester.pumpWidget(MaterialApp(
      home: CreatorHubPage(
          profileRepository: profiles,
          orderRepository: MemoryCustomizationOrderRepository())));
  await tester.pumpAndSettle();
}

Future<void> _application(WidgetTester tester) async {
  await tester.tap(find.text('待机动作'));
  await tester.tap(find.byKey(const Key('creator-market-region')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('中国大陆').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).at(0), 'Studio');
  await tester.enterText(
      find.byKey(const Key('creator-email')), 'studio@example.test');
  await tester.enterText(
      find.byType(TextField).at(2), 'https://portfolio.example');
  await tester.scrollUntilVisible(find.text('我已年满 18 岁'), 180,
      scrollable: find.byType(Scrollable).first);
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
  await tester.pumpAndSettle();
  await tester.tap(find.text('我已年满 18 岁'));
  await tester.scrollUntilVisible(find.text('我同意创作者规则、保密要求和禁止私下交易条款'), 200,
      scrollable: find.byType(Scrollable).first);
  await tester.tap(find.text('我同意创作者规则、保密要求和禁止私下交易条款'));
  await tester.pump();
  await tester.scrollUntilVisible(find.text('提交创作者申请'), 150,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('本地申请会自动补交到云端后才显示审核中', (tester) async {
    final profiles = _Profiles();
    await profiles.submitApplication(
        displayName: 'Studio',
        email: 'studio@example.test',
        portfolioUrl: 'https://portfolio.example',
        agreementVersion: 'creator-marketplace-v1',
        skillTags: ['待机动作'],
        marketRegion: 'cn_mainland');
    var loads = 0, submits = 0;
    await tester.pumpWidget(MaterialApp(
        home: CreatorHubPage(
      profileRepository: profiles,
      cloudProfileLoader: () async => ++loads == 1
          ? null
          : {'status': 'pending', 'updatedAt': '2026-09-16'},
      cloudProfileSubmitter: (
          {required displayName,
          required email,
          required portfolioUrl,
          required agreementVersion,
          required skillTags,
          required marketRegion}) async {
        submits++;
        return true;
      },
    )));
    await tester.pumpAndSettle();

    expect(submits, 1);
    expect(loads, 2);
    expect(find.text('创作者申请审核中'), findsOneWidget);
    expect(find.text('申请尚未同步到云端'), findsNothing);
  });

  testWidgets('云端失败时明确显示待同步而非审核中', (tester) async {
    final profiles = _Profiles();
    await profiles.submitApplication(
        displayName: 'Studio',
        email: 'studio@example.test',
        portfolioUrl: 'https://portfolio.example',
        agreementVersion: 'creator-marketplace-v1',
        skillTags: ['待机动作'],
        marketRegion: 'cn_mainland');
    await tester.pumpWidget(MaterialApp(
        home: CreatorHubPage(
      profileRepository: profiles,
      cloudProfileLoader: () async => null,
      cloudProfileSubmitter: (
              {required displayName,
              required email,
              required portfolioUrl,
              required agreementVersion,
              required skillTags,
              required marketRegion}) async =>
          false,
    )));
    await tester.pumpAndSettle();

    expect(find.text('申请尚未同步到云端'), findsOneWidget);
    expect(find.text('重新同步申请'), findsOneWidget);
    expect(find.text('创作者申请审核中'), findsNothing);
  });

  testWidgets('application suppresses duplicate calls and retains failed draft',
      (tester) async {
    final profiles = _Profiles()..request = Completer<void>();
    await _open(tester, profiles);
    await _application(tester);
    final submit =
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!;
    submit();
    submit();
    await tester.pump();
    expect(profiles.applications, 1);
    expect(find.text('Submitting…'), findsOneWidget);
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == 'Refresh',
            ))
            .onPressed,
        isNull);
    profiles.request!.completeError(StateError('private backend details'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('result could not be confirmed'), findsOneWidget);
    expect(find.textContaining('private backend'), findsNothing);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);
    await tester.drag(find.byType(ListView), const Offset(0, 1200));
    await tester.pumpAndSettle();
    expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Studio');
    expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        'https://portfolio.example');
    expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, '待机动作'))
            .selected,
        isTrue);
    expect(profiles.profile, isNull);
  });

  testWidgets('certified creator enters task board without payout binding',
      (tester) async {
    final profiles = _Profiles(_certified);
    await _open(tester, profiles);
    expect(find.byType(CreatorTaskBoardPage), findsOneWidget);
    expect(find.text('设置创作者收款账户'), findsNothing);
    expect(profiles.payouts, 0);
  });

  testWidgets('refresh advances review gates only after repository approval',
      (tester) async {
    final profiles = _Profiles();
    await profiles.submitApplication(
        displayName: 'Studio',
        email: 'studio@example.test',
        portfolioUrl: 'https://portfolio.example',
        agreementVersion: 'creator-marketplace-v1',
        skillTags: ['待机动作'],
        marketRegion: 'cn_mainland');
    await _open(tester, profiles);
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(find.text('创作者申请审核中'), findsOneWidget);
    await profiles.approveApplication();
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(find.byType(CreatorTaskBoardPage), findsOneWidget);
    expect(profiles.applications, 1);
    expect(profiles.payouts, 0);
  });
}
