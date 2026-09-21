import '../../localization/localization.dart';
import 'dart:async';
import '../../config/launch_config.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'creator_content_repository.dart';
import 'creator_content_media.dart';

typedef CreatorVideoPicker = Future<String?> Function();
typedef CreatorCoverPicker = Future<CreatorPickedCover?> Function();

class CreatorPickedCover {
  const CreatorPickedCover(this.path, this.contentType);

  final String path;
  final String contentType;
}

class CreatorContentPage extends StatefulWidget {
  const CreatorContentPage({
    required this.repository,
    this.videoPicker,
    this.coverPicker,
    super.key,
  });

  final CreatorContentRepository repository;
  final CreatorVideoPicker? videoPicker;
  final CreatorCoverPicker? coverPicker;

  @override
  State<CreatorContentPage> createState() => _CreatorContentPageState();
}

class _CreatorContentPageState extends State<CreatorContentPage> {
  List<CreatorContent> items = const [];
  List<CreatorContentTag> tags = const [];
  bool loading = true;
  CreatorContentCapabilities? capabilities;
  String? error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final values = await Future.wait<Object>([
        widget.repository.loadOwned(),
        widget.repository.loadTags(),
        if (widget.repository is CreatorContentPricingRepository)
          (widget.repository as CreatorContentPricingRepository)
              .loadCapabilities(),
      ]);
      if (!mounted) return;
      setState(() {
        items = values[0] as List<CreatorContent>;
        tags = values[1] as List<CreatorContentTag>;
        capabilities =
            values.length > 2 ? values[2] as CreatorContentCapabilities : null;
        if (capabilities?.canUpload == false) error = '创作者资格尚未通过或已暂停，请返回认证页查看';
      });
    } catch (caught) {
      if (!mounted) return;
      setState(() => error = _creatorContentError(caught));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openEditor([CreatorContent? item]) async {
    final creating = item == null;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreatorContentEditorPage(
          repository: widget.repository,
          availableTags: tags,
          canSetPaid: LaunchConfig.paidPurchases && (capabilities?.canSetPaid ?? false),
          initial: item,
          videoPicker: widget.videoPicker,
          coverPicker: widget.coverPicker,
          tagReloader: () async {
            final loaded = await widget.repository.loadTags();
            if (mounted) tags = loaded;
            return loaded;
          },
        ),
      ),
    );
    if (!mounted) return;
    await _reload();
    if (!mounted || !creating || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.submissionDraftSaved)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.submissionTitle),
          actions: [
            IconButton(
              tooltip: context.l10n.submissionRefresh,
              onPressed: loading ? null : _reload,
              icon: Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: loading || error != null
            ? null
            : FloatingActionButton.extended(
                onPressed: _openEditor,
                icon: Icon(Icons.add),
                label: Text(context.l10n.submissionCreate),
              ),
        body: loading
            ? Center(child: CircularProgressIndicator())
            : error != null
                ? _CreatorContentErrorPanel(message: error!, retry: _reload)
                : items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(context.l10n.submissionEmpty),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView.builder(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, 96),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                key: Key('creator-content-${item.id}'),
                                leading: widget.repository
                                            is CreatorContentMediaRepository &&
                                        item.clips.any((clip) => clip.hasMedia)
                                    ? SizedBox(
                                        width: 88,
                                        child: CreatorContentThumbnail(
                                            key: ValueKey(
                                                'thumbnail-${item.id}'),
                                            item: item,
                                            clip: item.clips.firstWhere(
                                                (clip) => clip.hasMedia),
                                            compact: true,
                                            repository: widget.repository
                                                as CreatorContentMediaRepository))
                                    : Icon(item.format == 'package'
                                        ? Icons.video_collection_outlined
                                        : Icons.smart_display_outlined),
                                title: Text(item.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_submissionLabel(context, item)),
                                    if (item.reviewNote?.trim().isNotEmpty ==
                                        true)
                                      Text(item.reviewNote!.trim()),
                                  ],
                                ),
                                trailing: Icon(Icons.chevron_right),
                                onTap: () => _openEditor(item),
                              ),
                            );
                          },
                        ),
                      ),
      );
}

class CreatorContentEditorPage extends StatefulWidget {
  const CreatorContentEditorPage({
    required this.repository,
    required this.availableTags,
    this.initial,
    this.videoPicker,
    this.coverPicker,
    this.tagReloader,
    this.canSetPaid = false,
    super.key,
  });

  final CreatorContentRepository repository;
  final List<CreatorContentTag> availableTags;
  final bool canSetPaid;
  final CreatorContent? initial;
  final CreatorVideoPicker? videoPicker;
  final CreatorCoverPicker? coverPicker;
  final Future<List<CreatorContentTag>> Function()? tagReloader;

  @override
  State<CreatorContentEditorPage> createState() =>
      _CreatorContentEditorPageState();
}

class _CreatorContentEditorPageState extends State<CreatorContentEditorPage> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final storyController = TextEditingController();
  final clipControllers = <TextEditingController>[];
  final selectedTags = <String>{};
  late List<CreatorContentTag> availableTags;
  CreatorContent? item;
  String format = 'single';
  bool busy = false;

  bool get editable => item?.editable ?? true;

  @override
  void initState() {
    super.initState();
    item = widget.initial;
    availableTags = List.of(widget.availableTags);
    final current = item;
    if (current == null) {
      clipControllers.add(TextEditingController());
    } else {
      titleController.text = current.title;
      storyController.text = current.description;
      format = current.format;
      selectedTags.addAll(current.tags);
      clipControllers.addAll(
        current.clips.map((clip) => TextEditingController(text: clip.title)),
      );
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    storyController.dispose();
    for (final controller in clipControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy || !mounted) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (caught) {
      if (!mounted) return;
      if (caught is CreatorContentException &&
          caught.code == 'INVALID_CONTENT_TAGS' &&
          widget.tagReloader != null) {
        try {
          availableTags = await widget.tagReloader!();
          if (mounted) setState(() {});
        } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_submissionError(context, _creatorContentError(caught)))),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _save() => _run(() async {
        if (!formKey.currentState!.validate()) return;
        final title = titleController.text.trim();
        final story = storyController.text.trim();
        if (item == null) {
          final created = await widget.repository.create(
            title: title,
            format: format,
            tags: selectedTags.toList(growable: false),
            description: story,
            clips: [
              for (var index = 0; index < clipControllers.length; index++)
                CreatorContentClipDraft(
                  id: 'clip-${index + 1}',
                  title: clipControllers[index].text.trim(),
                ),
            ],
          );
          if (!mounted) return;
          item = created;
          Navigator.of(context).pop(true);
        } else {
          item = await widget.repository.updateMetadata(
            item!,
            title: title,
            tags: selectedTags.toList(growable: false),
            description: story,
          );
          if (!mounted) return;
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.submissionUpdated)),
          );
        }
      });

  Future<String?> _pickVideo() async {
    if (widget.videoPicker != null) return widget.videoPicker!();
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['mp4'],
    );
    return result?.path;
  }

  Future<CreatorPickedCover?> _pickCover() async {
    if (widget.coverPicker != null) return widget.coverPicker!();
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    final path = result?.path;
    if (path == null) return null;
    final contentType =
        path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    return CreatorPickedCover(path, contentType);
  }

  Future<void> _uploadClip(CreatorContentClip clip) => _run(() async {
        final path = await _pickVideo();
        if (path == null || !mounted) return;
        item = await widget.repository.uploadClip(
          item!,
          clipId: clip.id,
          filePath: path,
        );
        if (mounted) setState(() {});
      });

  Future<void> _uploadCover() => _run(() async {
        final picked = await _pickCover();
        if (picked == null || !mounted) return;
        item = await widget.repository.uploadCover(
          item!,
          filePath: picked.path,
          contentType: picked.contentType,
        );
        if (mounted) setState(() {});
      });

  Future<void> _inspect(CreatorContentClip clip) => _run(() async {
        item = await widget.repository.inspect(item!, clip.id);
        if (mounted) setState(() {});
      });

  Future<void> _setPrice(CreatorContentClip clip) async {
    final repository = widget.repository;
    if (repository is! CreatorContentPricingRepository) return;
    final controller = TextEditingController(
        text: clip.amountMinor > 0
            ? (clip.amountMinor / 100).toStringAsFixed(2)
            : '');
    var paid = clip.amountMinor > 0 && widget.canSetPaid;
    final priceForm = GlobalKey<FormState>();
    final route = DialogRoute<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
                title: Text(context.l10n.submissionVideoPrice(clip.title)),
                content: Form(
                    key: priceForm,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(value: false, label: Text(context.l10n.submissionFree)),
                          ButtonSegment(value: true, label: Text(context.l10n.submissionPaid))
                        ],
                        selected: {paid},
                        onSelectionChanged: widget.canSetPaid
                            ? (values) =>
                                setDialogState(() => paid = values.single)
                            : null,
                      ),
                      if (paid)
                        TextFormField(
                          key: Key('creator-price-usd'),
                          controller: controller,
                          keyboardType: TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                              labelText: context.l10n.submissionPrice, helperText: context.l10n.submissionDecimals),
                          validator: (value) =>
                              _parseUsdCents(value ?? '') == null
                                  ? context.l10n.submissionInvalidPrice
                                  : null,
                        ),
                      Text(context.l10n.submissionReviewNote),
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(context.l10n.submissionCancel)),
                  FilledButton(
                      onPressed: () {
                        if (paid && !priceForm.currentState!.validate()) return;
                        Navigator.pop(dialogContext,
                            paid ? _parseUsdCents(controller.text) : 0);
                      },
                      child: Text(context.l10n.submissionSavePrice)),
                ],
              )),
    );
    final amount = await Navigator.of(context).push(route);
    unawaited(route.completed.then((_) => controller.dispose()));
    if (amount == null || !mounted) return;
    await _run(() async {
      item = await (repository as CreatorContentPricingRepository)
          .updatePricing(item!, clipId: clip.id, amountMinor: amount);
      if (mounted) setState(() {});
    });
  }

  Future<void> _submit() => _run(() async {
        if (!formKey.currentState!.validate()) return;
        var current = item!;
        final title = titleController.text.trim();
        final story = storyController.text.trim();
        final tags = selectedTags.toList(growable: false);
        if (title != current.title ||
            story != current.description ||
            !_sameTags(tags, current.tags)) {
          current = await widget.repository.updateMetadata(
            current,
            title: title,
            tags: tags,
            description: story,
          );
          item = current;
          if (mounted) setState(() {});
        }
        item = await widget.repository.submit(current);
        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.submissionSubmitted)),
        );
      });

  void _addClip() =>
      setState(() => clipControllers.add(TextEditingController()));

  void _removeClip(int index) {
    if (clipControllers.length == 1) return;
    final controller = clipControllers.removeAt(index);
    controller.dispose();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final current = item;
    final legacyTags = selectedTags.where(
        (name) => !availableTags.any((tag) => tag.name == name && tag.active));
    final selectableTags = [
      ...availableTags.where((tag) => tag.active),
      ...legacyTags.map(
        (name) =>
            CreatorContentTag(id: 'legacy-$name', name: name, active: false),
      ),
    ];
    final canSubmit = current != null &&
        current.editable &&
        current.clips.every((clip) => clip.inspectionPassed) &&
        (current.format != 'package' || current.hasCover);
    return Scaffold(
      appBar: AppBar(title: Text(current == null ? context.l10n.submissionCreate : current.title)),
      body: AbsorbPointer(
        absorbing: busy,
        child: Form(
          key: formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              if (busy) LinearProgressIndicator(),
              if (editable) ...[
                Text(widget.canSetPaid
                    ? context.l10n.submissionPartnerNote
                    : context.l10n.submissionFreeNote),
                SizedBox(height: 20),
              ],
              if (current != null) ...[
                Wrap(spacing: 8, runSpacing: 8, children: [
                  Chip(label: Text(_submissionLabel(context, current))),
                  Chip(
                      label:
                          Text(current.format == 'package' ? context.l10n.submissionCharacterPackage : context.l10n.submissionSingleVideo)),
                ]),
                SizedBox(height: 16),
                if (current.reviewNote?.trim().isNotEmpty == true)
                  Card(
                    margin: EdgeInsets.only(bottom: 24),
                    color: current.submissionStatus == 'rejected'
                        ? Theme.of(context).colorScheme.errorContainer
                        : Theme.of(context).colorScheme.surfaceContainerHigh,
                    child: ListTile(
                      leading: Icon(Icons.rate_review_outlined),
                      title: Text(current.submissionStatus == 'rejected'
                          ? context.l10n.submissionRejectedReason
                          : context.l10n.submissionReviewFeedback),
                      subtitle: Text(current.reviewNote!.trim()),
                    ),
                  ),
              ],
              if (!editable && current != null) ...[
                _CreatorContentSummary(item: current),
                SizedBox(height: 24),
              ],
              if (editable) ...[
                TextFormField(
                  key: Key('creator-content-title'),
                  controller: titleController,
                  enabled: editable,
                  maxLength: 120,
                  decoration: InputDecoration(labelText: context.l10n.submissionName),
                  validator: (value) =>
                      value?.trim().isEmpty == true ? context.l10n.submissionNameRequired : null,
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  itemHeight: null,
                  key: Key('creator-content-format'),
                  initialValue: format,
                  decoration: InputDecoration(labelText: context.l10n.submissionFormat),
                  items: [
                    DropdownMenuItem(value: 'single', child: Text(context.l10n.submissionSingle)),
                    DropdownMenuItem(value: 'package', child: Text(context.l10n.submissionPackage)),
                  ],
                  onChanged: !editable || current != null
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            format = value;
                            if (format == 'single') {
                              while (clipControllers.length > 1) {
                                clipControllers.removeLast().dispose();
                              }
                            }
                          });
                        },
                ),
                SizedBox(height: 16),
                Text(context.l10n.submissionTags, style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                if (selectableTags.isEmpty)
                  Text(context.l10n.submissionNoTags)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in selectableTags)
                        FilterChip(
                          label:
                              Text(tag.active ? tag.displayName(context.l10n.localeName) : context.l10n.submissionLegacyTag(tag.displayName(context.l10n.localeName))),
                          selected: selectedTags.contains(tag.name),
                          onSelected: !editable
                              ? null
                              : (selected) => setState(() {
                                    if (selected && tag.active) {
                                      selectedTags.add(tag.name);
                                    } else {
                                      selectedTags.remove(tag.name);
                                    }
                                  }),
                        ),
                    ],
                  ),
                SizedBox(height: 16),
                TextFormField(
                  key: Key('creator-content-story'),
                  controller: storyController,
                  enabled: editable,
                  minLines: 4,
                  maxLines: 10,
                  maxLength: 10000,
                  decoration: InputDecoration(
                    labelText: context.l10n.submissionStory,
                    alignLabelWithHint: true,
                  ),
                  validator: (value) =>
                      value?.trim().isEmpty == true ? context.l10n.submissionStoryRequired : null,
                ),
                SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(context.l10n.submissionVideos,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  if (current == null && format == 'package')
                    TextButton.icon(
                      onPressed: _addClip,
                      icon: Icon(Icons.add),
                      label: Text(context.l10n.submissionAddVideo),
                    ),
                ],
              ),
              if (current == null)
                for (var index = 0; index < clipControllers.length; index++)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      key: Key('creator-clip-title-$index'),
                      controller: clipControllers[index],
                      enabled: editable && current == null,
                      decoration: InputDecoration(
                        labelText: context.l10n.submissionVideoName(index + 1),
                        suffixIcon: current == null &&
                                clipControllers.length > 1
                            ? IconButton(
                                tooltip: context.l10n.submissionRemoveVideo,
                                onPressed: () => _removeClip(index),
                                icon: Icon(Icons.remove_circle_outline),
                              )
                            : null,
                      ),
                      validator: (value) =>
                          value?.trim().isEmpty == true ? context.l10n.submissionVideoNameRequired : null,
                    ),
                  ),
              if (current == null)
                FilledButton.icon(
                  onPressed: busy ? null : _save,
                  icon: Icon(Icons.save_outlined),
                  label: Text(context.l10n.submissionSaveDraft),
                )
              else ...[
                if (editable)
                  FilledButton.icon(
                    onPressed: busy ? null : _save,
                    icon: Icon(Icons.save_outlined),
                    label: Text(context.l10n.submissionSaveInfo),
                  ),
                SizedBox(height: 16),
                if (current.format == 'package')
                  Card(
                    child: ListTile(
                      leading: Icon(current.hasCover
                          ? Icons.check_circle_outline
                          : Icons.image_outlined),
                      title: Text(current.hasCover ? context.l10n.submissionCoverUploaded : context.l10n.submissionCover),
                      subtitle: Text(context.l10n.submissionCoverTypes),
                      trailing: editable
                          ? TextButton(
                              onPressed: _uploadCover,
                              child: Text(current.hasCover ? context.l10n.submissionReplace : context.l10n.submissionUpload),
                            )
                          : null,
                    ),
                  ),
                for (final clip in current.clips)
                  Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (clip.hasMedia &&
                              widget.repository
                                  is CreatorContentMediaRepository) ...[
                            CreatorContentThumbnail(
                                key: ValueKey('thumbnail-${clip.id}'),
                                item: current,
                                clip: clip,
                                repository: widget.repository
                                    as CreatorContentMediaRepository),
                            SizedBox(height: 12),
                          ],
                          Text(clip.title,
                              style: Theme.of(context).textTheme.titleMedium),
                          SizedBox(height: 4),
                          Text(_clipStatus(context, clip)),
                          Text(clip.amountMinor == 0
                              ? context.l10n.submissionFree
                              : 'USD ${(clip.amountMinor / 100).toStringAsFixed(2)}'),
                          if (editable &&
                              (widget.canSetPaid || clip.amountMinor > 0) &&
                              widget.repository
                                  is CreatorContentPricingRepository)
                            TextButton(
                              onPressed: () => _setPrice(clip),
                              child: Text(widget.canSetPaid ? context.l10n.submissionSetPrice : context.l10n.submissionMakeFree),
                            ),
                          if (editable) ...[
                            SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              OutlinedButton.icon(
                                onPressed: () => _uploadClip(clip),
                                icon: Icon(Icons.upload_file_outlined),
                                label:
                                    Text(clip.hasMedia ? context.l10n.submissionReplaceMp4 : context.l10n.submissionUploadMp4),
                              ),
                              if (clip.hasMedia)
                                FilledButton.tonalIcon(
                                  onPressed: () => _inspect(clip),
                                  icon: Icon(Icons.fact_check_outlined),
                                  label: Text(context.l10n.submissionCheckVideo),
                                ),
                            ]),
                          ],
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 12),
                if (editable)
                  FilledButton.icon(
                    onPressed: canSubmit ? _submit : null,
                    icon: Icon(Icons.send_outlined),
                    label: Text(current.submissionStatus == 'rejected'
                        ? context.l10n.submissionResubmit
                        : context.l10n.submissionSubmit),
                  ),
                if (editable && !canSubmit)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(context.l10n.submissionRequirements),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatorContentSummary extends StatelessWidget {
  const _CreatorContentSummary({required this.item});
  final CreatorContent item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.submissionInfo, style: theme.textTheme.titleMedium),
            SizedBox(height: 16),
            Text(item.title, style: theme.textTheme.headlineSmall),
            if (item.tags.isNotEmpty) ...[
              SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 4, children: [
                for (final tag in item.tags)
                  Chip(label: Text(tag), visualDensity: VisualDensity.compact),
              ]),
            ],
            SizedBox(height: 20),
            Text(context.l10n.submissionStory, style: theme.textTheme.titleSmall),
            SizedBox(height: 8),
            Text(item.description.isEmpty ? context.l10n.submissionNoStory : item.description,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
          ],
        ),
      ),
    );
  }
}

class _CreatorContentErrorPanel extends StatelessWidget {
  const _CreatorContentErrorPanel({required this.message, required this.retry});

  final String message;
  final Future<void> Function() retry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 42),
              SizedBox(height: 12),
              Text(_submissionError(context, message), textAlign: TextAlign.center),
              SizedBox(height: 12),
              OutlinedButton(onPressed: retry, child: Text(context.l10n.submissionRetry)),
            ],
          ),
        ),
      );
}

String _submissionLabel(BuildContext context, CreatorContent item) => switch (item.submissionStatus) {
      'pending' => context.l10n.submissionPending,
      'approved' => item.status == 'published' ? context.l10n.submissionPublished : context.l10n.submissionApproved,
      'rejected' => context.l10n.submissionRejected,
      _ => context.l10n.submissionDraft,
    };

String _clipStatus(BuildContext context, CreatorContentClip clip) {
  if (!clip.hasMedia) return context.l10n.submissionNoMedia;
  return switch (clip.inspectionStatus) {
    'checked' => context.l10n.submissionChecked,
    'processing' => context.l10n.submissionProcessing,
    'rejected' || 'failed' => context.l10n.submissionFailed,
    _ => context.l10n.submissionWaiting,
  };
}

String _creatorContentError(Object error) => error is CreatorContentException
    ? error.sessionExpired ? 'SESSION_EXPIRED' : error.code ?? error.message
    : error is FormatException
        ? '服务返回了无法识别的投稿数据'
        : '投稿数据暂时无法加载，请稍后重试';

bool _sameTags(List<String> left, List<String> right) =>
    left.length == right.length && left.toSet().containsAll(right);

int? _parseUsdCents(String value) {
  final text = value.trim();
  if (!RegExp(r'^\d{1,7}(?:\.\d{1,2})?$').hasMatch(text)) return null;
  final parts = text.split('.');
  final cents = int.parse(parts[0]) * 100 +
      int.parse(parts.length == 2 ? parts[1].padRight(2, '0') : '0');
  return cents > 0 && cents <= 99999999 ? cents : null;
}

String _submissionError(BuildContext context, String message) => switch(message) {
  '创作者资格尚未通过或已暂停，请返回认证页查看' => context.l10n.submissionApprovalError,
  '服务返回了无法识别的投稿数据' => context.l10n.submissionDataError,
  '投稿数据暂时无法加载，请稍后重试' => context.l10n.submissionLoadError,
  'SESSION_EXPIRED' || '登录已失效，请重新认证创作者身份' => context.l10n.submissionSessionError,
  'CREATOR_APPROVAL_REQUIRED' || '仅已认证且未停用的创作者可以投稿' => context.l10n.submissionAccessError,
  'CREATOR_PAID_NOT_ALLOWED' || '仅签约伙伴可设置付费视频，请改为免费后送审' => context.l10n.submissionPaidError,
  'INVALID_PRICING' || '价格无效，请输入最多两位小数的美元金额' => context.l10n.submissionPriceError,
  'VERSION_OR_STATE_CONFLICT' || '投稿状态已经变化，请刷新后重试' => context.l10n.submissionConflictError,
  'MEDIA_REVIEW_REQUIRED' || '请先上传并检查全部视频' => context.l10n.submissionMediaError,
  'PACKAGE_COVER_REQUIRED' || '内容包需要先上传封面' => context.l10n.submissionCoverError,
  'INVALID_CONTENT_TAGS' || '所选标签已失效，请刷新后重新选择' => context.l10n.submissionTagError,
  '服务暂时不可用，请稍后重试' => context.l10n.submissionServerError,
  '操作未完成，请检查内容后重试' => context.l10n.submissionRequestError,
  '账号已切换，请刷新投稿' => context.l10n.submissionAccountChanged,
  '视频尚未上传或预览服务不可用' => context.l10n.submissionPreviewError,
  _ => context.l10n.errorGeneric,
};
