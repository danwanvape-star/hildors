enum P20OperatingMode {
  unknown,
  localPlayback,
  bluetoothWaiting,
  bluetoothAudio,
}

enum BluetoothAudioState {
  unavailable,
  waiting,
  connecting,
  connected,
  playing,
  paused,
  disconnected,
}

enum BluetoothDisconnectPolicy {
  resumePreviousLocalVideo,
  playFirstLocalVideo,
  remainOnWaitingVisual,
}

enum BatteryChargingState { unknown, unplugged, charging, full }

class DeviceBatteryState {
  const DeviceBatteryState({
    this.percent,
    this.chargingState = BatteryChargingState.unknown,
  });

  final int? percent;
  final BatteryChargingState chargingState;

  bool get isLow => percent != null && percent! <= 20;
  bool get isCritical => percent != null && percent! <= 10;
  bool get isCharging => chargingState == BatteryChargingState.charging;
}

class BluetoothSourceState {
  const BluetoothSourceState({
    this.state = BluetoothAudioState.unavailable,
    this.sourceName,
    this.volume,
    this.muted,
  });

  final BluetoothAudioState state;
  final String? sourceName;
  final int? volume;
  final bool? muted;
}

/// Combined runtime snapshot shown by the App. LAN control connectivity and
/// Bluetooth audio connectivity are intentionally represented separately.
class DeviceRuntimeState {
  const DeviceRuntimeState({
    this.mode = P20OperatingMode.unknown,
    this.bluetooth = const BluetoothSourceState(),
    this.battery = const DeviceBatteryState(),
    this.localVideoName,
    this.bluetoothVisualName,
    this.lastUpdatedAt,
  });

  final P20OperatingMode mode;
  final BluetoothSourceState bluetooth;
  final DeviceBatteryState battery;
  final String? localVideoName;
  final String? bluetoothVisualName;
  final DateTime? lastUpdatedAt;

  bool get isFresh =>
      lastUpdatedAt != null &&
      DateTime.now().difference(lastUpdatedAt!) < const Duration(seconds: 5);

  DeviceRuntimeState copyWith({
    P20OperatingMode? mode,
    BluetoothSourceState? bluetooth,
    DeviceBatteryState? battery,
    String? localVideoName,
    String? bluetoothVisualName,
    DateTime? lastUpdatedAt,
  }) {
    return DeviceRuntimeState(
      mode: mode ?? this.mode,
      bluetooth: bluetooth ?? this.bluetooth,
      battery: battery ?? this.battery,
      localVideoName: localVideoName ?? this.localVideoName,
      bluetoothVisualName: bluetoothVisualName ?? this.bluetoothVisualName,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}
