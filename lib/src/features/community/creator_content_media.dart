import 'package:flutter/material.dart';
import '../../localization/localization.dart';

import 'content_preview_player.dart';
import 'creator_content_repository.dart';

/// A thumbnail fetch never initializes a video player or downloads the MP4.
class CreatorContentThumbnail extends StatefulWidget {
  const CreatorContentThumbnail(
      {required this.item,
      required this.clip,
      required this.repository,
      this.compact = false,
      super.key});
  final CreatorContent item;
  final CreatorContentClip clip;
  final CreatorContentMediaRepository repository;
  final bool compact;

  @override
  State<CreatorContentThumbnail> createState() =>
      _CreatorContentThumbnailState();
}

class _CreatorContentThumbnailState extends State<CreatorContentThumbnail> {
  late Future<CreatorContentMediaAccess> access;
  bool _opening = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    access = widget.repository.mediaAccess(widget.item, widget.clip);
  }

  @override
  void didUpdateWidget(covariant CreatorContentThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.version != widget.item.version ||
        oldWidget.clip.mediaId != widget.clip.mediaId ||
        oldWidget.clip.id != widget.clip.id ||
        oldWidget.item.id != widget.item.id ||
        oldWidget.repository != widget.repository) {
      _load();
    }
  }

  Future<void> _play() async {
    if (_opening) return;
    _opening = true;
    // Resolve again at play time so a stale thumbnail cannot keep an old token.
    try {
      final media =
          await widget.repository.mediaAccess(widget.item, widget.clip);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => Scaffold(
                appBar: AppBar(title: Text(widget.clip.title)),
                body: ContentPreviewPlayer(
                    assetPath: null,
                    networkUrl: media.preview.toString(),
                    httpHeaders: media.headers,
                    refreshHttpHeaders: () async => (await widget.repository
                            .mediaAccess(widget.item, widget.clip,
                                refreshIdentity: true))
                        .headers,
                    autoPlay: true),
              )));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.creatorMediaOpenFailed)));
      }
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: context.l10n.creatorMediaPreviewLabel(widget.clip.title),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: InkWell(
                onTap: _play,
                child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(fit: StackFit.expand, children: [
                      FutureBuilder<CreatorContentMediaAccess>(
                          future: access,
                          builder: (context, snapshot) {
                            final media = snapshot.data;
                            if (media == null) {
                              return const Center(
                                  child: Icon(Icons.video_library_outlined));
                            }
                            return Image.network(media.thumbnail.toString(),
                                headers: media.headers,
                                fit: BoxFit.cover,
                                cacheWidth: widget.compact ? 240 : 720,
                                errorBuilder: (_, __, ___) => Center(
                                    child: widget.compact
                                        ? const Icon(Icons.videocam_outlined)
                                        : Text(context.l10n.creatorMediaThumbnailPending)));
                          }),
                      Align(
                          alignment: widget.compact
                              ? Alignment.center
                              : Alignment.bottomRight,
                          child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: DecoratedBox(
                                  decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      child: widget.compact
                                          ? const Icon(Icons.play_arrow_rounded,
                                              color: Colors.white, size: 20)
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                  Icon(Icons.play_arrow_rounded,
                                                      color: Colors.white),
                                                  SizedBox(width: 4),
                                                  Text(context.l10n.creatorMediaPreview,
                                                      style: TextStyle(
                                                          color: Colors.white))
                                                ]))))),
                    ]))),
          ),
        ),
      );
}
