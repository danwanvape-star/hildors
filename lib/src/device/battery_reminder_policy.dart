import 'device_runtime_state.dart';

enum BatteryReminder { none, low, critical }

class BatteryReminderPolicy {
  BatteryReminder _lastReminder = BatteryReminder.none;

  BatteryReminder evaluate(DeviceBatteryState battery) {
    final percent = battery.percent;
    if (percent == null || battery.isCharging) {
      _lastReminder = BatteryReminder.none;
      return BatteryReminder.none;
    }

    final current = battery.isCritical
        ? BatteryReminder.critical
        : battery.isLow
            ? BatteryReminder.low
            : BatteryReminder.none;

    if (current == BatteryReminder.none) {
      _lastReminder = BatteryReminder.none;
      return BatteryReminder.none;
    }
    if (current.index <= _lastReminder.index) return BatteryReminder.none;

    _lastReminder = current;
    return current;
  }

  void reset() => _lastReminder = BatteryReminder.none;
}
