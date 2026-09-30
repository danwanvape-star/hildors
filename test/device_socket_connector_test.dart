import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/device_socket_connector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('hildors/device_wifi');
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));
  test('Android connector uses Wi-Fi bridge and preserves bytes', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((socket) {
      socket.listen((bytes) {
        socket.add(bytes);
        socket.close();
      });
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'open');
      expect(call.arguments, {'host': '192.168.4.1', 'port': 8900});
      return server.port;
    });
    final socket = await connectAndroidDeviceSocket('192.168.4.1', 8900);
    socket.add([0xaa, 0, 0, 0, 1, 4, 5, 0xa5]);
    expect(await socket.expand((bytes) => bytes).toList(),
        [0xaa, 0, 0, 0, 1, 4, 5, 0xa5]);
    socket.destroy();
    await server.close();
  });
  test('Wi-Fi failure does not silently fall back to cellular', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel,
            (_) async => throw PlatformException(code: 'wifi_socket_failed'));
    await expectLater(connectAndroidDeviceSocket('192.168.4.1', 8900),
        throwsA(isA<SocketException>()));
  });
}
