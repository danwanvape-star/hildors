import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/reconnect_backoff.dart';

void main() {
  test('increases delay and caps at 30 seconds', () {
    final backoff = ReconnectBackoff();
    expect(
      List.generate(8, (_) => backoff.next().inSeconds),
      [1, 2, 4, 8, 15, 30, 30, 30],
    );
  });

  test('starts from first delay after reset', () {
    final backoff = ReconnectBackoff();
    backoff.next();
    backoff.next();
    backoff.reset();
    expect(backoff.next(), const Duration(seconds: 1));
  });
}
