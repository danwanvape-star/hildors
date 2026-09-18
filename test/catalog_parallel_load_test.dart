import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_page.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_repository.dart';

void main() {
  testWidgets('catalog starts layout request without waiting for content', (tester) async {
    final content = Completer<List<RemoteCatalogPackage>>();
    var layoutStarted = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: RemoteCatalogPage(
      load: () => content.future,
      loadLayout: () async { layoutStarted = true; throw Exception('offline layout'); },
    ))));
    expect(layoutStarted, isTrue);
    content.complete([]);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
