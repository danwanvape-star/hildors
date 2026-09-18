import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

/// Opens a bundled video directly, then falls back to a real cached file.
Future<VideoPlayerController> createBundledVideoController(
  String assetPath, {
  Future<void>? cancel,
}) async {
  var cancelled = false;
  final cancellation = cancel?.then((_) {
    cancelled = true;
  });
  void checkCancelled() {
    if (cancelled) throw StateError('Video initialization cancelled');
  }

  Future<void> initialize(VideoPlayerController controller) async {
    checkCancelled();
    if (cancellation == null) {
      await controller.initialize();
    } else {
      await Future.any<void>([controller.initialize(), cancellation]);
    }
    checkCancelled();
  }

  final assetController = VideoPlayerController.asset(assetPath);
  Object? assetError;
  try {
    await initialize(assetController);
    return assetController;
  } catch (error, stackTrace) {
    assetError = error;
    debugPrint('Asset video open failed for $assetPath: $error');
    debugPrintStack(stackTrace: stackTrace);
    await assetController.dispose();
    checkCancelled();
  }

  final data = await rootBundle.load(assetPath);
  final directory = await getTemporaryDirectory();
  checkCancelled();
  final fileName = assetPath.split('/').last;
  final file = File(
    '${directory.path}${Platform.pathSeparator}hildors_$fileName',
  );
  if (!await file.exists() || await file.length() != data.lengthInBytes) {
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await file.writeAsBytes(bytes, flush: true);
  }

  if (await file.length() != data.lengthInBytes) {
    throw StateError(
      'Cached video size mismatch: ${await file.length()}/${data.lengthInBytes}',
    );
  }

  checkCancelled();
  final fileController = VideoPlayerController.file(file);
  try {
    await initialize(fileController);
    return fileController;
  } catch (fileError) {
    await fileController.dispose();
    throw StateError('asset=$assetError; file=$fileError');
  }
}
