import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';
import 'package:hildors_cockpit/src/features/customization/custom_plans_page.dart';
import 'package:hildors_cockpit/src/features/customization/cloud_business_intake.dart';

class Service extends CloudBusinessIntake {
  Map<String, dynamic>? submitted;
  @override
  Future<CloudBusinessResponse> contentRequest(String method, String path,
          {Map<String, dynamic>? document,
          String? filePath,
          String? contentType,
          int? ifMatch}) async =>
      const CloudBusinessResponse(200, {
        'items': [
          {
            'id': 'custom-10s',
            'version': 2,
            'durationSeconds': 10,
            'usdBaseCents': 1999,
            'description': {'en': 'Private video', 'zh': '私密视频'},
            'audio': {'markupPercent': 20, 'totalUsdCents': 2399}
          }
        ]
      });
  @override
  Future<Map<String, dynamic>> orderRequest(String method, String path,
      {Map<String, dynamic>? document,
      Uint8List? bytes,
      String? contentType}) async {
    if (method == 'POST') {
      submitted = document;
      return {'id': 'order-1'};
    }
    return {'items': []};
  }
}

void main() {
  testWidgets(
      'supplemented scope returns to review using current order version',
      (tester) async {
    final service = SupplementService();
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CustomPlansPage(service: service)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Private robot'));
    await tester.pumpAndSettle();
    expect(find.text('Animation started.'), findsOneWidget);
    await tester.tap(find.text('Update requirements and resubmit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Turn left slowly');
    await tester.tap(find
        .widgetWithText(FilledButton, 'Update requirements and resubmit')
        .last);
    await tester.pumpAndSettle();
    expect(service.submitted, {
      'version': 3,
      'action': 'resubmit',
      'requirements': 'Turn left slowly'
    });
    expect(find.text('Requirements under review'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final audio in [false, true]) {
    testWidgets('audio choice submits server-priced variant: $audio',
        (tester) async {
      final service = Service();
      await tester.pumpWidget(MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CustomPlansPage(service: service)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send requirements for review'));
      await tester.pumpAndSettle();
      if (audio) {
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining(audio ? '23.99' : '19.99'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), 'Robot');
      await tester.enterText(find.byType(TextField).at(1), 'A simple turn');
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(service.submitted?['audioMode'], audio ? 'matched' : 'none');
      expect(service.submitted?['planVersion'], 2);
      expect(service.submitted?.containsKey('totalUsdCents'), false);
      expect(tester.takeException(), isNull);
    });
  }
}

class SupplementService extends Service {
  final order = <String, dynamic>{
    'id': 'order-1',
    'version': 3,
    'status': 'needs_info',
    'requirements': 'Old request',
    'characterName': 'Private robot',
    'productionUpdates': [
      {
        'text': {'en': 'Animation started.', 'zh': '已开始制作动画。'},
        'at': '2026-09-19T01:00:00Z'
      }
    ],
    'planSnapshot': {'audioMode': 'none'}
  };
  @override
  Future<Map<String, dynamic>> orderRequest(String method, String path,
          {Map<String, dynamic>? document,
          Uint8List? bytes,
          String? contentType}) async =>
      path.endsWith('customization-orders')
          ? {
              'items': [order]
            }
          : order;
  @override
  Future<CloudBusinessResponse> contentRequest(String method, String path,
      {Map<String, dynamic>? document,
      String? filePath,
      String? contentType,
      int? ifMatch}) async {
    if (method == 'POST') {
      submitted = document;
      order['status'] = 'free_review';
      order['version'] = 4;
      return CloudBusinessResponse(200, order);
    }
    return super.contentRequest(method, path);
  }
}
