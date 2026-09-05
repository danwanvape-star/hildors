import '../device/p20_command_session.dart';
import '../device/p20_device_client.dart';
import 'experience_pack_manifest.dart';

class ExperienceResult {
  const ExperienceResult({
    required this.id,
    required this.title,
    required this.deviceVideo,
    this.description = '',
  });

  final String id;
  final String title;
  final String deviceVideo;
  final String description;
}

enum ProjectionOutcome { phoneOnly, missingMaterial, projected }

class ExperiencePackStatus {
  const ExperiencePackStatus({
    required this.deviceConnected,
    required this.totalFiles,
    required this.missingFiles,
  });

  final bool deviceConnected;
  final int totalFiles;
  final List<String> missingFiles;

  int get availableFiles => totalFiles - missingFiles.length;
  bool get installed => deviceConnected && missingFiles.isEmpty;
  double get progress => totalFiles == 0 ? 1 : availableFiles / totalFiles;
}

bool hasDeviceVideo(Iterable<String> fileNames, String target) {
  final normalizedTarget = target.trim().toLowerCase();
  return fileNames.any((name) => name.trim().toLowerCase() == normalizedTarget);
}

abstract interface class ProjectionService {
  bool get deviceConnected;
  Future<ProjectionOutcome> present(ExperienceResult result);
  Future<ExperiencePackStatus> inspectPack(
    ExperiencePackManifest manifest, {
    bool forceRefresh = false,
  });
}

class P20ProjectionService implements ProjectionService {
  P20ProjectionService(this.client, this.session);

  static const _catalogLifetime = Duration(seconds: 30);

  final P20DeviceClient client;
  final P20CommandSession session;
  Set<String>? _availableVideos;
  DateTime? _catalogLoadedAt;

  @override
  bool get deviceConnected => client.isConnected;

  @override
  Future<ProjectionOutcome> present(ExperienceResult result) async {
    if (!deviceConnected) return ProjectionOutcome.phoneOnly;
    final videos = await _loadVideoCatalog();
    if (!hasDeviceVideo(videos, result.deviceVideo)) {
      return ProjectionOutcome.missingMaterial;
    }
    await session.playVideo(result.deviceVideo);
    return ProjectionOutcome.projected;
  }

  @override
  Future<ExperiencePackStatus> inspectPack(
    ExperiencePackManifest manifest, {
    bool forceRefresh = false,
  }) async {
    if (!deviceConnected) {
      return ExperiencePackStatus(
        deviceConnected: false,
        totalFiles: manifest.files.length,
        missingFiles: manifest.files.map((file) => file.path).toList(),
      );
    }
    if (forceRefresh) invalidateVideoCatalog();
    final videos = await _loadVideoCatalog();
    return ExperiencePackStatus(
      deviceConnected: true,
      totalFiles: manifest.files.length,
      missingFiles: manifest.missingFiles(videos),
    );
  }

  Future<Set<String>> _loadVideoCatalog() async {
    final loadedAt = _catalogLoadedAt;
    final cached = _availableVideos;
    if (cached != null &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < _catalogLifetime) {
      return cached;
    }
    final videos = await session.queryVideos();
    final names = videos.map((video) => video.fileName).toSet();
    _availableVideos = names;
    _catalogLoadedAt = DateTime.now();
    return names;
  }

  void invalidateVideoCatalog() {
    _availableVideos = null;
    _catalogLoadedAt = null;
  }
}
