import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/creator_content_repository.dart';

class _Pages implements CreatorContentTransport {
  final paths = <String>[];
  final responses = <Map<String, dynamic>>[];
  @override
  Future<CreatorContentResponse> request(
      {required String method,
      required String path,
      Map<String, dynamic>? body,
      String? filePath,
      String? contentType,
      int? ifMatch}) async {
    paths.add(path);
    return CreatorContentResponse(200, responses.removeAt(0));
  }
}

Map<String, dynamic> _item(String id) => {
      'id': id,
      'title': '角色',
      'format': 'single',
      'status': 'draft',
      'submissionStatus': 'draft',
      'version': 1,
      'description': '故'.padRight(10000, '故'),
      'tags': <String>[],
      'clips': [
        {'id': 'c', 'title': '待机'}
      ],
    };

void main() {
  test('owned content follows bounded pages and retains complete stories',
      () async {
    final transport = _Pages()
      ..responses.addAll([
        {
          'items': [_item('a')],
          'nextCursor': 'a'
        },
        {
          'items': [_item('b')],
          'nextCursor': null
        },
      ]);
    final items = await RemoteCreatorContentRepository(transport).loadOwned();
    expect(items.map((item) => item.id), ['a', 'b']);
    expect(items.first.description.length, 10000);
    expect(transport.paths,
        ['/v1/me/content?limit=20', '/v1/me/content?limit=20&cursor=a']);
  });
  test('repeated pages fail explicitly instead of silently duplicating drafts',
      () async {
    final transport = _Pages()
      ..responses.addAll([
        {
          'items': [_item('a')],
          'nextCursor': 'a'
        },
        {
          'items': [_item('a')],
          'nextCursor': 'a'
        },
      ]);
    await expectLater(RemoteCreatorContentRepository(transport).loadOwned(),
        throwsFormatException);
  });
}
