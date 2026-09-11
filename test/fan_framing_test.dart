import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/video/fan_framing_page.dart';

void main() {
  test('完整展示让横竖视频四角都处于圆内', () {
    for (final aspect in [1.0, 9 / 16, 16 / 9, 0.1, 10.0]) {
      final scale = FanFraming.fullScale(aspect);
      final w = aspect >= 1 ? 1.0 : aspect;
      final h = aspect >= 1 ? 1 / aspect : 1.0;
      expect(math.sqrt(w * w + h * h) * scale, closeTo(1, 0.00001));
    }
  });
  test('取景参数保存格式可以还原', () {
    const frame = FanFraming(scale: 1.8, x: 0.2, y: -0.1);
    final restored = FanFraming.fromJson(frame.toJson());
    expect(restored.scale, frame.scale);
    expect(restored.x, frame.x);
    expect(restored.y, frame.y);
    expect(frame.toJson()['mask'], 'circle');
  });
}
