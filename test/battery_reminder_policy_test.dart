import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/battery_reminder_policy.dart';
import 'package:hildors_cockpit/src/device/device_runtime_state.dart';

void main() {
  test('reminds only once at each severity in one discharge cycle', () {
    final policy = BatteryReminderPolicy();
    expect(
      policy.evaluate(const DeviceBatteryState(percent: 20)),
      BatteryReminder.low,
    );
    expect(
      policy.evaluate(const DeviceBatteryState(percent: 19)),
      BatteryReminder.none,
    );
    expect(
      policy.evaluate(const DeviceBatteryState(percent: 10)),
      BatteryReminder.critical,
    );
    expect(
      policy.evaluate(const DeviceBatteryState(percent: 9)),
      BatteryReminder.none,
    );
  });

  test('resets reminder after battery recovers', () {
    final policy = BatteryReminderPolicy();
    policy.evaluate(const DeviceBatteryState(percent: 20));
    policy.evaluate(const DeviceBatteryState(percent: 40));
    expect(
      policy.evaluate(const DeviceBatteryState(percent: 20)),
      BatteryReminder.low,
    );
  });

  test('does not remind while charging', () {
    final policy = BatteryReminderPolicy();
    expect(
      policy.evaluate(const DeviceBatteryState(
        percent: 8,
        chargingState: BatteryChargingState.charging,
      )),
      BatteryReminder.none,
    );
  });
}
