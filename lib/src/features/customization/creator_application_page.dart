import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'cloud_business_intake.dart';
import 'cloud_orders_page.dart';
import 'creator_application_repository.dart';

class CreatorApplicationPage extends StatefulWidget {
  const CreatorApplicationPage({super.key, this.repository, this.pickVideos});
  final CreatorApplicationRepository? repository;
  final Future<List<String>> Function()? pickVideos;
  @override
  State<CreatorApplicationPage> createState() => _CreatorApplicationPageState();
}

class _CreatorApplicationPageState extends State<CreatorApplicationPage> {
  late final repository = widget.repository ?? CreatorApplicationRepository();
  final name = TextEditingController(), email = TextEditingController();
  final roles = <String>{}, directions = <String>{};
  final failedUploads = <String>[];
  List<String> tags = [];
  CreatorApplication? profile;
  bool loading = true, busy = false, adult = false, accepted = false;
  String region = 'cn_mainland';
  String? error, progress;
  bool get editable => profile == null || profile!.editable;
  bool get valid =>
      name.text.trim().isNotEmpty &&
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.text.trim()) &&
      roles.isNotEmpty &&
      directions.isNotEmpty &&
      adult &&
      accepted;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final loaded = await repository.load();
      final loadedTags = await repository.loadTags();
      if (!mounted) return;
      setState(() {
        profile = loaded;
        tags = loadedTags;
        final data = loaded?.data ?? <String, dynamic>{};
        name.text = data['displayName'] as String? ?? '';
        email.text = data['email'] as String? ?? '';
        region = data['marketRegion'] as String? ?? 'cn_mainland';
        if (!const [
          'cn_mainland',
          'us',
          'eea',
          'uk',
          'jp',
          'hk',
          'mo',
          'tw',
          'asia_other',
          'other'
        ].contains(region)) {
          region = 'other';
        }
        roles
          ..clear()
          ..addAll((data['characterTags'] as List? ?? [])
              .whereType<String>()
              .where(tags.contains));
        directions
          ..clear()
          ..addAll((data['skillTags'] as List? ?? [])
              .whereType<String>()
              .where(creatorApplicationDirections.contains));
        adult = data['adultConfirmed'] == true;
        accepted = data['agreementAccepted'] == true;
      });
    } catch (e) {
      if (mounted) setState(() => error = _message(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _message(Object e) => e is FormatException
      ? e.message
      : e is HttpException
          ? e.message
          : '操作失败，请检查网络后重试';
  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => error = _message(e));
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          progress = null;
        });
      }
    }
  }

  Future<void> _save() async {
    final updated = await repository.save({
      if (profile != null) 'version': profile!.version,
      'displayName': name.text.trim(),
      'email': email.text.trim().toLowerCase(),
      'characterTags': roles.toList(),
      'skillTags': directions.toList(),
      'marketRegion': region,
      'agreementVersion': 'creator-marketplace-v2',
      'adultConfirmed': adult,
      'agreementAccepted': accepted,
    });
    if (mounted) setState(() => profile = updated);
  }

  Future<void> _upload(List<String> files) async {
    setState(() {
      for (final path in files) {
        if (!failedUploads.contains(path)) failedUploads.add(path);
      }
    });
    await _save();
    for (final path in files) {
      if (!mounted) return;
      setState(() =>
          progress = '正在上传并检查：${path.replaceAll('\\', '/').split('/').last}');
      if (!path.toLowerCase().endsWith('.mp4')) {
        throw const FormatException('请选择 MP4 视频');
      }
      if (await File(path).length() > 256 * 1024 * 1024) {
        throw const FormatException('单个视频不能超过 256 MiB');
      }
      final updated = await repository.upload(path, profile!.version);
      if (!mounted) return;
      setState(() {
        profile = updated;
        failedUploads.remove(path);
      });
    }
  }

  Future<void> _pick() => _run(() async {
        final files = widget.pickVideos != null
            ? await widget.pickVideos!()
            : (await FilePicker.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['mp4'],
              ))
                .map((file) => file.path)
                .whereType<String>()
                .toList();
        if (files.isEmpty || !mounted) return;
        if ((profile?.videos.length ?? 0) + files.length > 10) {
          throw const FormatException('最多上传 10 个作品');
        }
        await _upload(files);
      });
  Future<void> _preview(Map<String, dynamic> video) => _run(() async {
        final intake = CloudBusinessIntake.instance;
        final identity = await intake.downloadIdentity();
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => _ApplicationVideoPreview(
                  url: intake.baseUri!.resolve(
                      '${CreatorApplicationRepository.path}/videos/${Uri.encodeComponent(video['id'] as String)}'),
                  token: identity.token,
                )));
      });
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('创作者认证'), actions: [
          IconButton(
              onPressed: busy || loading ? null : _load,
              icon: const Icon(Icons.refresh),
              tooltip: '刷新审核结果')
        ]),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(padding: const EdgeInsets.all(20), children: [
                if (error != null) ...[
                  Text(error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  TextButton(
                      onPressed: busy ? null : _load, child: const Text('刷新重试'))
                ],
                if (error != null && tags.isEmpty) const Text('加载申请失败，刷新后继续'),
                if (error == null && tags.isEmpty && editable)
                  const Text('平台暂未配置角色标签，请稍后刷新重试'),
                if (profile?.reason?.isNotEmpty == true) Text(profile!.reason!),
                if (profile?.status == 'approved') ...[
                  const Text('已认证创作者', style: TextStyle(fontSize: 24)),
                  if (profile!.grade != null)
                    Text('创作等级：${profile!.grade}',
                        style: const TextStyle(fontSize: 20)),
                  FilledButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) =>
                                  const CloudOrdersPage(creator: true))),
                      child: const Text('进入创作者工作台')),
                ] else if (!editable) ...[
                  Text(profile?.status == 'pending' ? '创作者申请审核中' : '创作者资格已暂停',
                      style: const TextStyle(fontSize: 24)),
                  const Text('审核由平台人工完成。可刷新查看审核结果。'),
                ] else if (tags.isNotEmpty) ...[
                  if (profile?.status == 'rejected')
                    const Text('申请未通过，请根据审核意见修改后重新提交'),
                  const Text('擅长角色', style: TextStyle(fontSize: 20)),
                  Wrap(
                      spacing: 8,
                      children: tags
                          .map((tag) => FilterChip(
                              label: Text(tag),
                              selected: roles.contains(tag),
                              onSelected: busy
                                  ? null
                                  : (value) => setState(() {
                                        value
                                            ? roles.add(tag)
                                            : roles.remove(tag);
                                      })))
                          .toList()),
                  const SizedBox(height: 16),
                  const Text('擅长内容方向', style: TextStyle(fontSize: 20)),
                  Wrap(
                      spacing: 8,
                      children: creatorApplicationDirections
                          .map((tag) => FilterChip(
                              label: Text(tag),
                              selected: directions.contains(tag),
                              onSelected: busy
                                  ? null
                                  : (value) => setState(() {
                                        value
                                            ? directions.add(tag)
                                            : directions.remove(tag);
                                      })))
                          .toList()),
                  TextField(
                      key: const Key('application-name'),
                      controller: name,
                      enabled: !busy,
                      decoration: const InputDecoration(labelText: '创作者显示名称'),
                      onChanged: (_) => setState(() {})),
                  TextField(
                      key: const Key('application-email'),
                      controller: email,
                      enabled: !busy,
                      keyboardType: TextInputType.emailAddress,
                      decoration:
                          const InputDecoration(labelText: '邮箱（创作者唯一识别）'),
                      onChanged: (_) => setState(() {})),
                  DropdownButtonFormField<String>(
                      initialValue: region,
                      decoration: const InputDecoration(labelText: '创作者所在地'),
                      items: const {
                        'cn_mainland': '中国大陆',
                        'us': '美国',
                        'eea': '欧洲经济区',
                        'uk': '英国',
                        'jp': '日本',
                        'hk': '中国香港',
                        'mo': '中国澳门',
                        'tw': '中国台湾',
                        'asia_other': '其他亚洲地区',
                        'other': '其他地区'
                      }
                          .entries
                          .map((e) => DropdownMenuItem(
                              value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: busy
                          ? null
                          : (value) => setState(() => region = value!)),
                  CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: adult,
                      onChanged: busy
                          ? null
                          : (value) => setState(() => adult = value!),
                      title: const Text('我已年满 18 岁')),
                  CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: accepted,
                      onChanged: busy
                          ? null
                          : (value) => setState(() => accepted = value!),
                      title: const Text('我同意创作者规则、保密要求和禁止私下交易条款')),
                  const SizedBox(height: 16),
                  const Text('本人创作的视频作品', style: TextStyle(fontSize: 20)),
                  const Text(
                      '请上传至少 1 个本人创作的 MP4 视频，最多 10 个，每个不超过 256 MiB。作品仅供认证审核，不会公开发布。人工审核将综合作品数量、质量及创意评定等级。'),
                  OutlinedButton.icon(
                      onPressed: busy || !valid ? null : _pick,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('上传本人作品')),
                  for (final file in failedUploads)
                    ListTile(
                        title: Text(file.replaceAll('\\', '/').split('/').last),
                        subtitle: const Text('上传失败，作品未添加'),
                        trailing: Wrap(children: [
                          IconButton(
                              tooltip: '重试上传',
                              onPressed: busy || !valid
                                  ? null
                                  : () => _run(() => _upload([file])),
                              icon: const Icon(Icons.refresh)),
                          IconButton(
                              tooltip: '移除失败项',
                              onPressed: busy
                                  ? null
                                  : () => setState(
                                      () => failedUploads.remove(file)),
                              icon: const Icon(Icons.close))
                        ])),
                ],
                for (final video in profile?.videos ?? <Map<String, dynamic>>[])
                  ListTile(
                      title: Text(video['name'] as String? ?? '认证作品'),
                      subtitle: const Text('已上传 · 私有作品'),
                      leading: IconButton(
                          tooltip: '预览作品',
                          onPressed: busy ? null : () => _preview(video),
                          icon: const Icon(Icons.play_circle_outline)),
                      trailing: editable
                          ? IconButton(
                              tooltip: '移除作品',
                              onPressed: busy
                                  ? null
                                  : () => _run(() async {
                                        final updated = await repository.remove(
                                            video['id'] as String,
                                            profile!.version);
                                        if (mounted) {
                                          setState(() => profile = updated);
                                        }
                                      }),
                              icon: const Icon(Icons.delete_outline))
                          : null),
                if (progress != null) Text(progress!),
                if (busy) const LinearProgressIndicator(),
                if (editable && tags.isNotEmpty) ...[
                  TextButton(
                      onPressed: busy || !valid ? null : () => _run(_save),
                      child: const Text('保存草稿')),
                  FilledButton(
                      onPressed: busy ||
                              !valid ||
                              (profile?.videos.isEmpty ?? true) ||
                              failedUploads.isNotEmpty
                          ? null
                          : () => _run(() async {
                                await _save();
                                if (!mounted) return;
                                final updated =
                                    await repository.submit(profile!.version);
                                if (mounted) setState(() => profile = updated);
                              }),
                      child: const Text('提交创作者申请')),
                ],
              ]),
      );
}

class _ApplicationVideoPreview extends StatefulWidget {
  const _ApplicationVideoPreview({required this.url, required this.token});
  final Uri url;
  final String token;
  @override
  State<_ApplicationVideoPreview> createState() =>
      _ApplicationVideoPreviewState();
}

class _ApplicationVideoPreviewState extends State<_ApplicationVideoPreview> {
  late final controller = VideoPlayerController.networkUrl(widget.url,
      httpHeaders: {'Authorization': 'Bearer ${widget.token}'});
  String? error;
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await controller.initialize();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => error = '视频预览失败，请返回后重试');
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('认证作品预览')),
      body: Center(
          child: error != null
              ? Text(error!)
              : !controller.value.isInitialized
                  ? const CircularProgressIndicator()
                  : Column(children: [
                      Expanded(
                          child: Center(
                              child: AspectRatio(
                                  aspectRatio: controller.value.aspectRatio,
                                  child: VideoPlayer(controller)))),
                      VideoProgressIndicator(controller, allowScrubbing: true),
                      IconButton(
                          onPressed: () {
                            setState(() {
                              controller.value.isPlaying
                                  ? controller.pause()
                                  : controller.play();
                            });
                          },
                          icon: Icon(controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow))
                    ])));
}
