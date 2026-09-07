enum CommunityLicense { personalUse, commercialUse, publicDomain }

enum CommunityRightsStatus { pending, verified, removed }

enum DevicePlaylistTarget { local, bluetooth }

enum ContentDownloadStatus { notDownloaded, downloading, downloaded, failed }

class CommunityContent {
  const CommunityContent({
    required this.id,
    required this.title,
    required this.creatorName,
    required this.summary,
    required this.category,
    required this.license,
    required this.rightsStatus,
    required this.playlistTarget,
    required this.supportedModels,
    required this.fileSizeMb,
    required this.durationSeconds,
    required this.version,
    this.previewAsset,
  });

  final String id;
  final String title;
  final String creatorName;
  final String summary;
  final String category;
  final CommunityLicense license;
  final CommunityRightsStatus rightsStatus;
  final DevicePlaylistTarget playlistTarget;
  final List<String> supportedModels;
  final int fileSizeMb;
  final int durationSeconds;
  final String version;
  final String? previewAsset;

  bool get canDownload => rightsStatus == CommunityRightsStatus.verified;
  bool get canInstall => canDownload;
}

const communityPreviewItems = <CommunityContent>[
  CommunityContent(
    id: 'hildors_demo_01',
    title: 'HILDORS 全息展示 01',
    creatorName: 'HILDORS Demo',
    summary: '为全息座舱优化的横屏角色展示，可在手机端直接预览。',
    category: '角色',
    license: CommunityLicense.personalUse,
    rightsStatus: CommunityRightsStatus.verified,
    playlistTarget: DevicePlaylistTarget.local,
    supportedModels: ['P20', 'P11'],
    fileSizeMb: 12,
    durationSeconds: 63,
    version: '1.0',
    previewAsset: 'assets/videos/showcase/showcase_01.mp4',
  ),
  CommunityContent(
    id: 'hildors_demo_02',
    title: 'HILDORS 全息展示 02',
    creatorName: 'HILDORS Demo',
    summary: '适合开机自动播放列表的竖屏角色演示内容。',
    category: '角色',
    license: CommunityLicense.personalUse,
    rightsStatus: CommunityRightsStatus.verified,
    playlistTarget: DevicePlaylistTarget.local,
    supportedModels: ['P20', 'P11'],
    fileSizeMb: 2,
    durationSeconds: 10,
    version: '1.0',
    previewAsset: 'assets/videos/showcase/showcase_02.mp4',
  ),
  CommunityContent(
    id: 'hildors_demo_03',
    title: 'HILDORS 音乐联动 01',
    creatorName: 'HILDORS Demo',
    summary: '连接蓝牙音源后展示的音乐氛围演示内容。',
    category: '音乐',
    license: CommunityLicense.personalUse,
    rightsStatus: CommunityRightsStatus.verified,
    playlistTarget: DevicePlaylistTarget.bluetooth,
    supportedModels: ['P20'],
    fileSizeMb: 1,
    durationSeconds: 10,
    version: '1.0',
    previewAsset: 'assets/videos/showcase/showcase_03.mp4',
  ),
  CommunityContent(
    id: 'hildors_demo_04',
    title: 'HILDORS 音乐联动 02',
    creatorName: 'HILDORS Demo',
    summary: '适合蓝牙播放状态的竖屏全息氛围内容。',
    category: '音乐',
    license: CommunityLicense.personalUse,
    rightsStatus: CommunityRightsStatus.verified,
    playlistTarget: DevicePlaylistTarget.bluetooth,
    supportedModels: ['P20'],
    fileSizeMb: 4,
    durationSeconds: 10,
    version: '1.0',
    previewAsset: 'assets/videos/showcase/showcase_04.mp4',
  ),
];
