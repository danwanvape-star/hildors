import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/video/device_playlist_draft.dart';

void main() {
  test('playlist draft moves a video without changing the source', () {
    const source = DevicePlaylistDraft(
      kind: DevicePlaylistKind.startup,
      enabled: true,
      loopMode: PlaylistLoopMode.listLoop,
      videoNames: ['a.mp4', 'b.mp4', 'c.mp4'],
    );

    final moved = source.move(2, 0);

    expect(source.videoNames, ['a.mp4', 'b.mp4', 'c.mp4']);
    expect(moved.videoNames, ['c.mp4', 'a.mp4', 'b.mp4']);
  });

  test('playlist draft ignores an invalid move', () {
    const source = DevicePlaylistDraft(
      kind: DevicePlaylistKind.bluetooth,
      enabled: true,
      loopMode: PlaylistLoopMode.listLoop,
      videoNames: ['music.mp4'],
    );

    expect(identical(source.move(0, 4), source), isTrue);
  });
}
