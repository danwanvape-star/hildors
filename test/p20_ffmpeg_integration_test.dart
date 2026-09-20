import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/video/p20_ffmpeg_preparation.dart';

class DesktopEngine implements P20MediaEngine {
  @override
  bool get isIdle => true;
  @override
  Future<void> cancel() async {}
  @override
  Future<String> execute(List<String> args, {bool probe = false}) async {
    final result = await Process.run(
        Platform.environment[probe ? 'HILDORS_FFPROBE' : 'HILDORS_FFMPEG']!,
        args);
    if (result.exitCode != 0) throw StateError('${result.stderr}');
    return result.stdout as String;
  }
}

void main() {
  test('real FFmpeg synthetic source produces MP3 and 20fps device container',
      () async {
    final root = await Directory.systemTemp.createTemp('p20-integration-');
    final source = File('${root.path}/synthetic.mp4');
    final engine = DesktopEngine();
    final prep = P20FfmpegPreparation(engine, root,
        settings: P20TranscodeSettings(scale: 1.1, x: 0.1, y: -0.1));
    try {
      await engine.execute([
        '-v',
        'error',
        '-y',
        '-f',
        'lavfi',
        '-i',
        'testsrc2=size=320x180:rate=25',
        '-f',
        'lavfi',
        '-i',
        'sine=frequency=440:sample_rate=44100',
        '-t',
        '0.2',
        '-c:v',
        'mpeg4',
        '-c:a',
        'aac',
        source.path
      ]);
      final audio = await prep.extractAudio(source);
      final output = await prep.transcodeVideo(source);
      final info = jsonDecode(await engine.execute([
        '-v',
        'error',
        '-show_entries',
        'stream=codec_name,sample_rate,channels',
        '-of',
        'json',
        audio.path
      ], probe: true));
      expect(info['streams'][0]['codec_name'], 'mp3');
      expect(info['streams'][0]['sample_rate'], '16000');
      expect(info['streams'][0]['channels'], 2);
      final bytes = await output.readAsBytes();
      expect(ByteData.sublistView(bytes).getUint32(0, Endian.little), 200);
      await prep.dispose();
      expect(await output.exists(), isFalse);
      expect(await source.exists(), isTrue);
    } finally {
      await prep.dispose();
      await root.delete(recursive: true);
    }
  }, skip: Platform.environment['HILDORS_FFMPEG'] == null);
}
