import 'package:flutter/widgets.dart';
import 'p20_device_client.dart';
import 'p20_command_session.dart';

/// Shares the single device socket with routes opened above the dashboard.
class DeviceAccess extends InheritedWidget {
  const DeviceAccess(
      {required this.client,
      required this.session,
      required super.child,
      super.key});
  final P20DeviceClient client;
  final P20CommandSession session;
  static DeviceAccess? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DeviceAccess>();
  @override
  bool updateShouldNotify(DeviceAccess oldWidget) =>
      client != oldWidget.client || session != oldWidget.session;
}
