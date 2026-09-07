import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/device_error_message.dart';

void main() {
  test('connection refused becomes a device setup instruction', () {
    final error = SocketException(
      'Connection refused',
      osError: const OSError('Connection refused', 111),
    );

    expect(friendlyDeviceConnectionError(error), contains('设备已开机'));
    expect(friendlyDeviceConnectionError(error), isNot(contains('Socket')));
  });

  test('timeout becomes a nearby Wi-Fi instruction', () {
    final error = SocketException(
      'Connection timed out',
      osError: const OSError('Connection timed out', 110),
    );

    expect(friendlyDeviceConnectionError(error), contains('连接超时'));
  });
}
