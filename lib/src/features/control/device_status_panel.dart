import 'package:flutter/material.dart';

import '../../device/device_runtime_state.dart';
import '../../device/p20_device_client.dart';

class DeviceStatusPanel extends StatelessWidget {
  const DeviceStatusPanel({
    required this.connection,
    required this.runtime,
    super.key,
  });

  final DeviceConnectionState connection;
  final DeviceRuntimeState runtime;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hub_outlined, color: colors.primary),
                const SizedBox(width: 8),
                Text('设备状态', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            _StatusRow(
              icon: Icons.wifi,
              title: '局域网控制',
              value: _connectionLabel,
              active: connection == DeviceConnectionState.connected,
            ),
            const Divider(height: 24),
            _StatusRow(
              icon: Icons.play_circle_outline,
              title: '工作模式',
              value: _modeLabel,
              active: runtime.mode != P20OperatingMode.unknown,
            ),
            const Divider(height: 24),
            _StatusRow(
              icon: Icons.speaker_outlined,
              title: '蓝牙音源',
              value: _bluetoothLabel,
              active:
                  runtime.bluetooth.state == BluetoothAudioState.connected ||
                      runtime.bluetooth.state == BluetoothAudioState.playing,
            ),
            const Divider(height: 24),
            _BatteryRow(battery: runtime.battery),
            if (runtime.mode == P20OperatingMode.unknown) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '当前协议尚未提供工作模式和蓝牙状态。新版协议接入后，'
                  '这里将实时显示“本机播放”或“蓝牙音响”。',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get _connectionLabel => switch (connection) {
        DeviceConnectionState.disconnected => '未连接',
        DeviceConnectionState.connecting => '连接中…',
        DeviceConnectionState.reconnecting => '正在重连…',
        DeviceConnectionState.connected => '已连接',
      };

  String get _modeLabel => switch (runtime.mode) {
        P20OperatingMode.unknown => '等待新版协议',
        P20OperatingMode.localPlayback => '本机播放',
        P20OperatingMode.bluetoothWaiting => '蓝牙等待连接',
        P20OperatingMode.bluetoothAudio => '蓝牙音响',
      };

  String get _bluetoothLabel {
    final name = runtime.bluetooth.sourceName;
    return switch (runtime.bluetooth.state) {
      BluetoothAudioState.unavailable => '等待新版协议',
      BluetoothAudioState.waiting => '等待音源连接',
      BluetoothAudioState.connecting => '连接中…',
      BluetoothAudioState.connected => name ?? '已连接',
      BluetoothAudioState.playing => name == null ? '音频播放中' : '$name · 播放中',
      BluetoothAudioState.paused => name == null ? '音频已暂停' : '$name · 已暂停',
      BluetoothAudioState.disconnected => '已断开',
    };
  }
}

class _BatteryRow extends StatelessWidget {
  const _BatteryRow({required this.battery});

  final DeviceBatteryState battery;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final percent = battery.percent;
    final color = battery.isCritical
        ? colors.error
        : battery.isLow
            ? Colors.orange
            : colors.primary;
    final icon = battery.isCharging
        ? Icons.battery_charging_full
        : battery.isCritical
            ? Icons.battery_alert
            : Icons.battery_std;
    final label = percent == null
        ? '等待新版协议'
        : battery.chargingState == BatteryChargingState.full
            ? '已充满'
            : battery.isCharging
                ? '$percent% · 充电中'
                : '$percent%';
    return Row(
      children: [
        Icon(icon, color: percent == null ? colors.onSurfaceVariant : color),
        const SizedBox(width: 12),
        const Expanded(child: Text('设备电量')),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: percent == null
                ? colors.surfaceContainerHighest
                : color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(color: percent == null ? null : color),
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.active,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: active ? colors.primary : colors.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(child: Text(title)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active
                ? colors.primaryContainer
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(value),
        ),
      ],
    );
  }
}
