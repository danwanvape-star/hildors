import 'dart:async';
import 'package:hildors_cockpit/src/device/p20_device_profile.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/video/p20_media_upload_flow.dart';

class FakeMedia implements P20MediaPreparation {
  FakeMedia(this.events);
  final List<String> events;
  bool missingAudio = false;
  bool brokenAudio = false;
  Completer<void>? pauseAudio;
  @override
  Future<void> cancel() async {}
  @override
  Future<File> extractAudio(File source) async {
    events.add('extract');
    await pauseAudio?.future;
    if (missingAudio) throw const P20MissingAudio();
    if (brokenAudio) throw StateError('audio encoder failed');
    return File('sound.mp3');
  }

  @override
  Future<File> transcodeVideo(File source) async {
    events.add('transcode');
    return File('device.bin');
  }
}

class FakeUpload implements P20MediaDestination {
  FakeUpload(this.events);
  final List<String> events;
  bool failAudio = false;
  bool failVideo = false;
  @override
  Future<void> cancel() async {}
  @override
  Future<void> upload(File file, int listId, String name) async {
    events.add('$listId:$name');
    if ((failAudio && name.endsWith('.mp3')) ||
        (failVideo && name.endsWith('.mp4'))) {
      throw StateError('device rejected file');
    }
  }

  @override
  Future<void> refresh(int listId) async => events.add('refresh:$listId');
}

void main() {
  late List<String> events;
  late FakeMedia media;
  late FakeUpload destination;
  late P20MediaUploadFlow flow;
  setUp(() {
    events = [];
    media = FakeMedia(events);
    destination = FakeUpload(events);
    flow = P20MediaUploadFlow(media, destination);
  });
  test('single never extracts audio and uploads only bin to list zero',
      () async {
    final stages = <P20MediaStage>[];
    flow = P20MediaUploadFlow(media, destination,
        profile: const P20DeviceProfile.forKind(P20DeviceKind.single),
        onStage: stages.add);
    await flow.run(File('source.mp4'), P20MediaList.daily, 'clip');
    expect(events, ['transcode', '0:clip.bin', 'refresh:0']);
    expect(stages, isNot(contains(P20MediaStage.extractingAudio)));
    expect(stages, isNot(contains(P20MediaStage.uploadingAudio)));
  });
  test('single rejects second list and overlong name before preparation',
      () async {
    flow = P20MediaUploadFlow(media, destination,
        profile: const P20DeviceProfile.forKind(P20DeviceKind.single));
    await expectLater(flow.run(File('x'), P20MediaList.bluetooth, 'clip'),
        throwsArgumentError);
    await expectLater(
        flow.run(File('x'), P20MediaList.daily, 'x' * 29), throwsArgumentError);
    expect(events, isEmpty);
  });
  test('cancelling preparation prevents all subsequent upload', () async {
    media.pauseAudio = Completer<void>();
    final pending = flow.run(File('source.mp4'), P20MediaList.daily, 'sample');
    await flow.cancel();
    final assertion = expectLater(pending, throwsA(isA<P20UploadCancelled>()));
    media.pauseAudio!.complete();
    await assertion;
    expect(events, ['extract']);
    expect(flow.stage, P20MediaStage.cancelled);
  });
  test('A prepares both files then uploads audio before video', () async {
    await flow.run(File('source.mp4'), P20MediaList.daily, 'sample');
    expect(events,
        ['extract', 'transcode', '0:sample.mp3', '0:sample.mp4', 'refresh:0']);
    expect(flow.stage, P20MediaStage.completed);
  });
  test('B never touches audio extraction', () async {
    media.missingAudio = true;
    await flow.run(File('source.mp4'), P20MediaList.bluetooth, 'sample');
    expect(events, ['transcode', '1:sample.mp4', 'refresh:1']);
  });
  test('A without audio uploads video only', () async {
    media.missingAudio = true;
    await flow.run(File('source.mp4'), P20MediaList.daily, 'sample');
    expect(events, ['extract', 'transcode', '0:sample.mp4', 'refresh:0']);
    expect(flow.audioUploaded, isFalse);
    expect(flow.stage, P20MediaStage.completed);
  });
  test('A audio encoder failure is not treated as a silent source', () async {
    media.brokenAudio = true;
    await expectLater(
        flow.run(File('source.mp4'), P20MediaList.daily, 'sample'),
        throwsStateError);
    expect(events, ['extract']);
    expect(flow.stage, P20MediaStage.failed);
  });
  test('failed audio prevents video upload', () async {
    destination.failAudio = true;
    await expectLater(
        flow.run(File('source.mp4'), P20MediaList.daily, 'sample'),
        throwsStateError);
    expect(events, ['extract', 'transcode', '0:sample.mp3']);
    expect(flow.audioUploaded, isFalse);
  });
  test('video failure preserves knowledge of completed audio', () async {
    destination.failVideo = true;
    await expectLater(
        flow.run(File('source.mp4'), P20MediaList.daily, 'sample'),
        throwsStateError);
    expect(flow.audioUploaded, isTrue);
    expect(events, isNot(contains('refresh:0')));
  });
  test('rejects device path and reserved prefix before preparation', () async {
    for (final name in ['../sample', 'a_sample', 'b_sample', 'x/y', '']) {
      await expectLater(flow.run(File('source.mp4'), P20MediaList.daily, name),
          throwsArgumentError);
    }
    expect(events, isEmpty);
  });
}
