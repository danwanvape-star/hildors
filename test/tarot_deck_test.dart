import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/interaction/tarot/tarot_deck.dart';

void main() {
  test('major arcana contains 22 cards', () {
    expect(majorArcanaNames, hasLength(22));
  });

  test('maps upright card to a stable device video filename', () {
    final result = createTarotResult(0, reversed: false);
    expect(result.title, '愚者 · 正位');
    expect(result.deviceVideo, 'tarot_00.mp4');
  });

  test('upright and reversed meanings share one device video', () {
    final reversed = createTarotResult(21, reversed: true);
    final upright = createTarotResult(21, reversed: false);
    expect(reversed.title, '世界 · 逆位');
    expect(reversed.deviceVideo, 'tarot_21.mp4');
    expect(reversed.deviceVideo, upright.deviceVideo);
  });
  test('three-card spread never repeats a card', () {
    final results = drawTarotSpread(Random(42), 3);
    expect(results, hasLength(3));
    expect(results.map((card) => card.number).toSet(), hasLength(3));
    for (final result in results) {
      expect(result.deviceVideo, matches(RegExp(r'^tarot_\d{2}\.mp4$')));
    }
  });

  test('spread rejects an invalid card count', () {
    expect(() => drawTarotSpread(Random(1), 0), throwsRangeError);
    expect(() => drawTarotSpread(Random(1), 23), throwsRangeError);
  });
}
