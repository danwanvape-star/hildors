import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/device/p20_v2_protocol.dart';
void main() {
  test('verified connection waits for device reply and avoids duplicate socket', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final client = P20DeviceClient(modernProtocol: true, verifyOnConnect: true);
    var connections = 0;
    server.listen((socket) { connections++; socket.listen((data) {
      expect(client.isConnected, isFalse);
      final reply = P20V2Protocol.request(4, [50]); reply[0] = 0x55; reply[reply.length-1] = 0x5a;
      socket.add(reply);
    }); });
    try {
      await client.connect(host: '127.0.0.1', port: server.port);
      expect(client.isConnected, isTrue);
      await client.connect(host: '127.0.0.1', port: server.port);
      expect(connections, 1);
    } finally { await client.dispose(); await server.close(); }
  });
}
