import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/config/launch_config.dart';
import 'package:hildors_cockpit/src/localization/localization.dart';
import 'package:hildors_cockpit/src/features/customization/custom_plans_page.dart';
import 'package:hildors_cockpit/src/features/customization/cloud_business_intake.dart';
import 'package:hildors_cockpit/src/features/customization/custom_store_billing.dart';

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
      'free release links to the official website without price or request controls',
      (tester) async {
    expect(LaunchConfig.usFree, isTrue);
    final calls = <MethodCall>[];
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));

    await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CustomPlansPage(service: Service())));
    await tester.pumpAndSettle();

    expect(find.text('Visit the Hildors website'), findsOneWidget);
    expect(find.text('hildors.com'), findsOneWidget);
    expect(find.textContaining('19.99'), findsNothing);
    expect(find.text('Send requirements for review'), findsNothing);

    await tester.tap(find.text('Visit the Hildors website'));
    await tester.pump();
    expect(calls, hasLength(1));
    expect(calls.single.method, 'launch');
    expect(calls.single.arguments['url'], 'https://www.hildors.com/');
    expect(calls.single.arguments['useSafariVC'], isFalse);
    expect(calls.single.arguments['useWebView'], isFalse);
  }, skip: !LaunchConfig.usFree);

  testWidgets('free release hides payment controls on existing quoted orders',
      (tester) async {
    expect(LaunchConfig.usFree, isTrue);
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CustomPlansPage(
            service: QuotedService(), billing: AvailableBilling())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quoted robot'));
    await tester.pumpAndSettle();

    expect(find.text(r'Pay $19.99'), findsNothing);
    expect(find.text('Check unfinished purchases'), findsNothing);
    expect(find.text('I accept this confirmed scope and its terms.'),
        findsNothing);
  }, skip: !LaunchConfig.usFree);

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

  if (!LaunchConfig.usFree) {
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

class QuotedService extends Service {
  final order = <String, dynamic>{
    'id': 'quoted-1',
    'version': 1,
    'status': 'quoted',
    'characterName': 'Quoted robot',
    'revisionCount': 0,
    'planSnapshot': {
      'audioMode': 'none',
      'googleProductId': 'custom-video-10s'
    },
    'offer': {
      'version': 1,
      'terms': {
        'maxRevisions': 1,
        'deliveryContent': 'One video',
        'deliveryPeriod': 'After purchase',
        'revisionScope': 'One revision',
        'usageRights': 'Personal display'
      }
    }
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
}

class AvailableBilling implements CustomStoreBilling {
  @override
  String get platform => 'google';
  @override
  bool get testMode => false;
  @override
  Future<CustomStoreOffer?> product(String productId) async =>
      CustomStoreOffer(productId: productId, localizedPrice: r'$19.99');
  @override
  Future<String?> purchase(CustomStoreOffer offer, String orderId) async =>
      'proof';
  @override
  Future<List<String>> restore(String productId, String orderId) async =>
      ['proof'];
}
