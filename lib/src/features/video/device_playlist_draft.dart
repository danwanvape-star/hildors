enum DevicePlaylistKind { startup, bluetooth }

enum PlaylistLoopMode { listLoop, singleLoop, playOnce }

class DevicePlaylistDraft {
  const DevicePlaylistDraft({
    required this.kind,
    required this.enabled,
    required this.loopMode,
    required this.videoNames,
  });

  final DevicePlaylistKind kind;
  final bool enabled;
  final PlaylistLoopMode loopMode;
  final List<String> videoNames;

  DevicePlaylistDraft copyWith({
    bool? enabled,
    PlaylistLoopMode? loopMode,
    List<String>? videoNames,
  }) =>
      DevicePlaylistDraft(
        kind: kind,
        enabled: enabled ?? this.enabled,
        loopMode: loopMode ?? this.loopMode,
        videoNames: videoNames ?? this.videoNames,
      );

  DevicePlaylistDraft move(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= videoNames.length ||
        newIndex < 0 ||
        newIndex >= videoNames.length) {
      return this;
    }
    final reordered = List<String>.of(videoNames);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    return copyWith(videoNames: List.unmodifiable(reordered));
  }
}
