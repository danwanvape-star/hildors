enum CommunityLicense { personalUse, commercialUse, publicDomain }

enum CommunityRightsStatus { pending, verified, removed }

enum DevicePlaylistTarget { local, bluetooth }

class CommunityContent {
  const CommunityContent({
    required this.id,
    required this.title,
    required this.creatorName,
    required this.summary,
    required this.license,
    required this.rightsStatus,
    required this.playlistTarget,
    required this.supportedModels,
    required this.fileSizeMb,
    required this.version,
  });

  final String id;
  final String title;
  final String creatorName;
  final String summary;
  final CommunityLicense license;
  final CommunityRightsStatus rightsStatus;
  final DevicePlaylistTarget playlistTarget;
  final List<String> supportedModels;
  final int fileSizeMb;
  final String version;

  bool get canInstall => rightsStatus == CommunityRightsStatus.verified;
}

const communityPreviewItems = <CommunityContent>[
  CommunityContent(
    id: 'preview_pet_01',
    title: '太空犬伙伴',
    creatorName: '示例创作者',
    summary: '原创宠物角色演示内容，用于展示未来社区详情与授权流程。',
    license: CommunityLicense.personalUse,
    rightsStatus: CommunityRightsStatus.verified,
    playlistTarget: DevicePlaylistTarget.local,
    supportedModels: ['P20', 'P11'],
    fileSizeMb: 86,
    version: '1.0',
  ),
  CommunityContent(
    id: 'preview_host_01',
    title: '家庭派对主持人',
    creatorName: '示例创作者',
    summary: '原创聚会氛围角色演示内容，适用于家庭与朋友聚会。',
    license: CommunityLicense.personalUse,
    rightsStatus: CommunityRightsStatus.verified,
    playlistTarget: DevicePlaylistTarget.local,
    supportedModels: ['P20'],
    fileSizeMb: 124,
    version: '1.0',
  ),
];
