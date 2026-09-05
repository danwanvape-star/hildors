import 'dart:typed_data';

enum P20Command {
  power(0x01),
  playback(0x02),
  track(0x03),
  queryBrightness(0x04),
  setBrightness(0x05),
  queryAngle(0x06),
  setAngle(0x07),
  queryPlayMode(0x08),
  setPlayMode(0x09),
  queryBaudRate(0x0A),
  setBaudRate(0x0B),
  queryStatus(0x0F),
  queryDeviceSsid(0x21),
  setDeviceSsid(0x22),
  queryRouterWifi(0x23),
  setRouterWifi(0x24),
  queryRemoteEndpoint(0x25),
  setRemoteEndpoint(0x26),
  queryWifiMode(0x27),
  setWifiMode(0x28),
  resetWifi(0x29),
  queryNetworkConfig(0x2F),
  uploadVideo(0x31),
  deleteVideo(0x32),
  deleteAllVideos(0x33),
  renameVideo(0x34),
  playVideo(0x35),
  queryVideoList(0x36),
  queryCurrentVideo(0x37),
  reorderVideos(0x38),
  queryBluetoothSpeakerName(0x73),
  setBluetoothSpeakerName(0x74),
  factoryReset(0xC1),
  formatStorage(0xC2),
  queryVersion(0xE8);

  const P20Command(this.code);
  final int code;
}

class P20Frame {
  const P20Frame({required this.command, required this.data});

  final int command;
  final Uint8List data;
}

class P20Protocol {
  static const requestHead = 0xAA;
  static const requestEnd = 0xA5;
  static const responseHead = 0x55;
  static const responseEnd = 0x5A;
  static const crc = 0x20;
  static const legacyCrc = 0x02;

  static Uint8List encode(
    P20Command command, [
    List<int> data = const [],
    int frameCrc = crc,
  ]) {
    final length = 1 + data.length;
    return Uint8List.fromList([
      requestHead,
      (length >> 24) & 0xFF,
      (length >> 16) & 0xFF,
      (length >> 8) & 0xFF,
      length & 0xFF,
      command.code,
      ...data,
      frameCrc,
      requestEnd,
    ]);
  }

  static List<int> uint16BigEndian(int value) {
    if (value < 0 || value > 0xFFFF) {
      throw RangeError.range(value, 0, 0xFFFF, 'value');
    }
    return [(value >> 8) & 0xFF, value & 0xFF];
  }
}

/// Incremental decoder for TCP fragmentation and sticky packets.
class P20FrameDecoder {
  final List<int> _buffer = [];

  List<P20Frame> add(List<int> bytes) {
    _buffer.addAll(bytes);
    final frames = <P20Frame>[];

    while (true) {
      final headIndex = _buffer.indexOf(P20Protocol.responseHead);
      if (headIndex < 0) {
        _buffer.clear();
        break;
      }
      if (headIndex > 0) _buffer.removeRange(0, headIndex);
      if (_buffer.length < 8) break;

      final length = (_buffer[1] << 24) |
          (_buffer[2] << 16) |
          (_buffer[3] << 8) |
          _buffer[4];
      if (length < 1 || length > 2 * 1024 * 1024) {
        _buffer.removeAt(0);
        continue;
      }

      final frameLength = 1 + 4 + length + 1 + 1;
      if (_buffer.length < frameLength) break;
      final frameCrc = _buffer[frameLength - 2];
      final validCrc =
          frameCrc == P20Protocol.crc || frameCrc == P20Protocol.legacyCrc;
      if (!validCrc || _buffer[frameLength - 1] != P20Protocol.responseEnd) {
        _buffer.removeAt(0);
        continue;
      }

      frames.add(P20Frame(
        command: _buffer[5],
        data: Uint8List.fromList(_buffer.sublist(6, 5 + length)),
      ));
      _buffer.removeRange(0, frameLength);
    }
    return frames;
  }
}
