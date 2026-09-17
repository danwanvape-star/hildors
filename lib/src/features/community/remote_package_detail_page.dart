import 'package:flutter/material.dart';
import 'content_preview_player.dart';
import 'remote_catalog_repository.dart';

typedef CatalogClipActions = Widget Function(
    RemoteCatalogPackage, RemoteCatalogClip);

class RemotePackageDetailPage extends StatelessWidget {
  const RemotePackageDetailPage(
      {super.key, required this.item, required this.catalog, this.clipActions});
  final RemoteCatalogPackage item;
  final List<RemoteCatalogPackage> catalog;
  final CatalogClipActions? clipActions;

  Widget _credit(BuildContext context) => item.hasPublicCreator
      ? TextButton.icon(
          style: TextButton.styleFrom(
              padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => _CreatorWorksPage(
                  creator: item, catalog: catalog, clipActions: clipActions))),
          icon: const Icon(Icons.person_outline, size: 18),
          label: Text(item.credit))
      : Text(item.credit);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(item.title)),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          LayoutBuilder(builder: (context, constraints) {
            final image = AspectRatio(
                aspectRatio: 1,
                child: _CatalogImage(
                    url: item.format == 'package'
                        ? item.coverUrl
                        : item.clips.first.thumbnailUrl,
                    imageKey: ValueKey('package-detail-cover-${item.id}')));
            final intro =
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(item.description.isEmpty ? '角色简介待补充' : item.description),
              const SizedBox(height: 8),
              _credit(context),
              if (item.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(item.tags.join(' · '),
                    style: Theme.of(context).textTheme.bodySmall)
              ],
            ]);
            if (constraints.maxWidth < 340 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.4) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 180, child: image),
                    const SizedBox(height: 12),
                    intro
                  ]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 5, child: image),
              const SizedBox(width: 16),
              Expanded(flex: 6, child: intro)
            ]);
          }),
          const SizedBox(height: 24),
          Text(item.format == 'package' ? '包内视频' : '视频',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          LayoutBuilder(
              builder: (context, constraints) =>
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    for (final clip in item.clips)
                      SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: Card(
                              margin: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                  key: ValueKey('clip-${item.id}-${clip.id}'),
                                  onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                          builder: (_) => Scaffold(
                                              appBar: AppBar(
                                                  title: Text(clip.title)),
                                              body: ListView(
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  children: [
                                                    if (clip.previewUrl != null)
                                                      ContentPreviewPlayer(
                                                          assetPath: null,
                                                          autoPlay: true,
                                                          networkUrl:
                                                              clip.previewUrl)
                                                    else
                                                      const Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  32),
                                                          child:
                                                              Text('视频预览暂不可用')),
                                                    const SizedBox(height: 12),
                                                    Text(clip.title),
                                                    Text(item.credit),
                                                    if (clipActions != null)
                                                      clipActions!(item, clip),
                                                  ])))),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AspectRatio(
                                            aspectRatio: 1,
                                            child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  _CatalogImage(
                                                      url: clip.thumbnailUrl,
                                                      showPlaceholder: false),
                                                  const Center(
                                                      child: Icon(
                                                          Icons
                                                              .play_circle_outline,
                                                          size: 38)),
                                                ])),
                                        Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(clip.title,
                                                      maxLines: 2,
                                                      overflow: TextOverflow
                                                          .ellipsis),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                      clip.durationSeconds ==
                                                              null
                                                          ? '时长待确认'
                                                          : '${clip.durationSeconds!.toStringAsFixed(1)} 秒',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall),
                                                ])),
                                      ])))),
                  ])),
        ]),
      );
}

class _CreatorWorksPage extends StatelessWidget {
  const _CreatorWorksPage(
      {required this.creator, required this.catalog, this.clipActions});
  final RemoteCatalogPackage creator;
  final List<RemoteCatalogPackage> catalog;
  final CatalogClipActions? clipActions;
  @override
  Widget build(BuildContext context) {
    final works = catalog
        .where((item) =>
            item.hasPublicCreator && item.creatorId == creator.creatorId)
        .toList();
    return Scaffold(
        appBar: AppBar(title: Text('${creator.credit} 的空间')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Icon(Icons.account_circle_outlined, size: 56),
          Center(
              child: Text(creator.credit,
                  style: Theme.of(context).textTheme.titleLarge)),
          const SizedBox(height: 8),
          Center(child: Text('已发布作品 · ${works.length}')),
          const SizedBox(height: 20),
          LayoutBuilder(
              builder: (context, constraints) =>
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    for (final item in works)
                      SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: Card(
                              margin: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                  onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                          builder: (_) =>
                                              RemotePackageDetailPage(
                                                  item: item,
                                                  catalog: catalog,
                                                  clipActions: clipActions))),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AspectRatio(
                                            aspectRatio: 1,
                                            child: _CatalogImage(
                                                url: item.format == 'package'
                                                    ? item.coverUrl
                                                    : item.clips.first
                                                        .thumbnailUrl)),
                                        Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Text(item.title,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis)),
                                      ])))),
                  ])),
        ]));
  }
}

class _CatalogImage extends StatelessWidget {
  const _CatalogImage({this.url, this.imageKey, this.showPlaceholder = true});
  final String? url;
  final Key? imageKey;
  final bool showPlaceholder;
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
          color: const Color(0xff101d2c),
          child: url == null
              ? (showPlaceholder
                  ? Icon(Icons.image_outlined, key: imageKey, size: 38)
                  : const SizedBox.expand())
              : Image.network(url!,
                  key: imageKey,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => showPlaceholder
                      ? const Center(
                          child: Icon(Icons.broken_image_outlined, size: 38))
                      : const SizedBox.expand())));
}
