import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/creator_content_repository.dart';

class _Call {
  const _Call({
    required this.method,
    required this.path,
    this.body,
    this.filePath,
    this.contentType,
    this.ifMatch,
  });

  final String method;
  final String path;
  final Map<String, dynamic>? body;
  final String? filePath;
  final String? contentType;
  final int? ifMatch;
}

class _MediaTransport extends _Transport implements CreatorMediaTransport {
  @override
  int identityRevision = 0;
  int identityCalls = 0;
  @override
  Future<({Uri baseUri, String token})> mediaIdentity() async {
    identityCalls++;
    return (
      baseUri: Uri.parse('https://example.test'),
      token: 'token-$identityRevision'
    );
  }
}

class _Transport implements CreatorContentTransport {
  final calls = <_Call>[];
  final responses = <CreatorContentResponse>[];

  @override
  Future<CreatorContentResponse> request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    String? filePath,
    String? contentType,
    int? ifMatch,
  }) async {
    calls.add(_Call(
      method: method,
      path: path,
      body: body,
      filePath: filePath,
      contentType: contentType,
      ifMatch: ifMatch,
    ));
    return responses.removeAt(0);
  }
}

Map<String, dynamic> _content({
  int version = 1,
  String submissionStatus = 'draft',
  String? reviewNote,
}) =>
    {
      'id': 'content-1',
      'title': '星港守望者',
      'format': 'single',
      'source': 'creator',
      'status': 'draft',
      'submissionStatus': submissionStatus,
      'version': version,
      'description': '她在星港守护最后一盏灯。',
      'tags': ['幻想'],
      'creator': {'id': 'creator-1', 'name': 'Studio', 'anonymous': false},
      if (reviewNote != null) 'review': {'note': reviewNote},
      'clips': [
        {
          'id': 'main',
          'title': '待机',
          'media': {
            'id': 'media-1',
            'inspection': {'status': 'checked'}
          }
        }
      ]
    };

void main() {
  test(
      'private media URLs use current account headers and replacement media identity',
      () async {
    final transport = _MediaTransport();
    final repo = RemoteCreatorContentRepository(transport);
    final item = CreatorContent.fromJson(_content());
    const clip = CreatorContentClip(
        id: 'clip / 1',
        title: 'Video',
        hasMedia: true,
        inspectionStatus: 'checked',
        mediaId: 'replacement');
    final first = await repo.mediaAccess(item, clip);
    final second = await repo.mediaAccess(item, clip);
    expect(first.thumbnail.path, contains('/thumbnail'));
    expect(first.preview.queryParameters['v'], 'replacement');
    expect(first.preview.toString(), isNot(contains('token')));
    expect(first.headers['Authorization'], 'Bearer token-0');
    expect(second.headers, first.headers);
    expect(transport.identityCalls, 1);
    transport.identityRevision++;
    expect((await repo.mediaAccess(item, clip)).headers['Authorization'],
        'Bearer token-1');
    expect(transport.identityCalls, 2);
    await repo.mediaAccess(item, clip, refreshIdentity: true);
    expect(transport.identityCalls, 3);
  });
  test('repository sends creator draft and submission with exact versions',
      () async {
    final transport = _Transport()
      ..responses.addAll([
        CreatorContentResponse(200, {
          'items': [
            {'id': 'tag-1', 'name': '幻想', 'active': true},
            {'id': 'tag-2', 'name': '旧标签', 'active': false},
          ]
        }),
        CreatorContentResponse(201, _content()),
        CreatorContentResponse(
            200, _content(version: 2, submissionStatus: 'pending')),
      ]);
    final repository = RemoteCreatorContentRepository(transport);

    final tags = await repository.loadTags();
    final draft = await repository.create(
      title: '星港守望者',
      format: 'single',
      tags: const ['幻想'],
      description: '她在星港守护最后一盏灯。',
      clips: const [CreatorContentClipDraft(id: 'main', title: '待机')],
    );
    final submitted = await repository.submit(draft);

    expect(tags.map((tag) => tag.name), ['幻想', '旧标签']);
    expect(tags.last.active, isFalse);
    expect(transport.calls[0].path, '/v1/content-tags');
    expect(transport.calls[1].method, 'POST');
    expect(transport.calls[1].path, '/v1/me/content');
    expect(transport.calls[1].body, {
      'title': '星港守望者',
      'format': 'single',
      'tags': ['幻想'],
      'description': '她在星港守护最后一盏灯。',
      'clips': [
        {'id': 'main', 'title': '待机'}
      ],
    });
    expect(transport.calls[2].path, '/v1/me/content/content-1/submit');
    expect(transport.calls[2].body, {'version': 1});
    expect(submitted.submissionStatus, 'pending');
    expect(submitted.version, 2);
  });

  test('repository sends media type and current version for creator upload',
      () async {
    final transport = _Transport()
      ..responses.add(CreatorContentResponse(200, _content(version: 4)));
    final repository = RemoteCreatorContentRepository(transport);
    final item = CreatorContent.fromJson(_content(version: 3));

    await repository.uploadClip(
      item,
      clipId: 'main',
      filePath: r'C:\media\idle.mp4',
    );

    final call = transport.calls.single;
    expect(call.method, 'PUT');
    expect(call.path, '/v1/me/content/content-1/clips/main/media');
    expect(call.filePath, r'C:\media\idle.mp4');
    expect(call.contentType, 'video/mp4');
    expect(call.ifMatch, 3);
  });

  test('upload inspection and submission always advance the returned version',
      () async {
    final transport = _Transport()
      ..responses.addAll([
        CreatorContentResponse(200, _content(version: 2)),
        CreatorContentResponse(200, _content(version: 4)),
        CreatorContentResponse(
          200,
          _content(version: 5, submissionStatus: 'pending'),
        ),
      ]);
    final repository = RemoteCreatorContentRepository(transport);
    final draft = CreatorContent.fromJson(_content());

    final uploaded = await repository.uploadClip(
      draft,
      clipId: 'main',
      filePath: r'C:\media\idle.mp4',
    );
    final inspected = await repository.inspect(uploaded, 'main');
    final submitted = await repository.submit(inspected);

    expect(transport.calls[0].ifMatch, 1);
    expect(transport.calls[1].body, {'version': 2});
    expect(transport.calls[2].body, {'version': 4});
    expect(submitted.version, 5);
    expect(submitted.submissionStatus, 'pending');
  });

  test('401 is exposed as an expired creator session', () async {
    final transport = _Transport()
      ..responses.add(const CreatorContentResponse(401, {
        'code': 'UNAUTHORIZED',
      }));
    final repository = RemoteCreatorContentRepository(transport);

    await expectLater(
      repository.loadOwned(),
      throwsA(isA<CreatorContentException>()
          .having((error) => error.sessionExpired, 'sessionExpired', isTrue)
          .having((error) => error.message, 'message', '登录已失效，请重新认证创作者身份')),
    );
    expect(transport.calls, hasLength(1));
  });
}
