import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as image;
import 'p20_media_upload_flow.dart';

/// Port of the supplied MakeP20BinOpenCV4 geometry. Input is RGB24, 298 square;
/// the vendor's w/h variables are used as ROW/COLUMN, not x/y.
class P20PolarMapper {
  static const diameter = 298, angles = 960, leds = 149, stride = 160;
  final _rows = Float64List(angles * leds);
  final _cols = Float64List(angles * leds);
  double brightness = 1;

  P20PolarMapper() {
    for (var i = 0; i < angles; i++) {
      for (var l = 0; l < leds; l++) {
        // Preserve the vendor's evaluation order: equivalent trig expressions
        // can cross a byte-truncation boundary during interpolation.
        var degrees = i * 360.0 / angles;
        final radius = l + 0.5;
        double row, col;
        if (degrees <= 90) {
          final radians = degrees * math.pi / 180.0;
          row = 149.5 + radius * math.sin(radians);
          col = 149.5 + radius * math.cos(radians);
        } else if (degrees <= 180) {
          degrees -= 90;
          final radians = degrees * math.pi / 180.0;
          row = 149.5 + radius * math.cos(radians);
          col = 149.5 - radius * math.sin(radians);
        } else if (degrees <= 270) {
          degrees -= 180;
          final radians = degrees * math.pi / 180.0;
          col = 149.5 - radius * math.cos(radians);
          row = 149.5 - radius * math.sin(radians);
        } else {
          degrees -= 270;
          final radians = degrees * math.pi / 180.0;
          row = 149.5 - radius * math.cos(radians);
          col = 149.5 + radius * math.sin(radians);
        }
        _rows[i * leds + l] = row - 1;
        _cols[i * leds + l] = col - 1;
      }
    }
  }

  Uint8List convert(Uint8List rgb) {
    if (rgb.length != diameter * diameter * 3) {
      throw const FormatException('Expected one 298x298 RGB24 frame');
    }
    final output = Uint8List(angles * stride * 3);
    for (var i = 0; i < angles; i++) {
      var sum = 0;
      for (var l = 0; l < leds; l++) {
        if ((l == 0 && i % 16 != 0) || (l > 0 && l < 8 && i % 8 > l)) continue;
        final row = _rows[i * leds + l], col = _cols[i * leds + l];
        final r = row.floor(), c = col.floor();
        final source = (r * diameter + c) * 3;
        final target = ((angles - i - 1) * stride + (159 - l)) * 3;
        for (var channel = 0; channel < 3; channel++) {
          var value = rgb[source + channel];
          if (r <= 296 && c <= 296) {
            final p1 = rgb[source + channel];
            final p2 = rgb[source + diameter * 3 + channel];
            final p3 = rgb[source + 3 + channel];
            final p4 = rgb[source + diameter * 3 + 3 + channel];
            // The reference truncates each intermediate interpolation to byte.
            final top = (p1 + (p2 - p1) * (row - r)).toInt();
            final bottom = (p3 + (p4 - p3) * (row - r)).toInt();
            value = (top + (bottom - top) * (col - c)).toInt();
          }
          output[target + channel] = value;
          sum += value;
        }
      }
      if (sum > 149 * 3 * 128) {
        final rate = Float32List.fromList([149 * 3 * 128 / sum]).single;
        brightness = math.min(brightness, rate);
      }
    }
    return output;
  }
}

/// Vendor BIN container; this is not a standards-compliant MP4 file even though
/// the device protocol uses .mp4 names. Run CPU work in a worker isolate.
class P20BinEncoder {
  static const frameBytes = 298 * 298 * 3;

  Future<void> encode(
    File rawRgb,
    File output, {
    bool Function()? isCancelled,
    void Function(int frames, int total)? onProgress,
  }) async {
    final size = await rawRgb.length();
    if (size == 0 || size % frameBytes != 0) {
      throw const FormatException('Truncated or empty RGB stream');
    }
    final count = size ~/ frameBytes;
    if (count * 50 > 0xffffffff) throw const FormatException('Video too long');
    if (await output.exists()) throw StateError('Output already exists');
    final partial = File('${output.path}.partial');
    if (await partial.exists()) {
      throw StateError('Partial output already exists');
    }
    final input = await rawRgb.open();
    RandomAccessFile? writer;
    var finished = false;
    void check() {
      if (isCancelled?.call() ?? false) throw const P20UploadCancelled();
    }

    try {
      check();
      writer = await partial.open(mode: FileMode.write);
      await writer.writeFrom(_u32(count * 50));
      final black = image.Image(width: 160, height: 960);
      final blackJpeg =
          image.encodeJpg(black, quality: 93, chroma: image.JpegChroma.yuv420);
      await _record(writer, blackJpeg);
      await _record(writer, blackJpeg);
      final mapper = P20PolarMapper();
      for (var n = 0; n < count; n++) {
        check();
        final raw = await input.read(frameBytes);
        if (raw.length != frameBytes) {
          throw const FormatException('Source changed');
        }
        final pixels = mapper.convert(raw);
        final unscaled = image.Image.fromBytes(
            width: 160,
            height: 960,
            bytes: pixels.buffer,
            numChannels: 3,
            order: image.ChannelOrder.rgb);
        final scaled =
            mapper.brightness < 1 ? image.Image.from(unscaled) : unscaled;
        if (mapper.brightness < 1) {
          for (final pixel in scaled) {
            pixel.setRgb(
                (pixel.r * mapper.brightness).round(),
                (pixel.g * mapper.brightness).round(),
                (pixel.b * mapper.brightness).round());
          }
        }
        var jpeg = image.encodeJpg(scaled,
            quality: 93, chroma: image.JpegChroma.yuv420);
        // Preserve the reference's unscaled fallback, but bound its quality loop.
        for (var quality = 92;
            jpeg.length >= 63 * 1024 && quality >= 1;
            quality--) {
          check();
          jpeg = image.encodeJpg(unscaled,
              quality: quality, chroma: image.JpegChroma.yuv420);
        }
        if (jpeg.length >= 63 * 1024) {
          throw const FormatException('Frame too large');
        }
        await _record(writer, jpeg);
        onProgress?.call(n + 1, count);
      }
      check();
      if (await input.length() != size) {
        throw const FormatException('Source changed');
      }
      await writer.flush();
      await writer.close();
      writer = null;
      await partial.rename(output.path);
      finished = true;
    } finally {
      await input.close();
      await writer?.close();
      if (!finished && await partial.exists()) await partial.delete();
    }
  }

  static Uint8List _u32(int value) =>
      (ByteData(4)..setUint32(0, value, Endian.little)).buffer.asUint8List();

  static Future<void> _record(RandomAccessFile writer, Uint8List jpeg) async {
    final length = ((1600 + jpeg.length + 3) ~/ 4) * 4;
    await writer.writeFrom(_u32(length));
    await writer.writeFrom(Uint8List(1600));
    await writer.writeFrom(jpeg);
    await writer.writeFrom(Uint8List(length - 1600 - jpeg.length));
  }
}
