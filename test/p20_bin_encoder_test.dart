import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:hildors_cockpit/src/features/video/p20_bin_encoder.dart';

void main() {
  test('cancel removes partial file and preserves raw source', () async {
    final dir = await Directory.systemTemp.createTemp('p20-cancel-encode-');
    try {
      final raw = await File('${dir.path}/raw')
          .writeAsBytes(Uint8List(298 * 298 * 3 * 2));
      final output = File('${dir.path}/output');
      var cancelled = false;
      await expectLater(
          P20BinEncoder().encode(raw, output,
              isCancelled: () => cancelled,
              onProgress: (_, __) => cancelled = true),
          throwsA(isA<Exception>()));
      expect(await output.exists(), isFalse);
      expect(await File('${output.path}.partial').exists(), isFalse);
      expect(await raw.length(), 298 * 298 * 3 * 2);
    } finally {
      await dir.delete(recursive: true);
    }
  });
  test('polar mapping retains vendor row/column order and LED masking', () {
    final rgb = Uint8List(298 * 298 * 3);
    for (var row = 0; row < 298; row++) {
      for (var col = 0; col < 298; col++) {
        rgb[(row * 298 + col) * 3] = row ~/ 2;
        rgb[(row * 298 + col) * 3 + 1] = col ~/ 2;
      }
    }
    final polar = P20PolarMapper().convert(rgb);
    // i=0, l=100 -> source row 148.5, col 249; destination row959,col59.
    expect(polar.sublist((959 * 160 + 59) * 3, (959 * 160 + 59) * 3 + 3),
        [74, 124, 0]);
    // i=1, l=0 is masked at the centre.
    expect(polar.sublist((958 * 160 + 159) * 3, (958 * 160 + 159) * 3 + 3),
        [0, 0, 0]);
    expect(polar.sublist(0, 11 * 3), everyElement(0));
  });
  test('writes little endian duration, two black frames, aligned JPEG records',
      () async {
    final dir = await Directory.systemTemp.createTemp('p20-bin-');
    try {
      final raw = await File('${dir.path}/frames.rgb')
          .writeAsBytes(Uint8List(298 * 298 * 3 * 2));
      final output = File('${dir.path}/device.bin');
      await P20BinEncoder().encode(raw, output);
      final bytes = await output.readAsBytes();
      final data = ByteData.sublistView(bytes);
      expect(data.getUint32(0, Endian.little), 100);
      var offset = 4;
      var count = 0;
      while (offset < bytes.length) {
        final length = data.getUint32(offset, Endian.little);
        expect(length % 4, 0);
        expect(bytes.sublist(offset + 4, offset + 1604), everyElement(0));
        final decoded =
            image.decodeJpg(bytes.sublist(offset + 1604, offset + 4 + length))!;
        expect([decoded.width, decoded.height], [160, 960]);
        expect(decoded.getPixel(80, 480).r, lessThan(3));
        offset += 4 + length;
        count++;
      }
      expect(offset, bytes.length);
      expect(count, 4);
    } finally {
      await dir.delete(recursive: true);
    }
  });
  test('rejects truncated frames without publishing a device file', () async {
    final dir = await Directory.systemTemp.createTemp('p20-truncated-');
    try {
      final raw = await File('${dir.path}/input').writeAsBytes([1, 2, 3]);
      final output = File('${dir.path}/output');
      await expectLater(
          P20BinEncoder().encode(raw, output), throwsFormatException);
      expect(await output.exists(), isFalse);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
