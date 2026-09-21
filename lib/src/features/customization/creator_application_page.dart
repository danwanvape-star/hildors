import '../../localization/localization.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'cloud_business_intake.dart';
import 'creator_workbench_page.dart';
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
  bool get validName =>
      RegExp(r'^[A-Za-z0-9]+$').hasMatch(name.text.trim()) &&
      RegExp(r'[A-Za-z]').hasMatch(name.text.trim()) &&
      name.text.trim().length <= 80;
  String? get validationMessage {
    if (!validName) return '名称仅限英文字母和数字，至少包含一个英文字母，最多 80 个字符';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.text.trim())) {
      return '请填写有效邮箱后上传作品';
    }
    if (roles.isEmpty) return '请至少选择一个擅长角色类型';
    if (directions.isEmpty) return '请至少选择一个擅长内容方向';
    if (!adult) return '请确认已年满 18 岁';
    if (!accepted) return '请阅读并同意创作者规则';
    return null;
  }

  bool get valid => validationMessage == null;
  void _validate() {
    final message = validationMessage;
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_applicationError(context, message))));
      throw FormatException(message);
    }
  }

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
    _validate();
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
          progress = context.l10n.applicationUploading(path.replaceAll('\\', '/').split('/').last));
      if (!path.toLowerCase().endsWith('.mp4')) {
        throw FormatException('请选择 MP4 视频');
      }
      if (await File(path).length() > 15000000) {
        throw FormatException('单个视频不能超过 15 MB，请压缩后重新选择');
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
        _validate();
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
          throw FormatException('最多上传 10 个作品');
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
        appBar: AppBar(title: Text(context.l10n.applicationTitle), actions: [
          IconButton(
              onPressed: busy || loading ? null : _load,
              icon: Icon(Icons.refresh),
              tooltip: context.l10n.applicationRefresh)
        ]),
        body: loading
            ? Center(child: CircularProgressIndicator())
            : ListView(padding: EdgeInsets.all(20), children: [
                if (error != null) ...[
                  Text(_applicationError(context, error!),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  TextButton(
                      onPressed: busy ? null : _load, child: Text(context.l10n.applicationRetry))
                ],
                if (error != null && tags.isEmpty) Text(context.l10n.applicationLoadFailed),
                if (error == null && tags.isEmpty && editable)
                  Text(context.l10n.applicationNoTags),
                if (profile?.reason?.isNotEmpty == true) Text(profile!.reason!),
                if (profile?.status == 'approved') ...[
                  Text(context.l10n.applicationApproved, style: TextStyle(fontSize: 24)),
                  if (profile!.grade != null)
                    Text(context.l10n.applicationGrade(_applicationLabel(context, profile!.grade!)),
                        style: TextStyle(fontSize: 20)),
                  FilledButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => CreatorWorkbenchPage())),
                      child: Text(context.l10n.applicationOpenStudio)),
                ] else if (!editable) ...[
                  Text(profile?.status == 'pending' ? context.l10n.applicationPending : context.l10n.applicationSuspended,
                      style: TextStyle(fontSize: 24)),
                  Text(context.l10n.applicationReviewNote),
                ] else if (tags.isNotEmpty) ...[
                  if (profile?.status == 'rejected')
                    Text(context.l10n.applicationRejected),
                  Text(context.l10n.applicationRoles, style: TextStyle(fontSize: 20)),
                  Wrap(
                      spacing: 8,
                      children: tags
                          .map((tag) => FilterChip(
                              label: Text(repository.tagLabel(tag, context.l10n.localeName)),
                              selected: roles.contains(tag),
                              onSelected: busy
                                  ? null
                                  : (value) => setState(() {
                                        value
                                            ? roles.add(tag)
                                            : roles.remove(tag);
                                      })))
                          .toList()),
                  SizedBox(height: 16),
                  Text(context.l10n.applicationDirections, style: TextStyle(fontSize: 20)),
                  Wrap(
                      spacing: 8,
                      children: creatorApplicationDirections
                          .map((tag) => FilterChip(
                              label: Text(_applicationLabel(context, tag)),
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
                      key: Key('application-name'),
                      controller: name,
                      enabled: !busy,
                      keyboardType: TextInputType.text,
                      autocorrect: false,
                      decoration: InputDecoration(
                          labelText: context.l10n.applicationName,
                          helperText: context.l10n.applicationNameHint,
                          errorMaxLines: 2,
                          errorText: name.text.isNotEmpty && !validName
                              ? context.l10n.applicationNameRule
                              : null),
                      onChanged: (_) => setState(() {})),
                  TextField(
                      key: Key('application-email'),
                      controller: email,
                      enabled: !busy,
                      keyboardType: TextInputType.emailAddress,
                      decoration:
                          InputDecoration(labelText: context.l10n.applicationEmail),
                      onChanged: (_) => setState(() {})),
                  DropdownButtonFormField<String>(
                      isExpanded: true,
                      itemHeight: null,
                      initialValue: region,
                      decoration: InputDecoration(labelText: context.l10n.applicationRegion),
                      items: {
                        'cn_mainland': context.l10n.applicationChina,
                        'us': context.l10n.applicationUs,
                        'eea': context.l10n.applicationEea,
                        'uk': context.l10n.applicationUk,
                        'jp': context.l10n.applicationJapan,
                        'hk': context.l10n.applicationHk,
                        'mo': context.l10n.applicationMo,
                        'tw': context.l10n.applicationTw,
                        'asia_other': context.l10n.applicationAsia,
                        'other': context.l10n.applicationOther
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
                      title: Text(context.l10n.applicationAdult)),
                  CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: accepted,
                      onChanged: busy
                          ? null
                          : (value) => setState(() => accepted = value!),
                      title: Text(context.l10n.applicationAgreement)),
                  SizedBox(height: 16),
                  Text(context.l10n.applicationWorks, style: TextStyle(fontSize: 20)),
                  Text(
                      context.l10n.applicationWorkNote),
                  if (validationMessage != null) Text(_applicationError(context, validationMessage!)),
                  OutlinedButton.icon(
                      onPressed: busy ? null : _pick,
                      icon: Icon(Icons.upload_file),
                      label: Text(context.l10n.applicationUpload)),
                  for (final file in failedUploads)
                    ListTile(
                        title: Text(file.replaceAll('\\', '/').split('/').last),
                        subtitle: Text(context.l10n.applicationUploadFailed),
                        trailing: Wrap(children: [
                          IconButton(
                              tooltip: context.l10n.applicationRetryUpload,
                              onPressed: busy || !valid
                                  ? null
                                  : () => _run(() => _upload([file])),
                              icon: Icon(Icons.refresh)),
                          IconButton(
                              tooltip: context.l10n.applicationRemoveFailed,
                              onPressed: busy
                                  ? null
                                  : () => setState(
                                      () => failedUploads.remove(file)),
                              icon: Icon(Icons.close))
                        ])),
                ],
                for (final video in profile?.videos ?? <Map<String, dynamic>>[])
                  ListTile(
                      title: Text(video['name'] as String? ?? context.l10n.applicationSample),
                      subtitle: Text(context.l10n.applicationPrivate),
                      leading: IconButton(
                          tooltip: context.l10n.applicationPreview,
                          onPressed: busy ? null : () => _preview(video),
                          icon: Icon(Icons.play_circle_outline)),
                      trailing: editable
                          ? IconButton(
                              tooltip: context.l10n.applicationRemove,
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
                              icon: Icon(Icons.delete_outline))
                          : null),
                if (progress != null) Text(progress!),
                if (busy) LinearProgressIndicator(),
                if (editable && tags.isNotEmpty) ...[
                  TextButton(
                      onPressed: busy ? null : () => _run(_save),
                      child: Text(context.l10n.applicationSave)),
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
                      child: Text(context.l10n.applicationSubmit)),
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
      appBar: AppBar(title: Text(context.l10n.applicationPreviewTitle)),
      body: Center(
          child: error != null
              ? Text(_applicationError(context, error!))
              : !controller.value.isInitialized
                  ? CircularProgressIndicator()
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

String _applicationError(BuildContext context, String message) => switch(message) {
  '名称仅限英文字母和数字，至少包含一个英文字母，最多 80 个字符' => context.l10n.applicationInvalidName,
  '请填写有效邮箱后上传作品' => context.l10n.applicationInvalidEmail,
  '请至少选择一个擅长角色类型' => context.l10n.applicationRoleRequired,
  '请至少选择一个擅长内容方向' => context.l10n.applicationDirectionRequired,
  '请确认已年满 18 岁' => context.l10n.applicationAdultRequired,
  '请阅读并同意创作者规则' => context.l10n.applicationAgreementRequired,
  '请选择 MP4 视频' => context.l10n.applicationMp4,
  '单个视频不能超过 15 MB，请压缩后重新选择' => context.l10n.applicationTooLarge,
  '最多上传 10 个作品' => context.l10n.applicationLimit,
  '该邮箱已被其他创作者使用，请更换邮箱' => context.l10n.applicationEmailUsed,
  '请检查英文名称、角色、方向、邮箱及协议确认' => context.l10n.applicationInvalidFields,
  '视频检查繁忙，请稍后重试' => context.l10n.applicationProcessorBusy,
  '申请已锁定，请刷新查看审核状态' => context.l10n.applicationLocked,
  '最多上传 10 个作品，请移除作品后重试' => context.l10n.applicationVideoLimit,
  '视频检查未通过，请选择可正常播放的 MP4 视频重试' => context.l10n.applicationVideoInvalid,
  '请至少上传 1 个检查通过的视频作品' => context.l10n.applicationVideoRequired,
  '申请已更新，请刷新后重试' => context.l10n.applicationConflict,
  '视频预览失败，请返回后重试' => context.l10n.applicationPreviewFailed,
  _ => context.l10n.errorGeneric,
};

String _applicationLabel(BuildContext context, String value) => switch(value) {
  '简单动作' => context.l10n.applicationDirectionAction,
  '歌舞表演' => context.l10n.applicationDirectionDance,
  '特效炫技' => context.l10n.applicationDirectionEffects,
  '角色成长' => context.l10n.applicationDirectionGrowth,
  '白银' => context.l10n.applicationGradeSilver,
  '黄金' => context.l10n.applicationGradeGold,
  '钻石' => context.l10n.applicationGradeDiamond,
  '宗师' => context.l10n.applicationGradeMaster,
  '大神' => context.l10n.applicationGradeLegend,
  _ => value,
};
