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

  bool get canDownload => rightsStatus == CommunityRightsStatus.verified;
  bool get canInstall => canDownload;
}

const communityPreviewItems = <CommunityContent>[
  CommunityContent(
    id: 'preview_pet_01',
    title: '太空犬伙伴',
    creatorName: 'MythBuild 创作者',
    summary: '适合日常陪伴场景的原创宠物角色演示内容。',
    category: '宠物',
    license: CommunityLicense.personalUse,
    rightsStatus: CommunityRightsStatus.verified,
    playlistTarget: DevicePlaylistTarget.local,
    supportedModels: ['P20', 'P11'],
    fileSizeMb: 86,
    durationSeconds: 18,
    version: '1.0',
  ),
  CommunityContent(
    id: 'preview_host_01',
    title: '家庭派对主持人',
    creatorName: 'MythBuild 创作者',
    summary: '适合家庭和朋友聚会的氛围角色内容。',
    category: '派对',
    license: CommunityLicense.personalUse,
    rightsStatus: CommunityRightsStatus.verified,
    playlistTarget: DevicePlaylistTarget.local,
    supportedModels: ['P20'],
    fileSizeMb: 124,
    durationSeconds: 24,
    version: '1.0',
  ),
  CommunityContent(
    id: 'preview_music_01',
    title: '霓虹水母律动',
    creatorName: 'MythBuild 创作者',
    summary: '连接蓝牙音箱后使用的音乐氛围可视化内容。',
    category: '音乐',
    license: CommunityLicense.personalUse,
    rightsStatus: CommunityRightsStatus.verified,
    playlistTarget: DevicePlaylistTarget.bluetooth,
    supportedModels: ['P20'],
    fileSizeMb: 98,
    durationSeconds: 20,
    version: '1.0',
  ),
];
