import 'dart:math';

/// Eight ASCII hex characters plus .mp4/.mp3 fit the firmware's 12-byte limit.
/// The device's duplicate-name response must still abort; never overwrite.
String createP20UploadBaseName({Random? random}) {
  final source = random ?? Random.secure();
  return List.generate(
      2, (_) => source.nextInt(65536).toRadixString(16).padLeft(4, '0')).join();
}
