import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/video/p20_bin_encoder.dart';

// Independent, literal translation of the vendor's four quadrant table and
// byte-truncating interpolation. No production geometry helpers are reused.
Uint8List vendorFrame(Uint8List input) {
  final out = Uint8List(960 * 160 * 3);
  for (var i = 0; i < 960; i++) {
    for (var l = 0; l < 149; l++) {
      var degrees = i * 360.0 / 960;
      final radius = l + 0.5;
      double w, h;
      if (degrees <= 90) {
        final a = degrees * math.pi / 180;
        w = 149.5 + radius * math.sin(a);
        h = 149.5 + radius * math.cos(a);
      } else if (degrees <= 180) {
        degrees -= 90;
        final a = degrees * math.pi / 180;
        w = 149.5 + radius * math.cos(a);
        h = 149.5 - radius * math.sin(a);
      } else if (degrees <= 270) {
        degrees -= 180;
        final a = degrees * math.pi / 180;
        h = 149.5 - radius * math.cos(a);
        w = 149.5 - radius * math.sin(a);
      } else {
        degrees -= 270;
        final a = degrees * math.pi / 180;
        w = 149.5 - radius * math.cos(a);
        h = 149.5 + radius * math.sin(a);
      }
      w -= 1;
      h -= 1;
      final row = w.floor(), col = h.floor();
      int at(int r, int c, int ch) => input[(r * 298 + c) * 3 + ch];
      for (var ch = 0; ch < 3; ch++) {
        var value = at(row, col, ch);
        if (row <= 296 && col <= 296) {
          final top =
              (value + (at(row + 1, col, ch) - value) * (w - row)).toInt();
          final a = at(row, col + 1, ch);
          final bottom =
              (a + (at(row + 1, col + 1, ch) - a) * (w - row)).toInt();
          value = (top + (bottom - top) * (h - col)).toInt();
        }
        if ((l == 0 && i % 16 != 0) || (l >= 1 && l <= 7 && i % 8 > l)) {
          value = 0;
        }
        out[((959 - i) * 160 + 148 - l + 11) * 3 + ch] = value;
      }
    }
  }
  return out;
}

void main() {
  test('all mapped bytes agree with literal vendor geometry and interpolation',
      () {
    final random = math.Random(20260921);
    final input = Uint8List.fromList(
        List.generate(298 * 298 * 3, (_) => random.nextInt(256)));
    final expected = vendorFrame(input);
    final actual = P20PolarMapper().convert(input);
    var count = 0, maxDelta = 0;
    for (var n = 0; n < actual.length; n++) {
      if (actual[n] != expected[n]) count++;
      maxDelta = math.max(maxDelta, (actual[n] - expected[n]).abs());
    }
    expect(count, 0,
        reason: 'different bytes=$count maximum channel error=$maxDelta');
  });
  test('power limiter is cumulative across frames and new video resets it', () {
    final mapper = P20PolarMapper();
    mapper.convert(Uint8List(298 * 298 * 3)..fillRange(0, 298 * 298 * 3, 255));
    final expected = Float32List.fromList([128 / 255]).single;
    expect(mapper.brightness, expected);
    mapper.convert(Uint8List(298 * 298 * 3));
    expect(mapper.brightness, expected);
    expect(P20PolarMapper().brightness, 1);
  });
}
