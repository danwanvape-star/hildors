import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/video/device_playlist_draft.dart';

void main() {
  const source = DevicePlaylistDraft(
    kind: DevicePlaylistKind.startup,
    enabled: true,
    loopMode: PlaylistLoopMode.listLoop,
    videoNames: ['a.mp4', 'b.mp4', 'c.mp4'],
  );

  test('playlist draft moves a video without changing the source', () {
    final moved = source.move(2, 0);

    expect(source.videoNames, ['a.mp4', 'b.mp4', 'c.mp4']);
    expect(moved.videoNames, ['c.mp4', 'a.mp4', 'b.mp4']);
  });

  test('playlist draft ignores an invalid move', () {
    expect(identical(source.move(0, 4), source), isTrue);
  });

  test('playlist draft adds and removes a unique device video', () {
    final added = source.add('d.mp4').add('d.mp4');
    final removed = added.remove('b.mp4');

    expect(added.videoNames.where((name) => name == 'd.mp4').length, 1);
    expect(removed.videoNames, ['a.mp4', 'c.mp4', 'd.mp4']);
  });
}
