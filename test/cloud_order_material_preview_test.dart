import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/cloud_orders_page.dart';

void main() {
  for (final creator in [false, true]) {
    testWidgets(
        'material preview loads immediately, retries and explicitly fetches original (creator: $creator)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final paths = <String>[];
      final pending = <Completer<Uint8List>>[];
      final png = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==');
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!),
        home: CloudOrdersPage(
          creator: creator,
          materialRequest: (path) {
            paths.add(path);
            final completer = Completer<Uint8List>();
            pending.add(completer);
            return completer.future;
          },
          request: (method, path, {document, bytes, contentType}) async => {
            'items': [
              {
                'id': 'one',
                'version': 1,
                'characterName': 'Nova',
                'status': 'delivered',
                'assignedCreatorId': 'creator',
                'materials': [
                  {'id': 'photo', 'name': 'photo.png'}
                ]
              }
            ]
          },
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('查看素材 photo.png'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final root =
          creator ? '/v1/me/creator-tasks' : '/v1/me/customization-orders';
      expect(paths, ['$root/one/materials/photo?variant=preview']);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('重试'), findsNothing);
      pending[0].completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(find.text('素材加载失败，请重试'), findsOneWidget);
      await tester.tap(find.text('重试'));
      await tester.pump();
      expect(paths.last, '$root/one/materials/photo?variant=preview');
      expect(paths.length, 2);
      pending[1].complete(png);
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('重试'), findsNothing);
      await tester.tap(find.text('查看原图'));
      await tester.pump();
      expect(paths, [
        '$root/one/materials/photo?variant=preview',
        '$root/one/materials/photo?variant=preview',
        '$root/one/materials/photo'
      ]);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending[2].completeError(Exception('offline original'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('重试'));
      await tester.pump();
      expect(paths.last, '$root/one/materials/photo');
      expect(paths.length, 4);
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      pending[3].complete(png);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
