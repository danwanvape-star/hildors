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
      required String portfolioUrl,
      required String agreementVersion,
      required List<String> skillTags,
      required String marketRegion}) async {
    applications++;
    if (request != null) await request!.future;
    await super.submitApplication(
        displayName: displayName,
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
      find.byType(TextField).at(1), 'https://portfolio.example');
  await tester.tap(find.byType(Checkbox).first);
  await tester.scrollUntilVisible(find.text('我同意创作者规则、保密要求和禁止私下交易条款'), 200,
      scrollable: find.byType(Scrollable).first);
  await tester.tap(find.text('我同意创作者规则、保密要求和禁止私下交易条款'));
  await tester.pump();
  await tester.scrollUntilVisible(find.text('提交创作者申请'), 150,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

Future<void> _payout(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('creator-tax-form')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('中国大陆税务资料').last);
  await tester.pumpAndSettle();
  await tester.enterText(
      find.byKey(const Key('creator-payout-reference')), 'provider-token');
  await tester.ensureVisible(find.text('提交收款账户审核'));
  await tester.pumpAndSettle();
}

void main() {
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

  testWidgets('payout suppresses duplicates and retains account and tax choice',
      (tester) async {
    final profiles = _Profiles(_certified)..request = Completer<void>();
    await _open(tester, profiles);
    await _payout(tester);
    final submit =
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!;
    submit();
    submit();
    await tester.pump();
    expect(profiles.payouts, 1);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    profiles.request!.completeError(StateError('private token failure'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('result could not be confirmed'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'provider-token');
    expect(find.text('中国大陆税务资料'), findsOneWidget);
    expect(find.text('结算币种：CNY'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);
    expect(profiles.profile!.payoutAccountStatus, '待提交');
  });

  testWidgets('leaving during payout submission handles a late failure',
      (tester) async {
    final profiles = _Profiles(_certified)..request = Completer<void>();
    await _open(tester, profiles);
    await _payout(tester);
    await tester.tap(find.text('提交收款账户审核'));
    await tester.pumpWidget(const SizedBox());
    profiles.request!.completeError(StateError('late failure'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh advances review gates only after repository approval',
      (tester) async {
    final profiles = _Profiles();
    await profiles.submitApplication(
        displayName: 'Studio',
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
    expect(find.text('设置创作者收款账户'), findsOneWidget);
    await _payout(tester);
    await tester.tap(find.text('提交收款账户审核'));
    await tester.pumpAndSettle();
    expect(find.text('收款账户与税务资料审核中'), findsOneWidget);
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(find.byType(CreatorTaskBoardPage), findsNothing);
    await profiles.approvePayoutAccount();
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(find.byType(CreatorTaskBoardPage), findsOneWidget);
    expect(profiles.applications, 1);
    expect(profiles.payouts, 1);
  });
}
