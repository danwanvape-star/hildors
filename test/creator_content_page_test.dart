import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/creator_content_page.dart';
import 'package:hildors_cockpit/src/features/community/creator_content_repository.dart';

class _Repository implements CreatorContentRepository {
  _Repository({this.items = const []});

  List<CreatorContent> items;
  List<String>? createdTags;
  String? createdTitle;
  String? updatedTitle;
  String? updatedStory;
  List<String>? updatedTags;
  CreatorContent? submittedItem;
  int loadCalls = 0;
  int updateCalls = 0;
  bool failNextSubmit = false;
  final submittedVersions = <int>[];

  @override
  Future<List<CreatorContent>> loadOwned() async {
    loadCalls++;
    return items;
  }

  @override
  Future<List<CreatorContentTag>> loadTags() async => const [
        CreatorContentTag(id: 'tag-1', name: '幻想', active: true),
        CreatorContentTag(id: 'tag-2', name: '旧标签', active: false),
      ];

  @override
  Future<CreatorContent> create({
    required String title,
    required String format,
    required List<String> tags,
    required String description,
    required List<CreatorContentClipDraft> clips,
  }) async {
    createdTitle = title;
    createdTags = tags;
    final item = CreatorContent(
      id: 'new',
      title: title,
      format: format,
      status: 'draft',
      submissionStatus: 'draft',
      version: 1,
      description: description,
      tags: tags,
      clips: clips
          .map((clip) => CreatorContentClip(
                id: clip.id,
                title: clip.title,
                hasMedia: false,
                inspectionStatus: null,
              ))
          .toList(),
    );
    items = [item];
    return item;
  }

  @override
  Future<CreatorContent> inspect(CreatorContent item, String clipId) =>
      throw UnimplementedError();
  @override
  Future<CreatorContent> submit(CreatorContent item) async {
    submittedItem = item;
    submittedVersions.add(item.version);
    if (failNextSubmit) {
      failNextSubmit = false;
      throw const CreatorContentException(
        message: '暂时无法提交',
        code: 'TEMPORARY',
      );
    }
    return _copy(item,
        version: item.version + 1, submissionStatus: 'pending');
  }
  @override
  Future<CreatorContent> updateMetadata(CreatorContent item,
      {required String title,
      required List<String> tags,
      required String description}) async {
    updateCalls++;
    updatedTitle = title;
    updatedStory = description;
    updatedTags = tags;
    final updated = _copy(item,
        title: title,
        tags: tags,
        description: description,
        version: item.version + 1,
        submissionStatus: 'draft');
    items = [updated];
    return updated;
  }
  @override
  Future<CreatorContent> uploadClip(CreatorContent item,
          {required String clipId, required String filePath}) =>
      throw UnimplementedError();
  @override
  Future<CreatorContent> uploadCover(CreatorContent item,
          {required String filePath, required String contentType}) =>
      throw UnimplementedError();
}

CreatorContent _rejected() => const CreatorContent(
      id: 'returned',
      title: '退回作品',
      format: 'single',
      status: 'draft',
      submissionStatus: 'rejected',
      version: 8,
      description: '旧故事',
      tags: ['幻想'],
      reviewNote: '请补充角色来历，并重新检查视频。',
      clips: [
        CreatorContentClip(
          id: 'main',
          title: '待机',
          hasMedia: true,
          inspectionStatus: 'checked',
        )
      ],
    );

CreatorContent _copy(
  CreatorContent item, {
  String? title,
  List<String>? tags,
  String? description,
  int? version,
  String? submissionStatus,
}) =>
    CreatorContent(
      id: item.id,
      title: title ?? item.title,
      format: item.format,
      status: item.status,
      submissionStatus: submissionStatus ?? item.submissionStatus,
      version: version ?? item.version,
      description: description ?? item.description,
      tags: tags ?? item.tags,
      clips: item.clips,
      hasCover: item.hasCover,
      reviewNote: item.reviewNote,
    );

void main() {
  testWidgets('list shows rejected status and review reason', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CreatorContentPage(repository: _Repository(items: [_rejected()])),
    ));
    await tester.pumpAndSettle();

    expect(find.text('退回修改'), findsOneWidget);
    expect(find.text('请补充角色来历，并重新检查视频。'), findsOneWidget);
  });

  testWidgets('creator selects only active shared tags when creating a draft',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository();
    await tester.pumpWidget(MaterialApp(
      home: CreatorContentPage(repository: repository),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('创建投稿'));
    await tester.pumpAndSettle();

    expect(find.text('幻想'), findsOneWidget);
    expect(find.text('旧标签'), findsNothing);
    await tester.enterText(
        find.byKey(const Key('creator-content-title')), '星港守望者');
    await tester.enterText(
        find.byKey(const Key('creator-content-story')), '她在星港守护最后一盏灯。');
    await tester.enterText(
        find.byKey(const Key('creator-clip-title-0')), '待机');
    await tester.tap(find.widgetWithText(FilterChip, '幻想'));
    await tester.ensureVisible(find.text('保存草稿'));
    await tester.tap(find.text('保存草稿'));
    await tester.pumpAndSettle();

    expect(repository.createdTitle, '星港守望者');
    expect(repository.createdTags, ['幻想']);
    expect(find.text('已保存草稿，可继续上传视频并送审。'), findsOneWidget);
  });

  testWidgets('rejected edits save metadata before resubmission',
      (tester) async {
    final repository = _Repository();
    final returned = _copy(_rejected(), tags: const ['旧标签']);
    await tester.pumpWidget(MaterialApp(
      home: CreatorContentEditorPage(
        repository: repository,
        availableTags: const [
          CreatorContentTag(id: 'old', name: '旧标签', active: false),
          CreatorContentTag(id: 'new', name: '幻想', active: true),
        ],
        initial: returned,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('creator-content-title')), '退回作品新版');
    await tester.enterText(
        find.byKey(const Key('creator-content-story')), '补充后的完整角色来历。');
    await tester.tap(find.widgetWithText(FilterChip, '旧标签（旧标签）'));
    await tester.scrollUntilVisible(
      find.text('重新提交审核'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('重新提交审核'));
    await tester.pumpAndSettle();

    expect(repository.updatedTitle, '退回作品新版');
    expect(repository.updatedStory, '补充后的完整角色来历。');
    expect(repository.updatedTags, isEmpty);
    expect(repository.submittedItem?.version, 9);
    expect(find.text('重新提交审核'), findsNothing);
    expect(find.text('已提交平台审核，审核期间不可修改。'), findsOneWidget);
  });

  testWidgets('returning from an existing editor refreshes the owned list',
      (tester) async {
    final repository = _Repository(items: [_rejected()]);
    await tester.pumpWidget(MaterialApp(
      home: CreatorContentPage(repository: repository),
    ));
    await tester.pumpAndSettle();
    expect(repository.loadCalls, 1);

    await tester.tap(find.text('退回作品'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(repository.loadCalls, 2);
  });

  testWidgets('submit retry keeps the version returned by saved metadata',
      (tester) async {
    final repository = _Repository()..failNextSubmit = true;
    await tester.pumpWidget(MaterialApp(
      home: CreatorContentEditorPage(
        repository: repository,
        availableTags: const [
          CreatorContentTag(id: 'tag-1', name: '幻想', active: true),
        ],
        initial: _rejected(),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('creator-content-story')), '第二版背景故事');
    await tester.scrollUntilVisible(
      find.text('重新提交审核'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('重新提交审核'));
    await tester.pumpAndSettle();
    expect(find.text('暂时无法提交'), findsOneWidget);
    await tester.tap(find.text('提交审核'));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, 1);
    expect(repository.submittedVersions, [9, 9]);
  });
}
