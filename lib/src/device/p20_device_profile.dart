enum P20DeviceKind { unknown, single, dual }

enum P20DevicePreference { auto, single, dual }

/// Capabilities belong to the verified connection, not its Wi-Fi name.
class P20DeviceProfile {
  const P20DeviceProfile.forKind(this.kind);
  final P20DeviceKind kind;
  int get listCount => switch (kind) {
        P20DeviceKind.unknown => 0,
        P20DeviceKind.single => 1,
        P20DeviceKind.dual => 2,
      };
  bool get supportsAudio => kind == P20DeviceKind.dual;
  String get videoExtension => '.mp4';
  int get maxUploadNameBytes => 12;
  int get maxNameBytes => kind == P20DeviceKind.single ? 32 : 61;
  int get chunkSize => 32768;
  bool supportsList(int listId) => listId >= 0 && listId < listCount;
}
