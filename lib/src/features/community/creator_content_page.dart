import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'creator_content_repository.dart';

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
      ]);
      if (!mounted) return;
      setState(() {
        items = values[0] as List<CreatorContent>;
        tags = values[1] as List<CreatorContentTag>;
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
      const SnackBar(content: Text('已保存草稿，可继续上传视频并送审。')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('原创内容投稿'),
          actions: [
            IconButton(
              tooltip: '刷新投稿',
              onPressed: loading ? null : _reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: loading || error != null
            ? null
            : FloatingActionButton.extended(
                onPressed: _openEditor,
                icon: const Icon(Icons.add),
                label: const Text('创建投稿'),
              ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? _CreatorContentErrorPanel(message: error!, retry: _reload)
                : items.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('还没有投稿。创建草稿后上传视频，检查通过即可送审。'),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                key: Key('creator-content-${item.id}'),
                                leading: Icon(item.format == 'package'
                                    ? Icons.video_collection_outlined
                                    : Icons.smart_display_outlined),
                                title: Text(item.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_submissionLabel(item)),
                                    if (item.reviewNote?.trim().isNotEmpty ==
                                        true)
                                      Text(item.reviewNote!.trim()),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
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
    super.key,
  });

  final CreatorContentRepository repository;
  final List<CreatorContentTag> availableTags;
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
        SnackBar(content: Text(_creatorContentError(caught))),
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
            const SnackBar(content: Text('投稿信息已更新')),
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
    final contentType = path.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';
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
          const SnackBar(content: Text('已提交平台审核，审核期间不可修改。')),
        );
      });

  void _addClip() => setState(() => clipControllers.add(TextEditingController()));

  void _removeClip(int index) {
    if (clipControllers.length == 1) return;
    final controller = clipControllers.removeAt(index);
    controller.dispose();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final current = item;
    final legacyTags = selectedTags.where((name) => !availableTags
        .any((tag) => tag.name == name && tag.active));
    final selectableTags = [
      ...availableTags.where((tag) => tag.active),
      ...legacyTags.map(
        (name) => CreatorContentTag(id: 'legacy-$name', name: name, active: false),
      ),
    ];
    final canSubmit = current != null &&
        current.editable &&
        current.clips.every((clip) => clip.inspectionPassed) &&
        (current.format != 'package' || current.hasCover);
    return Scaffold(
      appBar: AppBar(title: Text(current == null ? '创建投稿' : current.title)),
      body: AbsorbPointer(
        absorbing: busy,
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              if (busy) const LinearProgressIndicator(),
              if (current != null) ...[
                Wrap(spacing: 8, runSpacing: 8, children: [
                  Chip(label: Text(_submissionLabel(current))),
                  Chip(label: Text('版本 ${current.version}')),
                ]),
                if (current.reviewNote?.trim().isNotEmpty == true)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: ListTile(
                      leading: const Icon(Icons.rate_review_outlined),
                      title: const Text('退回原因'),
                      subtitle: Text(current.reviewNote!.trim()),
                    ),
                  ),
              ],
              TextFormField(
                key: const Key('creator-content-title'),
                controller: titleController,
                enabled: editable,
                maxLength: 120,
                decoration: const InputDecoration(labelText: '标题'),
                validator: (value) => value?.trim().isEmpty == true ? '请填写标题' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('creator-content-format'),
                initialValue: format,
                decoration: const InputDecoration(labelText: '内容形式'),
                items: const [
                  DropdownMenuItem(value: 'single', child: Text('单个视频')),
                  DropdownMenuItem(value: 'package', child: Text('视频包')),
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
              const SizedBox(height: 16),
              Text('共享标签', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (selectableTags.isEmpty)
                const Text('平台暂未开放内容标签')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in selectableTags)
                      FilterChip(
                        label: Text(tag.active ? tag.name : '${tag.name}（旧标签）'),
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
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('creator-content-story'),
                controller: storyController,
                enabled: editable,
                minLines: 4,
                maxLines: 10,
                maxLength: 10000,
                decoration: const InputDecoration(
                  labelText: '背景故事',
                  alignLabelWithHint: true,
                ),
                validator: (value) =>
                    value?.trim().isEmpty == true ? '请填写背景故事' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text('视频清单',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  if (current == null && format == 'package')
                    TextButton.icon(
                      onPressed: _addClip,
                      icon: const Icon(Icons.add),
                      label: const Text('添加视频'),
                    ),
                ],
              ),
              for (var index = 0; index < clipControllers.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    key: Key('creator-clip-title-$index'),
                    controller: clipControllers[index],
                    enabled: editable && current == null,
                    decoration: InputDecoration(
                      labelText: '视频 ${index + 1} 标题',
                      suffixIcon: current == null && clipControllers.length > 1
                          ? IconButton(
                              tooltip: '移除视频',
                              onPressed: () => _removeClip(index),
                              icon: const Icon(Icons.remove_circle_outline),
                            )
                          : null,
                    ),
                    validator: (value) =>
                        value?.trim().isEmpty == true ? '请填写视频标题' : null,
                  ),
                ),
              if (current == null)
                FilledButton.icon(
                  onPressed: busy ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('保存草稿'),
                )
              else ...[
                if (editable)
                  FilledButton.icon(
                    onPressed: busy ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('保存信息'),
                  ),
                const SizedBox(height: 16),
                if (current.format == 'package')
                  Card(
                    child: ListTile(
                      leading: Icon(current.hasCover
                          ? Icons.check_circle_outline
                          : Icons.image_outlined),
                      title: Text(current.hasCover ? '封面已上传' : '内容包封面'),
                      subtitle: const Text('支持 JPG 或 PNG'),
                      trailing: editable
                          ? TextButton(
                              onPressed: _uploadCover,
                              child: Text(current.hasCover ? '替换' : '上传'),
                            )
                          : null,
                    ),
                  ),
                for (final clip in current.clips)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clip.title,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(_clipStatus(clip)),
                          if (editable) ...[
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              OutlinedButton.icon(
                                onPressed: () => _uploadClip(clip),
                                icon: const Icon(Icons.upload_file_outlined),
                                label: Text(clip.hasMedia ? '替换 MP4' : '上传 MP4'),
                              ),
                              if (clip.hasMedia)
                                FilledButton.tonalIcon(
                                  onPressed: () => _inspect(clip),
                                  icon: const Icon(Icons.fact_check_outlined),
                                  label: const Text('检查视频'),
                                ),
                            ]),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (editable)
                  FilledButton.icon(
                    onPressed: canSubmit ? _submit : null,
                    icon: const Icon(Icons.send_outlined),
                    label: Text(current.submissionStatus == 'rejected'
                        ? '重新提交审核'
                        : '提交审核'),
                  ),
                if (editable && !canSubmit)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('提交前需完成全部视频检查；视频包还需上传封面。'),
                  ),
              ],
            ],
          ),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 42),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: retry, child: const Text('重试')),
            ],
          ),
        ),
      );
}

String _submissionLabel(CreatorContent item) => switch (item.submissionStatus) {
      'pending' => '审核中',
      'approved' => item.status == 'published' ? '已发布' : '审核通过，等待平台发布',
      'rejected' => '退回修改',
      _ => '草稿',
    };

String _clipStatus(CreatorContentClip clip) {
  if (!clip.hasMedia) return '尚未上传视频';
  return switch (clip.inspectionStatus) {
    'checked' => '视频检查通过',
    'processing' => '视频检查中',
    'rejected' || 'failed' => '视频检查未通过，请替换后重试',
    _ => '已上传，等待检查',
  };
}

String _creatorContentError(Object error) => error is CreatorContentException
    ? error.message
    : error is FormatException
        ? '服务返回了无法识别的投稿数据'
        : '投稿数据暂时无法加载，请稍后重试';

bool _sameTags(List<String> left, List<String> right) =>
    left.length == right.length && left.toSet().containsAll(right);
