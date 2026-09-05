import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/device_runtime_state.dart';

void main() {
  test('uses 20 percent as low-battery threshold', () {
    expect(const DeviceBatteryState(percent: 21).isLow, isFalse);
    expect(const DeviceBatteryState(percent: 20).isLow, isTrue);
  });

  test('uses 10 percent as critical-battery threshold', () {
    expect(const DeviceBatteryState(percent: 11).isCritical, isFalse);
    expect(const DeviceBatteryState(percent: 10).isCritical, isTrue);
  });

  test('tracks charging separately from battery percentage', () {
    const battery = DeviceBatteryState(
      percent: 45,
      chargingState: BatteryChargingState.charging,
    );
    expect(battery.isCharging, isTrue);
    expect(battery.isLow, isFalse);
  });
}
