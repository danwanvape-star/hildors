import 'dart:io';

enum P20MediaList { daily, bluetooth }

enum P20MediaStage {
  idle,
  extractingAudio,
  transcodingVideo,
  uploadingAudio,
  uploadingVideo,
  refreshing,
  completed,
  failed,
  cancelled,
}

class P20UploadCancelled implements Exception {
  const P20UploadCancelled();
}

class P20MissingAudio implements Exception {
  const P20MissingAudio();
  @override
  String toString() => 'p20_source_has_no_audio';
}

/// Implementations own their temporary files; the source must never be changed.
/// Video output must be the vendor container, normalized to 298x298 at 20 fps.
abstract interface class P20MediaPreparation {
  Future<void> cancel();
  Future<File> extractAudio(File source);
  Future<File> transcodeVideo(File source);
}

abstract interface class P20MediaDestination {
  /// Disconnect the device transport; never send cancellation as file bytes.
  Future<void> cancel();

  /// Returns only after the device has confirmed the entire file.
  Future<void> upload(File file, int listId, String name);
  Future<void> refresh(int listId);
}

/// One instance represents one attempt; failed paired uploads must be reconciled
/// explicitly, never blindly retried over existing device files.
class P20MediaUploadFlow {
  P20MediaUploadFlow(this.media, this.destination, {this.onStage});
  final P20MediaPreparation media;
  final P20MediaDestination destination;
  final void Function(P20MediaStage stage)? onStage;
  P20MediaStage stage = P20MediaStage.idle;
  bool audioUploaded = false;
  bool videoUploaded = false;
  bool _started = false;
  bool _cancelled = false;

  Future<void> cancel() async {
    if (stage == P20MediaStage.completed ||
        stage == P20MediaStage.failed ||
        _cancelled) {
      return;
    }
    _cancelled = true;
    await Future.wait([media.cancel(), destination.cancel()]);
  }

  void _checkCancelled() {
    if (_cancelled) throw const P20UploadCancelled();
  }

  void _set(P20MediaStage next) {
    if (next != P20MediaStage.failed && next != P20MediaStage.cancelled) {
      _checkCancelled();
    }
    stage = next;
    onStage?.call(next);
  }

  Future<void> run(File source, P20MediaList list, String baseName) async {
    // Generated ASCII device identifiers are a valid subset of CP936. User
    // display titles stay separate; full GBK title encoding belongs to the UI adapter.
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,56}$').hasMatch(baseName) ||
        baseName.toLowerCase().startsWith('a_') ||
        baseName.toLowerCase().startsWith('b_')) {
      throw ArgumentError.value(baseName, 'baseName');
    }
    if (_started) throw StateError('Create a new attempt after reconciliation');
    _started = true;
    try {
      File? audio;
      if (list == P20MediaList.daily) {
        _set(P20MediaStage.extractingAudio);
        audio = await media.extractAudio(source);
      }
      _set(P20MediaStage.transcodingVideo);
      final video = await media.transcodeVideo(source);
      if (audio != null) {
        _set(P20MediaStage.uploadingAudio);
        await destination.upload(audio, list.index, '$baseName.mp3');
        audioUploaded = true;
      }
      _set(P20MediaStage.uploadingVideo);
      await destination.upload(video, list.index, '$baseName.mp4');
      videoUploaded = true;
      _set(P20MediaStage.refreshing);
      await destination.refresh(list.index);
      _set(P20MediaStage.completed);
    } catch (_) {
      _set(_cancelled ? P20MediaStage.cancelled : P20MediaStage.failed);
      if (_cancelled) throw const P20UploadCancelled();
      rethrow;
    }
  }
}
