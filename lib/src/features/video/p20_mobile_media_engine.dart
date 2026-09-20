import 'dart:async';
import 'package:ffmpeg_kit_flutter_new_audio/abstract_session.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_session.dart';
import 'package:ffmpeg_kit_flutter_new_audio/log_redirection_strategy.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'p20_ffmpeg_preparation.dart';
import 'p20_media_upload_flow.dart';

abstract interface class P20NativeJob {
  Future<void> start();
  Future<String> get result;
  Future<void> cancel();
  bool get finished;
}

typedef P20NativeJobFactory = Future<P20NativeJob> Function(List<String>, bool);

/// A stalled native job poisons this runner. Keep its files until completion.
class P20MobileMediaEngine implements P20MediaEngine {
  P20MobileMediaEngine({
    P20NativeJobFactory? factory,
    this.executionTimeout = const Duration(minutes: 10),
    this.cancellationTimeout = const Duration(seconds: 10),
  }) : _factory = factory ?? _FFmpegJob.create;
  final P20NativeJobFactory _factory;
  final Duration executionTimeout, cancellationTimeout;
  bool _cancelled = false, _running = false;
  P20NativeJob? _job;
  Completer<void>? _cancelWaiter;

  Future<void> _stopAndDrain() async {
    final job = _job;
    if (job == null || job.finished) return;
    try {
      await job.cancel().timeout(cancellationTimeout);
      await job.result.timeout(cancellationTimeout);
    } catch (_) {
      // Retain an unconfirmed native job; isIdle prevents deleting its files.
    }
  }

  @override
  bool get isIdle => !_running && (_job == null || _job!.finished);

  @override
  Future<String> execute(List<String> args, {bool probe = false}) async {
    if (_cancelled) throw const P20UploadCancelled();
    if (!isIdle) throw StateError('Media engine is busy');
    _running = true;
    final cancelled = Completer<void>();
    _cancelWaiter = cancelled;
    Future<T> guarded<T>(Future<T> action) => Future.any<T>([
          action,
          cancelled.future.then<T>((_) => throw const P20UploadCancelled()),
        ]).timeout(executionTimeout);
    try {
      final job = await guarded(_factory(args, probe));
      if (_cancelled) throw const P20UploadCancelled();
      _job = job;
      await guarded(job.start());
      final output = await guarded(job.result);
      if (_cancelled) throw const P20UploadCancelled();
      return output;
    } on P20UploadCancelled {
      await _stopAndDrain();
      rethrow;
    } on TimeoutException {
      _cancelled = true;
      await _stopAndDrain();
      throw TimeoutException('p20_media_processing_timeout');
    } finally {
      _running = false;
      _cancelWaiter = null;
      if (_job?.finished ?? false) _job = null;
    }
  }

  @override
  Future<void> cancel() async {
    _cancelled = true;
    final waiter = _cancelWaiter;
    if (waiter != null && !waiter.isCompleted) waiter.complete();
    await _job?.cancel().timeout(cancellationTimeout);
  }
}

class _FFmpegJob implements P20NativeJob {
  _FFmpegJob(this.session, this._completed, this.probe);
  final AbstractSession session;
  final Completer<AbstractSession> _completed;
  final bool probe;

  static Future<P20NativeJob> create(List<String> args, bool probe) async {
    final completed = Completer<AbstractSession>();
    void finish(AbstractSession session) {
      if (!completed.isCompleted) completed.complete(session);
    }

    final AbstractSession session;
    if (probe) {
      session = await FFprobeSession.create(
          args, finish, (_) {}, LogRedirectionStrategy.neverPrintLogs);
    } else {
      session = await FFmpegSession.create(
          args, finish, (_) {}, null, LogRedirectionStrategy.neverPrintLogs);
    }
    if (session.getSessionId() == null) {
      throw StateError('Native session unavailable');
    }
    return _FFmpegJob(session, completed, probe);
  }

  @override
  bool get finished => _completed.isCompleted;
  @override
  Future<void> start() => probe
      ? FFmpegKitConfig.asyncFFprobeExecute(session as FFprobeSession)
      : FFmpegKitConfig.asyncFFmpegExecute(session as FFmpegSession);
  @override
  Future<void> cancel() => FFmpegKit.cancel(session.getSessionId()!);
  @override
  Future<String> get result async {
    final done = await _completed.future;
    final code = await done.getReturnCode();
    if (ReturnCode.isCancel(code)) throw const P20UploadCancelled();
    if (!ReturnCode.isSuccess(code)) {
      throw const FormatException('p20_media_processing_failed');
    }
    return probe ? (await done.getOutput() ?? '') : '';
  }
}
