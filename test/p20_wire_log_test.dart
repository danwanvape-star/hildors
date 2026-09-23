import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_wire_log.dart';

void main() {
  test('preserves raw chunks without parsing, omits media and bounds storage',
      () {
    final log = P20WireLog();
    log.record('RX', [0x55, 0, 0]);
    log.record('RX', [0, 6, 0x31, 1, 0, 0, 0, 2, 0x3a, 0x5a]);
    expect(log.text, contains('55 00 00'));
    expect(log.text, contains('00 06 31 01 00 00 00 02 3a 5a'));
    log.record('TX', [0xde, 0xad, 0xbe, 0xef], media: true);
    expect(log.text, contains('[media omitted]'));
    expect(log.text, isNot(contains('de ad be ef')));
    for (var i = 0; i < 500; i++) {
      log.record('RX', List.filled(100, 1));
    }
    expect(log.text.length, lessThan(66000));
  });
}
