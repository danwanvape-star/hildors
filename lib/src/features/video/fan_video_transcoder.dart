import 'dart:io';
import 'fan_framing_page.dart';

/// Manufacturer adapter contract. No implementation is enabled until the
/// device format, audio handling and output specifications are confirmed.
abstract interface class FanVideoTranscoder {
  Future<File> transcode({
    required File source,
    required FanFraming framing,
    required String deviceModel,
    required void Function(double fraction) onProgress,
  });
}
