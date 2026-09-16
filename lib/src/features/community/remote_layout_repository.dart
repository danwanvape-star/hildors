import 'dart:convert';

import 'remote_catalog_transport_stub.dart'
    if (dart.library.io) 'remote_catalog_transport_io.dart' as transport;

class RemoteLayoutBlock {
  const RemoteLayoutBlock({
    required this.id,
    required this.type,
    required this.title,
    required this.visible,
    required this.columns,
  });

  final String id, type, title;
  final bool visible;
  final int columns;

  factory RemoteLayoutBlock.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['id'] is! String ||
        value['type'] is! String ||
        value['title'] is! String ||
        value['visible'] is! bool ||
        value['columns'] is! int) {
      throw const FormatException('页面布局模块无效');
    }
    return RemoteLayoutBlock(
      id: value['id'] as String,
      type: value['type'] as String,
      title: value['title'] as String,
      visible: value['visible'] as bool,
      columns: value['columns'] as int,
    );
  }
}

class RemoteLayoutRepository {
  RemoteLayoutRepository(String baseUrl, {Future<String> Function(Uri)? fetch})
      : baseUri = Uri.parse(baseUrl),
        _fetch = fetch ?? transport.fetchCatalogJson;

  final Uri baseUri;
  final Future<String> Function(Uri) _fetch;

  Future<List<RemoteLayoutBlock>> loadPage(String page) async {
    final value = jsonDecode(await _fetch(baseUri.resolve('/v1/layout')));
    if (value is! Map<String, dynamic> || value['layout'] is! Map) {
      throw const FormatException('页面布局响应无效');
    }
    final layout = Map<String, dynamic>.from(value['layout'] as Map);
    if (layout['schemaVersion'] != 1 || layout['pages'] is! Map) {
      throw const FormatException('页面布局版本无效');
    }
    final pages = Map<String, dynamic>.from(layout['pages'] as Map);
    final blocks = pages[page];
    if (blocks is! List) throw const FormatException('页面布局缺失');
    return blocks
        .map(RemoteLayoutBlock.fromJson)
        .where((block) => block.visible)
        .toList(growable: false);
  }
}
