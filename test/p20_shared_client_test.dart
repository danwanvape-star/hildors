import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/device/p20_device_client.dart';
import 'package:hildors_cockpit/src/device/p20_v2_protocol.dart';
import 'package:hildors_cockpit/src/protocol/p20_protocol.dart';

void main() {
  test('modern controls and upload share one serialized socket', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final directory = await Directory.systemTemp.createTemp('p20-shared-');
    final file =
        await File('${directory.path}/video').writeAsBytes([11, 12, 13]);
    var connections = 0;
    final received = <List<int>>[];
    Socket? peer;
    final subscription = server.listen((socket) {
      connections++;
      peer = socket;
      socket.listen((bytes) {
        received.add(bytes.toList());
        final command = bytes[0] == 0xaa ? bytes[5] : 0x31;
        final data = command == 0x31
            ? [bytes[0] == 0xaa ? 0 : 2]
            : [1, 1, 50, 0, 0, 1, 0, 1];
        final response = P20V2Protocol.request(command, data);
        response[0] = 0x55;
        response[response.length - 1] = 0x5a;
        socket.add(response);
      });
    });
    final client = P20DeviceClient(modernProtocol: true);
    try {
      await client.connect(host: '127.0.0.1', port: server.port);
      final upload = client.uploadFile(file, 1, 'sample.mp4'.codeUnits);
      final status = client.requestFrame(P20Command.queryStatus);
      await upload;
      final parsed = client.parseStatus(await status);
      expect(parsed?.listId, 1);
      expect(connections, 1);
      expect(received, hasLength(3));
      expect(received[1], [11, 12, 13]);
      expect(received[2], P20V2Protocol.request(0x0f));
    } finally {
      await client.dispose();
      peer?.destroy();
      await subscription.cancel();
      await server.close();
      await directory.delete(recursive: true);
    }
  });
}
