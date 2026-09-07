import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

/// Opens a bundled video directly, then falls back to a real cached file.
Future<VideoPlayerController> createBundledVideoController(
  String assetPath,
) async {
  final assetController = VideoPlayerController.asset(assetPath);
  try {
    await assetController.initialize();
    return assetController;
  } catch (error, stackTrace) {
    debugPrint('Asset video open failed for $assetPath: $error');
    debugPrintStack(stackTrace: stackTrace);
    await assetController.dispose();
  }

  final data = await rootBundle.load(assetPath);
  final directory = await getTemporaryDirectory();
  final fileName = assetPath.split('/').last;
  final file = File(
    '${directory.path}${Platform.pathSeparator}hildors_$fileName',
  );
  if (!await file.exists() || await file.length() != data.lengthInBytes) {
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await file.writeAsBytes(bytes, flush: true);
  }

  final fileController = VideoPlayerController.file(file);
  try {
    await fileController.initialize();
    return fileController;
  } catch (_) {
    await fileController.dispose();
    rethrow;
  }
}
