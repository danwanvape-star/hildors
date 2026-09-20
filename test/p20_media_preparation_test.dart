import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/video/p20_ffmpeg_preparation.dart';
import 'package:hildors_cockpit/src/features/video/p20_media_upload_flow.dart';

class FakeEngine implements P20MediaEngine {
  @override
  bool get isIdle => idle;
  bool idle = true;
  final commands = <List<String>>[];
  bool hasAudio = true;
  @override
  Future<void> cancel() async {}
  @override
  Future<String> execute(List<String> args, {bool probe = false}) async {
    commands.add(args);
    if (probe) return hasAudio ? '{"streams":[{"index":1}]}' : '{"streams":[]}';
    await File(args.last).writeAsBytes(
        args.contains('libmp3lame') ? [1, 2, 3] : Uint8List(298 * 298 * 3));
    return '';
  }
}

void main() {
  test('cleanup preserves files until native session has stopped', () async {
    final root = await Directory.systemTemp.createTemp('p20-busy-native-');
    final source = await File('${root.path}/source').writeAsBytes([42]);
    final engine = FakeEngine();
    final prep = P20FfmpegPreparation(engine, root);
    try {
      final audio = await prep.extractAudio(source);
      engine.idle = false;
      await expectLater(prep.dispose(), throwsStateError);
      expect(await audio.exists(), isTrue);
      engine.idle = true;
      await prep.dispose();
      expect(await audio.exists(), isFalse);
    } finally {
      engine.idle = true;
      await prep.dispose();
      await root.delete(recursive: true);
    }
  });
  test('audio uses exact vendor arguments; video has no audio and uses 20fps',
      () async {
    final root = await Directory.systemTemp.createTemp('p20-prepare-test-');
    final source =
        await File('${root.path}/original source.mp4').writeAsBytes([42]);
    final engine = FakeEngine();
    final prep = P20FfmpegPreparation(engine, root,
        settings: P20TranscodeSettings(scale: 1.2, x: 0.1));
    try {
      final audio = await prep.extractAudio(source);
      final video = await prep.transcodeVideo(source);
      expect(
          engine.commands[1],
          containsAllInOrder([
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
            '17k'
          ]));
      expect(engine.commands[2], contains('-an'));
      expect(engine.commands[2].join(' '), contains('fps=20'));
      expect(engine.commands[2].join(' '), contains('crop=298:298'));
      expect(await video.length(), greaterThan(0));
      await prep.dispose();
      expect(await audio.exists(), isFalse);
      expect(await video.exists(), isFalse);
      expect(await source.readAsBytes(), [42]);
    } finally {
      await prep.dispose();
      await root.delete(recursive: true);
    }
  });
  test('missing audio is reported before encoding', () async {
    final root = await Directory.systemTemp.createTemp('p20-noaudio-test-');
    final source = await File('${root.path}/source').writeAsBytes([42]);
    final engine = FakeEngine()..hasAudio = false;
    final prep = P20FfmpegPreparation(engine, root);
    try {
      await expectLater(
          prep.extractAudio(source), throwsA(isA<P20MissingAudio>()));
      expect(engine.commands, hasLength(1));
    } finally {
      await prep.dispose();
      await root.delete(recursive: true);
    }
  });
  test('invalid framing is rejected', () {
    expect(() => P20TranscodeSettings(scale: double.nan), throwsArgumentError);
    expect(() => P20TranscodeSettings(x: 0.5), throwsArgumentError);
  });
}
