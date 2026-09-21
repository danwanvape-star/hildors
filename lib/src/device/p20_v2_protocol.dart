import 'dart:typed_data';
import '../protocol/p20_protocol.dart' show P20Frame;

/// September 2026 firmware. Deliberately separate from the legacy P11 codec.
class P20V2Protocol {
  static Uint8List request(int command, [List<int> data = const []]) {
    if (command < 0 || command > 255 || data.any((v) => v < 0 || v > 255)) {
      throw ArgumentError('Protocol fields must be bytes');
    }
    final size = ByteData(4)..setUint32(0, data.length + 1, Endian.big);
    final body = [...size.buffer.asUint8List(), command, ...data];
    return Uint8List.fromList([0xaa, ...body, checksum(body), 0xa5]);
  }

  static int checksum(Iterable<int> bytes) =>
      bytes.fold(0, (sum, byte) => (sum + byte) & 0xff);

  /// The caller supplies CP936-encoded bytes, never UTF-8 bytes.
  static Uint8List uploadHeader(int listId, int size, List<int> gbkName) {
    if (listId != 0 && listId != 1) throw ArgumentError.value(listId);
    if (size <= 0 || size > 0xffffffff) throw ArgumentError.value(size);
    if (gbkName.isEmpty ||
        gbkName.length > 61 ||
        gbkName.any((v) => v < 0x20 || v > 255)) {
      throw ArgumentError('Filename must contain 1–61 encoded bytes');
    }
    final asciiView = String.fromCharCodes(gbkName).toLowerCase();
    if (gbkName.length <= 4 ||
        !(asciiView.endsWith('.mp3') || asciiView.endsWith('.mp4')) ||
        asciiView.startsWith('a_') ||
        asciiView.startsWith('b_') ||
        asciiView.startsWith('.')) {
      throw ArgumentError('Invalid device filename');
    }
    for (var i = 0; i < gbkName.length; i++) {
      final byte = gbkName[i];
      if (byte >= 0x81 && byte <= 0xfe) {
        if (++i >= gbkName.length ||
            gbkName[i] < 0x40 ||
            gbkName[i] > 0xfe ||
            gbkName[i] == 0x7f) {
          throw ArgumentError('Malformed GBK filename');
        }
      } else if (byte >= 0x7f || '<>:"/\\|?*'.codeUnits.contains(byte)) {
        throw ArgumentError('Invalid filename character');
      }
    }
    final length = ByteData(4)..setUint32(0, size, Endian.big);
    return Uint8List.fromList(
        [listId, ...length.buffer.asUint8List(), ...gbkName]);
  }
}

class P20V2Decoder {
  final List<int> _buffer = [];
  int receivedBytes = 0, validFrames = 0, rejectedFrames = 0;
  int? lastCommand;
  int get pendingBytes => _buffer.length;
  int? get pendingLength => _buffer.length < 5
      ? null
      : (_buffer[1] << 24) |
          (_buffer[2] << 16) |
          (_buffer[3] << 8) |
          _buffer[4];
  void reset() => _buffer.clear();

  List<P20Frame> add(List<int> bytes) {
    receivedBytes += bytes.length;
    _buffer.addAll(bytes);
    final result = <P20Frame>[];
    while (_buffer.isNotEmpty) {
      final head = _buffer.indexOf(0x55);
      if (head < 0) {
        reset();
        break;
      }
      if (head > 0) _buffer.removeRange(0, head);
      if (_buffer.length < 8) break;
      final length = (_buffer[1] << 24) |
          (_buffer[2] << 16) |
          (_buffer[3] << 8) |
          _buffer[4];
      // Responses are short metadata, never the raw uploaded file.
      if (length < 1 || length > 4096) {
        _buffer.removeAt(0);
        continue;
      }
      final end = length + 7;
      if (_buffer.length < end) break;
      if (_buffer[end - 1] != 0x5a ||
          _buffer[end - 2] !=
              P20V2Protocol.checksum(_buffer.sublist(1, end - 2))) {
        // The complete frame boundary is known. Corrupt payload bytes must not
        // be reinterpreted as standalone replies (protocol section 2.2).
        rejectedFrames++;
        _buffer.removeRange(0, end);
        continue;
      }
      validFrames++;
      lastCommand = _buffer[5];
      result.add(P20Frame(
          command: _buffer[5],
          data: Uint8List.fromList(_buffer.sublist(6, end - 2))));
      _buffer.removeRange(0, end);
    }
    return result;
  }
}
