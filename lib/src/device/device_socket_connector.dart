import 'dart:io';
import 'package:flutter/services.dart';

Future<Socket> connectDeviceSocket(String host, int port) async {
  if (!Platform.isAndroid) {
    return Socket.connect(host, port, timeout: const Duration(seconds: 5));
  }
  return connectAndroidDeviceSocket(host, port);
}

Future<Socket> connectAndroidDeviceSocket(String host, int port) async {
  try {
    final localPort = await const MethodChannel('hildors/device_wifi')
        .invokeMethod<int>('open', {'host': host, 'port': port});
    if (localPort == null || localPort < 1 || localPort > 65535) {
      throw const SocketException('Invalid Wi-Fi socket');
    }
    return await Socket.connect(InternetAddress.loopbackIPv4, localPort,
        timeout: const Duration(seconds: 3));
  } on PlatformException catch (error) {
    throw SocketException('Device Wi-Fi connection failed: ${error.code}');
  }
}
