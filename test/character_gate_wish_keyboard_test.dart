import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/customization/character_gate_prototype_pages.dart';

void main() {
  testWidgets('wish keyboard advances then dismisses without submitting',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: IpWishPage()));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.ensureVisible(fields.first);
    await tester.enterText(fields.first, 'My world');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    final character = tester.widget<TextField>(fields.last);
    expect(character.focusNode!.hasFocus, isTrue);
    await tester.enterText(fields.last, 'Starlight');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(character.focusNode!.hasFocus, isFalse);
    expect(character.controller!.text, 'Starlight');
    expect(tester.widget<TextField>(fields.first).controller!.text, 'My world');
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
