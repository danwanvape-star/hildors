import '../community/community_content.dart';

class PackageVideo {
  const PackageVideo(
      {required this.id,
      required this.title,
      required this.source,
      required this.durationSeconds,
      this.thumbnail,
      this.asset = true});
  final bool asset;
  final String id, title, source;
  final int durationSeconds;
  final String? thumbnail;
}

class CharacterVideoPackage {
  const CharacterVideoPackage(
      {required this.id,
      required this.title,
      required this.videos,
      this.cover,
      this.description = '',
      this.credit = '',
      this.totalVideos,
      this.downloaded = false});
  final String description, credit;
  final int? totalVideos;
  final bool downloaded;
  final String id, title;
  final List<PackageVideo> videos;
  final String? cover;
}

// These are existing playable demos, not invented clips for original characters.
final officialVideoPackages = communityPreviewItems
    .where((item) => item.previewAsset != null)
    .map((item) =>
        CharacterVideoPackage(id: item.id, title: item.title, videos: [
          PackageVideo(
              id: '${item.id}:main',
              title: '展示视频',
              source: item.previewAsset!,
              durationSeconds: item.durationSeconds,
              thumbnail: item.thumbnailAsset),
        ]))
    .toList(growable: false);

class PackageVideoSelection {
  const PackageVideoSelection(this.package, this.video);
  final CharacterVideoPackage package;
  final PackageVideo video;
  String get key =>
      '${package.downloaded ? 'local/' : ''}${package.id}/${video.id}';
}
