import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/cloud_orders_page.dart';

void main() {
  testWidgets('assigned creator sees requested revision instructions',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: CloudOrdersPage(
            creator: true,
            request: (method, path, {document, bytes, contentType}) async => {
                  'items': [
                    {
                      'id': 'one',
                      'version': 2,
                      'characterName': 'Nova',
                      'status': 'in_production',
                      'assignedCreatorId': 'creator',
                      'workflowHistory': [
                        {'note': '请放慢转身动作', 'actor': 'user', 'at': '2026-09-17'}
                      ]
                    }
                  ]
                })));
    await tester.pumpAndSettle();
    expect(find.textContaining('请放慢转身动作'), findsOneWidget);
  });
  testWidgets('owner accepts the current server quote with its version',
      (tester) async {
    Map<String, dynamic>? sent;
    await tester.pumpWidget(MaterialApp(home: CloudOrdersPage(
        request: (method, path, {document, bytes, contentType}) async {
      if (method == 'POST') {
        sent = document;
        return {};
      }
      return {
        'items': [
          {
            'id': 'one',
            'version': 7,
            'characterName': 'Nova',
            'status': 'quoted',
            'workflow': {
              'quoteAmount': 120,
              'currency': 'USD',
              'deliveryDays': 3
            }
          }
        ]
      };
    })));
    await tester.pumpAndSettle();
    expect(find.textContaining('120'), findsOneWidget);
    await tester.tap(find.text('接受报价'));
    await tester.pumpAndSettle();
    expect(sent, containsPair('version', 7));
    expect(sent, containsPair('action', 'accept_quote'));
  });
  testWidgets(
      'open applications show summary without private material controls',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: CloudOrdersPage(
            creator: true,
            request: (method, path, {document, bytes, contentType}) async => {
                  'items': [
                    {
                      'id': 'one',
                      'version': 1,
                      'characterName': 'Nova',
                      'status': 'approved_for_quote',
                      'dispatchMode': 'applications',
                      'dispatchState': 'open',
                      'requirements': 'idle pose'
                    }
                  ]
                })));
    await tester.pumpAndSettle();
    expect(find.text('申请任务'), findsOneWidget);
    expect(find.text('提交报价'), findsNothing);
    expect(find.text('idle pose'), findsOneWidget);
  });
}
