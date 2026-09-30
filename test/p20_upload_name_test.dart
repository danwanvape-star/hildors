import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_upload_name.dart';

void main() {
  test('paired device names fit 12 bytes including extension', () {
    final random = Random(42);
    for (var i = 0; i < 1000; i++) {
      final base = createP20UploadBaseName(random: random);
      expect(RegExp(r'^[0-9a-f]{8}$').hasMatch(base), isTrue);
      for (final extension in ['.mp3', '.mp4']) {
        expect(utf8.encode(base + extension).length, 12);
      }
    }
  });
}
