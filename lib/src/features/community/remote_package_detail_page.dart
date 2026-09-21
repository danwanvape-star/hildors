import 'catalog_localization.dart';
import '../../config/launch_config.dart';
import 'content_governance.dart';
import '../../localization/localization.dart';
import 'catalog_network_image.dart';
import 'package:flutter/material.dart';
import 'content_preview_player.dart';
import 'remote_catalog_repository.dart';

typedef CatalogClipActions = Widget Function(
    RemoteCatalogPackage, RemoteCatalogClip);

class RemotePackageDetailPage extends StatelessWidget {
  const RemotePackageDetailPage(
      {super.key,
      required this.item,
      required this.catalog,
      this.clipActions,
      this.packageActions});
  final RemoteCatalogPackage item;
  final List<RemoteCatalogPackage> catalog;
  final CatalogClipActions? clipActions;
  final Widget Function(RemoteCatalogPackage)? packageActions;

  Widget _credit(BuildContext context) => item.hasPublicCreator
      ? TextButton.icon(
          style: TextButton.styleFrom(
              padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => _CreatorWorksPage(
                  creator: item,
                  catalog: catalog,
                  clipActions: clipActions,
                  packageActions: packageActions))),
          icon: Icon(Icons.person_outline, size: 18),
          label: Text(catalogCredit(context, item)))
      : Text(catalogCredit(context, item));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(item.title)),
        body: ListView(padding: EdgeInsets.all(16), children: [
          LayoutBuilder(builder: (context, constraints) {
            final image = AspectRatio(
                aspectRatio: 1,
                child: _CatalogImage(
                    url: item.format == 'package'
                        ? (item.coverPreviewUrl ??
                            item.coverThumbnailUrl ??
                            item.coverUrl)
                        : item.clips.first.thumbnailUrl,
                    imageKey: ValueKey('package-detail-cover-${item.id}')));
            final intro =
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 8),
              Text(
                item.description.isEmpty ? context.l10n.catalogDescriptionMissing : item.description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              _credit(context),
              if (item.tags.isNotEmpty) ...[
                SizedBox(height: 8),
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
                    SizedBox(height: 12),
                    intro
                  ]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 5, child: image),
              SizedBox(width: 16),
              Expanded(flex: 6, child: intro)
            ]);
          }),
          SizedBox(height: 24),
          if (LaunchConfig.usFree) ContentGovernanceActions(
            packageId: item.id,
            creatorId: item.hasPublicCreator ? item.creatorId : null,
            onBlocked: (_) => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          if (packageActions != null) packageActions!(item),
          Text(item.format == 'package' ? context.l10n.catalogPackVideos : context.l10n.catalogVideo,
              style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 12),
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
                                                      EdgeInsets.all(16),
                                                  children: [
                                                    if (clip.previewUrl != null)
                                                      ContentPreviewPlayer(
                                                          assetPath: null,
                                                          autoPlay: true,
                                                          networkUrl:
                                                              clip.previewUrl)
                                                    else
                                                      Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  32),
                                                          child:
                                                              Text(context.l10n.catalogNoPreview)),
                                                    SizedBox(height: 12),
                                                    _ExpandableStory(
                                                        story:
                                                            item.description),
                                                    SizedBox(height: 12),
                                                    Text(clip.title),
                                                    Text(catalogCredit(context, item)),
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
                                                      url: clip.thumbnailUrl),
                                                  Center(
                                                      child: Icon(
                                                          Icons
                                                              .play_circle_outline,
                                                          size: 38)),
                                                ])),
                                        Padding(
                                            padding: EdgeInsets.all(10),
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(clip.title,
                                                      maxLines: 2,
                                                      overflow: TextOverflow
                                                          .ellipsis),
                                                  SizedBox(height: 4),
                                                  Text(
                                                      clip.durationSeconds ==
                                                              null
                                                          ? context.l10n.catalogDurationUnknown
                                                          : context.l10n.catalogSeconds(clip.durationSeconds!.toStringAsFixed(1)),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall),
                                                ])),
                                      ])))),
                  ])),
        ]),
      );
}

class _ExpandableStory extends StatefulWidget {
  const _ExpandableStory({required this.story});

  final String story;

  @override
  State<_ExpandableStory> createState() => _ExpandableStoryState();
}

class _ExpandableStoryState extends State<_ExpandableStory> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final story = widget.story.trim();
    if (story.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(context.l10n.catalogStoryMissing),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.catalogStory, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            Text(
              story,
              key: Key('content-story'),
              maxLines: expanded ? null : 4,
              overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            TextButton(
              onPressed: () => setState(() => expanded = !expanded),
              child: Text(expanded ? context.l10n.catalogStoryCollapse : context.l10n.catalogStoryExpand),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorWorksPage extends StatelessWidget {
  const _CreatorWorksPage(
      {required this.creator,
      required this.catalog,
      this.clipActions,
      this.packageActions});
  final RemoteCatalogPackage creator;
  final List<RemoteCatalogPackage> catalog;
  final CatalogClipActions? clipActions;
  final Widget Function(RemoteCatalogPackage)? packageActions;
  @override
  Widget build(BuildContext context) {
    final works = catalog
        .where((item) =>
            item.hasPublicCreator && item.creatorId == creator.creatorId)
        .toList();
    return Scaffold(
        appBar: AppBar(title: Text(context.l10n.catalogCreatorSpace(catalogCredit(context, creator)))),
        body: ListView(padding: EdgeInsets.all(16), children: [
          Icon(Icons.account_circle_outlined, size: 56),
          Center(
              child: Text(catalogCredit(context, creator),
                  style: Theme.of(context).textTheme.titleLarge)),
          SizedBox(height: 8),
          Center(child: Text(context.l10n.catalogPublished(works.length))),
          SizedBox(height: 20),
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
                                                  clipActions: clipActions,
                                                  packageActions:
                                                      packageActions))),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AspectRatio(
                                            aspectRatio: 1,
                                            child: _CatalogImage(
                                                url: item.format == 'package'
                                                    ? (item.coverThumbnailUrl ??
                                                        item.coverUrl)
                                                    : item.clips.first
                                                        .thumbnailUrl)),
                                        Padding(
                                            padding: EdgeInsets.all(10),
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
  const _CatalogImage({this.url, this.imageKey});
  final String? url;
  final Key? imageKey;
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
          color: Color(0xff101d2c),
          child: CatalogNetworkImage(url: url, imageKey: imageKey)));
}
