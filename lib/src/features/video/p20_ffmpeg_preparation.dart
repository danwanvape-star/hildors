import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'p20_bin_encoder.dart';
import 'p20_media_upload_flow.dart';

abstract interface class P20MediaEngine {
  bool get isIdle;
  Future<String> execute(List<String> args, {bool probe = false});
  Future<void> cancel();
}

class P20TranscodeSettings {
  P20TranscodeSettings({this.scale = 1, this.x = 0, this.y = 0}) {
    if (!scale.isFinite ||
        scale < 0.2 ||
        scale > 4 ||
        !x.isFinite ||
        x.abs() > 0.3 ||
        !y.isFinite ||
        y.abs() > 0.3) {
      throw ArgumentError('Invalid fan framing');
    }
  }
  final double scale, x, y;
  String get filter => "scale=w='max(1,round(iw*min(298/iw,298/ih)*$scale))':"
      "h='max(1,round(ih*min(298/iw,298/ih)*$scale))',"
      "pad=w='max(iw,298)+180':h='max(ih,298)+180':"
      "x='(ow-iw)/2+${x * 298}':y='(oh-ih)/2+${y * 298}':color=black,"
      'crop=298:298:(iw-298)/2:(ih-298)/2,setsar=1,fps=20,format=rgb24';
}

/// Owns only a unique temporary directory. Caller must dispose after uploading.
class P20FfmpegPreparation implements P20MediaPreparation {
  P20FfmpegPreparation(this.engine, this.tempRoot,
      {P20TranscodeSettings? settings})
      : settings = settings ?? P20TranscodeSettings();
  final P20MediaEngine engine;
  final Directory tempRoot;
  final P20TranscodeSettings settings;
  static const maximumRawBytes = 512 * 1024 * 1024;
  Directory? _work;
  Completer<void>? _busy;
  bool _cancelled = false, _disposed = false;

  void _check() {
    if (_cancelled) throw const P20UploadCancelled();
    if (_disposed) throw StateError('Preparation disposed');
  }

  Future<T> _operation<T>(Future<T> Function(Directory work) action) async {
    _check();
    if (_busy != null) throw StateError('Media preparation is already running');
    final busy = Completer<void>();
    _busy = busy;
    try {
      _work ??= await tempRoot.createTemp('p20-');
      _check();
      final result = await action(_work!);
      _check();
      return result;
    } finally {
      _busy = null;
      busy.complete();
    }
  }

  @override
  Future<File> extractAudio(File source) => _operation((work) async {
        final info = jsonDecode(await engine.execute([
          '-v',
          'error',
          '-select_streams',
          'a:0',
          '-show_entries',
          'stream=index',
          '-of',
          'json',
          source.absolute.path,
        ], probe: true)) as Map<String, dynamic>;
        _check();
        if ((info['streams'] as List).isEmpty) throw const P20MissingAudio();
        final output = File('${work.path}/audio.mp3');
        await engine.execute([
          '-hide_banner',
          '-loglevel',
          'error',
          '-nostdin',
          '-y',
          '-i',
          source.absolute.path,
          '-map',
          '0:a:0',
          '-vn',
          '-ac',
          '2',
          '-ar',
          '16000',
          '-c:a',
          'libmp3lame',
          '-b:a',
          '17k',
          output.path,
        ]);
        if (!await output.exists() || await output.length() == 0) {
          throw const FormatException('Audio encoder produced no data');
        }
        return output;
      });

  @override
  Future<File> transcodeVideo(File source) => _operation((work) async {
        final raw = File('${work.path}/frames.rgb');
        final output = File('${work.path}/video.bin');
        try {
          await engine.execute([
            '-hide_banner',
            '-loglevel',
            'error',
            '-nostdin',
            '-y',
            '-i',
            source.absolute.path,
            '-map',
            '0:v:0',
            '-an',
            '-sn',
            '-dn',
            '-vf',
            settings.filter,
            '-c:v',
            'rawvideo',
            '-pix_fmt',
            'rgb24',
            '-threads',
            '1',
            '-f',
            'rawvideo',
            '-fs',
            '$maximumRawBytes',
            raw.path,
          ]);
          _check();
          if (await raw.length() >= maximumRawBytes) {
            throw const FormatException(
                'Video exceeds local preparation limit');
          }
          final paths = [raw.path, output.path, '${work.path}/cancel'];
          await _runIsolated(paths);
          return output;
        } finally {
          if (engine.isIdle && await raw.exists()) await raw.delete();
        }
      });

  // A static boundary avoids capturing this object's pending Completer.
  static Future<void> _runIsolated(List<String> paths) =>
      Isolate.run(() => _encodeDeviceFile(paths));

  static Future<void> _encodeDeviceFile(List<String> paths) =>
      P20BinEncoder().encode(File(paths[0]), File(paths[1]),
          isCancelled: () => File(paths[2]).existsSync());

  @override
  Future<void> cancel() async {
    _cancelled = true;
    final work = _work;
    if (work != null && await work.exists()) {
      await File('${work.path}/cancel').writeAsString('cancel');
    }
    await engine.cancel();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    if (_busy != null) {
      final idle = _busy!.future;
      await cancel();
      await idle;
    }
    if (!engine.isIdle) throw StateError('p20_native_job_still_running');
    _disposed = true;
    final work = _work;
    if (work != null && await work.exists()) await work.delete(recursive: true);
  }
}
