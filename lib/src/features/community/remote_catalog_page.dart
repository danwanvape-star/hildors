import 'catalog_network_image.dart';
import 'package:flutter/material.dart';

import 'remote_package_detail_page.dart';
import 'remote_catalog_repository.dart';
import 'remote_layout_repository.dart';

class RemoteCatalogPage extends StatefulWidget {
  const RemoteCatalogPage({
    super.key,
    required this.load,
    this.loadLayout,
    this.clipActions,
    this.packageActions,
  });

  final Future<List<RemoteCatalogPackage>> Function() load;
  final Future<List<RemoteLayoutBlock>> Function()? loadLayout;
  final Widget Function(RemoteCatalogPackage package, RemoteCatalogClip clip)?
      clipActions;
  final Widget Function(RemoteCatalogPackage)? packageActions;

  @override
  State<RemoteCatalogPage> createState() => _RemoteCatalogPageState();
}

class _RemoteCatalogPageState extends State<RemoteCatalogPage> {
  late Future<_CatalogData> _request;
  final searchController = TextEditingController();
  String query = '', source = '全部', format = '全部', topic = '全部';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _request = _loadData();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<_CatalogData> _loadData() async {
    final layoutRequest = _loadLayout();
    final packages = await widget.load();
    return _CatalogData(packages, await layoutRequest);
  }

  Future<List<RemoteLayoutBlock>> _loadLayout() async {
    if (widget.loadLayout == null) return _fallbackCollectionLayout;
    try {
      final layout = await widget.loadLayout!();
      return layout.isEmpty ? _fallbackCollectionLayout : layout;
    } catch (_) {
      return _fallbackCollectionLayout;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_CatalogData>(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('暂时无法加载内容库'),
              const Padding(
                  padding: EdgeInsets.all(16), child: Text('请检查网络连接后重试。')),
              FilledButton(
                  onPressed: () => setState(() {
                        _reload();
                      }),
                  child: const Text('重试')),
            ]));
          }
          final data = snapshot.data!;
          final topics = data.packages
              .expand((item) => item.tags)
              .where((tag) => tag.trim().isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          final items = data.packages
              .where((p) =>
                  (source == '全部' || p.source == source) &&
                  (format == '全部' || p.format == format) &&
                  (topic == '全部' || p.tags.contains(topic)) &&
                  '${p.title} ${p.credit} ${p.tags.join(' ')}'
                      .toLowerCase()
                      .contains(query.trim().toLowerCase()))
              .toList(growable: false);
          final filtering = query.trim().isNotEmpty ||
              source != '全部' ||
              format != '全部' ||
              topic != '全部';
          return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: searchController,
                          onChanged: (value) => setState(() => query = value),
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              hintText: '搜索角色、视频或题材',
                              prefixIconConstraints:
                                  BoxConstraints(minWidth: 36, minHeight: 40),
                              prefixIcon: Icon(Icons.search, size: 20)))),
                  IconButton(
                      tooltip: '刷新目录',
                      onPressed: () => setState(() {
                            _reload();
                          }),
                      icon: const Icon(Icons.refresh, size: 22)),
                ]),
                const SizedBox(height: 4),
                _filterRow(
                    '出处',
                    const {
                      '全部': '全部',
                      'hildors': 'HILDORS 出品',
                      'creator': '创作者作品'
                    },
                    source,
                    (value) => setState(() => source = value)),
                _filterRow(
                    '形式',
                    const {
                      '全部': '全部',
                      'single': '单条视频',
                      'package': '角色视频包',
                    },
                    format,
                    (value) => setState(() => format = value)),
                if (topics.isNotEmpty)
                  _filterRow(
                      '题材',
                      {'全部': '全部', for (final tag in topics) tag: tag},
                      topic,
                      (value) => setState(() => topic = value)),
                const SizedBox(height: 6),
                if (items.isEmpty)
                  const Padding(
                      padding: EdgeInsets.all(24), child: Text('暂无符合条件的内容')),
                if (filtering) ...[
                  Row(children: [
                    const Expanded(child: _SectionTitle('筛选结果')),
                    TextButton(
                        onPressed: () => setState(() {
                              source = format = topic = '全部';
                              query = '';
                              searchController.clear();
                            }),
                        child: const Text('清除筛选')),
                  ]),
                  if (items.isNotEmpty) _grid(items, 3, data.packages),
                ] else
                  for (final block in data.layout) ...[
                    if (_itemsFor(block, items).isNotEmpty) ...[
                      if (!const {'HILDORS 出品', 'HILDORS出品', '创作者作品', ''}
                          .contains(block.title.trim()))
                        _SectionTitle(block.title),
                      _grid(_itemsFor(block, items), block.columns,
                          data.packages),
                    ],
                  ],
              ]);
        },
      );

  Widget _filterRow(String label, Map<String, String> options, String selected,
          ValueChanged<String> onSelected) =>
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
              width: 38,
              child: Text(label,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xff91a6ba)))),
          Expanded(
              child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final entry in options.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: Text(entry.value,
                          style: const TextStyle(fontSize: 12)),
                      selected: selected == entry.key,
                      onSelected: (_) => onSelected(entry.key)),
                ),
            ]),
          )),
        ]),
      );

  List<RemoteCatalogPackage> _itemsFor(
      RemoteLayoutBlock block, List<RemoteCatalogPackage> items) {
    return switch (block.type) {
      'hildors' =>
        items.where((item) => item.source == 'hildors').toList(growable: false),
      'creators' =>
        items.where((item) => item.source == 'creator').toList(growable: false),
      _ => const [],
    };
  }

  Widget _grid(List<RemoteCatalogPackage> items, int requestedColumns,
          List<RemoteCatalogPackage> catalog) =>
      LayoutBuilder(builder: (context, constraints) {
        final accessible = constraints.maxWidth < 340 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        final columns = accessible ? 2 : requestedColumns.clamp(1, 3);
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(spacing: 10, runSpacing: 12, children: [
          for (final item in items) _tile(item, width, catalog),
        ]);
      });

  Widget _tile(RemoteCatalogPackage item, double width,
          List<RemoteCatalogPackage> catalog) =>
      SizedBox(
        width: width,
        child: Card(
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.zero,
            child: InkWell(
                onTap: () => _details(item, catalog),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                          aspectRatio: 1,
                          child: ColoredBox(
                              color: const Color(0xff101d2c),
                              child: CatalogNetworkImage(
                                  url: item.format == 'package'
                                      ? (item.coverThumbnailUrl ??
                                          item.coverUrl)
                                      : item.clips.first.thumbnailUrl,
                                  imageKey: ValueKey(item.format == 'package'
                                      ? ((item.coverThumbnailUrl ??
                                                  item.coverUrl) ==
                                              null
                                          ? 'package-cover-placeholder-${item.id}'
                                          : 'package-cover-${item.id}')
                                      : (item.clips.first.thumbnailUrl == null
                                          ? 'single-thumbnail-placeholder-${item.id}'
                                          : 'single-thumbnail-${item.id}')),
                                  placeholder: item.format == 'package'
                                      ? Icons.folder_copy_outlined
                                      : Icons.video_library_outlined))),
                      Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                Text(item.credit,
                                    key: ValueKey('credit-${item.id}'),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 6),
                                Text(
                                    '${item.format == 'single' ? '单条视频' : '角色视频包'} · ${item.clips.length}条',
                                    style: const TextStyle(fontSize: 11)),
                              ])),
                    ]))),
      );

  void _details(RemoteCatalogPackage item, List<RemoteCatalogPackage> catalog) {
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => RemotePackageDetailPage(
            item: item,
            catalog: catalog,
            clipActions: widget.clipActions,
            packageActions: widget.packageActions)));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Text(text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      );
}

class _CatalogData {
  const _CatalogData(this.packages, this.layout);
  final List<RemoteCatalogPackage> packages;
  final List<RemoteLayoutBlock> layout;
}

const _fallbackCollectionLayout = [
  RemoteLayoutBlock(
      id: 'collection-hildors',
      type: 'hildors',
      title: 'HILDORS 出品',
      visible: true,
      columns: 3),
  RemoteLayoutBlock(
      id: 'collection-creators',
      type: 'creators',
      title: '创作者作品',
      visible: true,
      columns: 3),
];
