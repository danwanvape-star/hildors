import '../../localization/localization.dart';
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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hub_outlined, color: colors.primary),
                SizedBox(width: 8),
                Expanded(child: Text(context.l10n.controlsStatus, style: Theme.of(context).textTheme.titleLarge)),
              ],
            ),
            SizedBox(height: 16),
            _StatusRow(
              icon: Icons.wifi,
              title: context.l10n.controlsLan,
              value: _connectionLabel(context),
              active: connection == DeviceConnectionState.connected,
            ),
            Divider(height: 24),
            _StatusRow(
              icon: Icons.play_circle_outline,
              title: context.l10n.controlsMode,
              value: _modeLabel(context),
              active: runtime.mode != P20OperatingMode.unknown,
            ),
            Divider(height: 24),
            _StatusRow(
              icon: Icons.speaker_outlined,
              title: context.l10n.controlsAudioSource,
              value: _bluetoothLabel(context),
              active:
                  runtime.bluetooth.state == BluetoothAudioState.connected ||
                      runtime.bluetooth.state == BluetoothAudioState.playing,
            ),
            Divider(height: 24),
            _BatteryRow(battery: runtime.battery),
            if (runtime.mode == P20OperatingMode.unknown) ...[
              SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.l10n.controlsProtocolNote,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _connectionLabel(BuildContext context) => switch (connection) {
        DeviceConnectionState.disconnected => context.l10n.controlsDisconnected,
        DeviceConnectionState.connecting => context.l10n.controlsConnecting,
        DeviceConnectionState.reconnecting => context.l10n.controlsReconnecting,
        DeviceConnectionState.connected => context.l10n.controlsConnected,
      };

  String _modeLabel(BuildContext context) => switch (runtime.mode) {
        P20OperatingMode.unknown => context.l10n.controlsProtocol,
        P20OperatingMode.localPlayback => context.l10n.controlsLocalPlayback,
        P20OperatingMode.bluetoothWaiting => context.l10n.controlsBluetoothWaiting,
        P20OperatingMode.bluetoothAudio => context.l10n.controlsBluetoothAudio,
      };

  String _bluetoothLabel(BuildContext context) {
    final name = runtime.bluetooth.sourceName;
    return switch (runtime.bluetooth.state) {
      BluetoothAudioState.unavailable => context.l10n.controlsProtocol,
      BluetoothAudioState.waiting => context.l10n.controlsWaitingSource,
      BluetoothAudioState.connecting => context.l10n.controlsConnecting,
      BluetoothAudioState.connected => name ?? context.l10n.controlsConnected,
      BluetoothAudioState.playing => name == null ? context.l10n.controlsAudioPlaying : context.l10n.controlsNamedPlaying(name),
      BluetoothAudioState.paused => name == null ? context.l10n.controlsAudioPaused : context.l10n.controlsNamedPaused(name),
      BluetoothAudioState.disconnected => context.l10n.controlsWasDisconnected,
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
        ? context.l10n.controlsProtocol
        : battery.chargingState == BatteryChargingState.full
            ? context.l10n.controlsBatteryFull
            : battery.isCharging
                ? context.l10n.controlsCharging(percent)
                : '$percent%';
    return Row(
      children: [
        Icon(icon, color: percent == null ? colors.onSurfaceVariant : color),
        SizedBox(width: 12),
        Expanded(child: Text(context.l10n.controlsBattery)),
        Expanded(child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
        )),
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
        SizedBox(width: 12),
        Expanded(child: Text(title)),
        Expanded(child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active
                ? colors.primaryContainer
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(value),
        )),
      ],
    );
  }
}
