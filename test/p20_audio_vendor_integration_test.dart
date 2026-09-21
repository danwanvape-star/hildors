import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/video/p20_ffmpeg_preparation.dart';
import 'package:hildors_cockpit/src/features/video/p20_media_upload_flow.dart';
import 'p20_ffmpeg_integration_test.dart' show DesktopEngine;

void main() {
  test('real audio output matches vendor command for first of two tracks',
      () async {
    final root = await Directory.systemTemp.createTemp('p20-audio-vendor-');
    final engine = DesktopEngine();
    final prep = P20FfmpegPreparation(engine, root);
    final source = File('${root.path}/参考 source with spaces.mkv');
    try {
      await engine.execute([
        '-v',
        'error',
        '-y',
        '-f',
        'lavfi',
        '-i',
        'sine=frequency=440:sample_rate=44100',
        '-f',
        'lavfi',
        '-i',
        'sine=frequency=880:sample_rate=48000',
        '-map',
        '0:a',
        '-map',
        '1:a',
        '-t',
        '1',
        '-c:a',
        'pcm_s16le',
        source.path
      ]);
      final sourceBytes = await source.readAsBytes();
      final actual = await prep.extractAudio(source);
      final reference = File('${root.path}/vendor.mp3');
      await engine.execute([
        '-y',
        '-i',
        source.path,
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
        reference.path
      ]);
      expect(await actual.readAsBytes(), await reference.readAsBytes());
      final info = jsonDecode(await engine.execute([
        '-v',
        'error',
        '-show_entries',
        'stream=codec_name,sample_rate,channels,bit_rate',
        '-of',
        'json',
        actual.path
      ], probe: true));
      final stream = info['streams'][0];
      expect(stream['codec_name'], 'mp3');
      expect(stream['sample_rate'], '16000');
      expect(stream['channels'], 2);
      // 17k is the requested vendor bitrate; record the encoder's actual rate.
      // ignore: avoid_print
      print('Vendor-equivalent audio stream: $stream');
      expect(await source.readAsBytes(), sourceBytes);
    } finally {
      await prep.dispose();
      await root.delete(recursive: true);
    }
  }, skip: Platform.environment['HILDORS_FFMPEG'] == null);

  test('real no-audio source is distinct from corrupt input', () async {
    final root = await Directory.systemTemp.createTemp('p20-audio-absent-');
    final engine = DesktopEngine();
    final prep = P20FfmpegPreparation(engine, root);
    try {
      final source = File('${root.path}/silent.mp4');
      await engine.execute([
        '-v',
        'error',
        '-y',
        '-f',
        'lavfi',
        '-i',
        'color=black:size=32x32:rate=20',
        '-t',
        '0.2',
        '-an',
        '-c:v',
        'mpeg4',
        source.path
      ]);
      await expectLater(
          prep.extractAudio(source), throwsA(isA<P20MissingAudio>()));
      final corrupt = await File('${root.path}/corrupt.mp4')
          .writeAsString('not a media file');
      await expectLater(prep.extractAudio(corrupt), throwsA(isA<StateError>()));
    } finally {
      await prep.dispose();
      await root.delete(recursive: true);
    }
  }, skip: Platform.environment['HILDORS_FFMPEG'] == null);
}
