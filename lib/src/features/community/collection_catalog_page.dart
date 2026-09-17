import 'package:flutter/material.dart';
import '../customization/character_gate_prototype_pages.dart';
import '../customization/character_entitlement_repository.dart';
import '../video/character_package_page.dart';
import '../video/character_video_package.dart';

import 'remote_catalog_page.dart';
import 'remote_catalog_repository.dart';
import 'remote_layout_repository.dart';
import 'owned_download_page.dart';

class CollectionCatalogItem {
  const CollectionCatalogItem(
      {required this.id,
      required this.title,
      required this.cover,
      required this.source,
      required this.format,
      required this.tags,
      this.package,
      this.creatorIndex});
  final String id, title, cover, source, format;
  final List<String> tags;
  final CharacterVideoPackage? package;
  final int? creatorIndex;
  bool get isConcept => creatorIndex != null;
  String get credit => source == 'HILDORS 出品' ? source : '匿名创作者';
}

// Browse metadata only: themes are not IP licences or verified author credits.
final collectionCatalogItems = <CollectionCatalogItem>[
  for (var i = 0; i < officialVideoPackages.length; i++)
    CollectionCatalogItem(
      id: officialVideoPackages[i].id,
      title: const ['全息舞者 01', '深海幻影 02', '幻翼舞台 01', '机械律动 02'][i],
      cover: officialVideoPackages[i].videos.first.thumbnail!,
      source: 'HILDORS 出品',
      format: '单条视频',
      tags: const [
        ['二次元', '音乐舞台'],
        ['神话', '二次元'],
        ['二次元', '音乐舞台'],
        ['未来时空', '音乐舞台']
      ][i],
      package: officialVideoPackages[i],
    ),
  for (var i = 0; i < characterGateCatalog.length; i++)
    CollectionCatalogItem(
      id: characterGateCatalog[i].$1,
      title: characterGateCatalog[i].$2,
      cover: characterGateCatalog[i].$4,
      source: '创作者作品',
      format: '角色视频包',
      tags: const [
        ['神话', '未来时空'],
        ['二次元', '音乐舞台'],
        ['神话'],
        ['游戏', '未来时空']
      ][i],
      creatorIndex: i,
    ),
];

List<CollectionCatalogItem> filterCollectionCatalog(
    {String source = '全部',
    String format = '全部',
    String topic = '全部',
    String query = ''}) {
  final search = query.trim().toLowerCase();
  return collectionCatalogItems
      .where((item) =>
          (source == '全部' || item.source == source) &&
          (format == '全部' || item.format == format) &&
          (topic == '全部' || item.tags.contains(topic)) &&
          (search.isEmpty ||
              '${item.title} ${item.source} ${item.tags.join(' ')}'
                  .toLowerCase()
                  .contains(search)))
      .toList(growable: false);
}

class CollectionCatalogPage extends StatefulWidget {
  const CollectionCatalogPage({super.key});
  @override
  State<CollectionCatalogPage> createState() => _CollectionCatalogPageState();
}

class _CollectionCatalogPageState extends State<CollectionCatalogPage> {
  String source = '全部', format = '全部', topic = '全部', query = '';
  final searchController = TextEditingController();
  void _reset() => setState(() {
        source = format = topic = '全部';
        query = '';
        searchController.clear();
      });
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backendUrl = String.fromEnvironment('HILDORS_API_BASE_URL');
    if (backendUrl.isNotEmpty) {
      return RemoteCatalogPage(
        load: () => RemoteCatalogRepository(backendUrl).load(),
        loadLayout: () =>
            RemoteLayoutRepository(backendUrl).loadPage('collection'),
        packageActions: (package) => OwnedDownloadButton(package: package),
        clipActions: (package, clip) =>
            OwnedDownloadButton(package: package, clip: clip),
      );
    }
    final items = filterCollectionCatalog(
        source: source, format: format, topic: topic, query: query);
    return CustomScrollView(
        key: const PageStorageKey('collection-catalog'),
        slivers: [
          SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Container(
                          width: 3, height: 20, color: const Color(0xff55dce6)),
                      const SizedBox(width: 8),
                      const Text('探索角色世界',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 12),
                    TextField(
                        controller: searchController,
                        onChanged: (value) => setState(() => query = value),
                        decoration: InputDecoration(
                            hintText: '搜索角色、视频或题材',
                            prefixIcon: const Icon(Icons.search, size: 21),
                            filled: true,
                            fillColor: const Color(0xff111b27),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xff293949))),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12))),
                    const SizedBox(height: 10),
                    _filters('出处', ['全部', 'HILDORS 出品', '创作者作品'], source,
                        (v) => setState(() => source = v)),
                    _filters('形式', ['全部', '单条视频', '角色视频包'], format,
                        (v) => setState(() => format = v)),
                    _filters('题材', ['全部', '神话', '游戏', '二次元', '未来时空', '音乐舞台'],
                        topic, (v) => setState(() => topic = v)),
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(children: [
                          Expanded(
                              child: Text('${items.length} 项内容',
                                  style: const TextStyle(
                                      color: Color(0xffb3c3d5), fontSize: 12))),
                          if (source != '全部' ||
                              format != '全部' ||
                              topic != '全部' ||
                              query.isNotEmpty)
                            TextButton(
                                onPressed: _reset, child: const Text('清除筛选')),
                        ])),
                  ]))),
          if (items.isEmpty)
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      const Icon(Icons.search_off,
                          size: 36, color: Color(0xff8196ad)),
                      const SizedBox(height: 12),
                      const Text('暂无符合条件的内容'),
                      const SizedBox(height: 6),
                      const Text('试试其他题材或内容形式',
                          style: TextStyle(color: Color(0xff9eafc3))),
                      TextButton(
                          onPressed: _reset, child: const Text('查看全部内容')),
                    ]))),
          SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverLayoutBuilder(builder: (context, constraints) {
                final width = (constraints.crossAxisExtent - 16) / 3;
                // Measure actual font metrics, including accessibility scaling.
                final textHeight = items.fold<double>(0, (largest, item) {
                  double measure(String text, TextStyle style, int lines) {
                    final painter = TextPainter(
                      text: TextSpan(
                          text: text,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .merge(style)),
                      textScaler: MediaQuery.textScalerOf(context),
                      textDirection: Directionality.of(context),
                      maxLines: lines,
                      ellipsis: '…',
                    )..layout(maxWidth: width - 16);
                    final result = painter.height;
                    painter.dispose();
                    return result;
                  }

                  final total = measure(
                          item.title,
                          const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w600),
                          2) +
                      measure(item.credit, const TextStyle(fontSize: 10), 1) +
                      measure(item.isConcept ? '视频包 · 概念示例' : '单条视频 · Demo',
                          const TextStyle(fontSize: 10), 2);
                  return total > largest ? total : largest;
                });
                final height = width + textHeight.ceilToDouble() + 26;
                return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 12,
                        mainAxisExtent: height),
                    delegate: SliverChildBuilderDelegate(
                        (context, index) => _tile(items[index]),
                        childCount: items.length));
              })),
        ]);
  }

  Widget _filters(String label, List<String> options, String selected,
          ValueChanged<String> onSelect) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Text(label,
                style: const TextStyle(color: Color(0xff8fabc0), fontSize: 12)),
            const SizedBox(width: 10),
            Expanded(
                child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final option in options)
                        Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(option),
                              selected: selected == option,
                              showCheckmark: false,
                              onSelected: (_) => onSelect(option),
                              labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: selected == option
                                      ? const Color(0xff93f3f1)
                                      : const Color(0xffb8c7d7)),
                              selectedColor: const Color(0xff163b46),
                              backgroundColor: const Color(0xff101a26),
                              side: BorderSide(
                                  color: selected == option
                                      ? const Color(0xff367481)
                                      : const Color(0xff23303f)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              visualDensity: VisualDensity.compact,
                            )),
                    ]))),
          ]));

  Widget _tile(CollectionCatalogItem item) => Semantics(
        label:
            '${item.title}，${item.source}，${item.format}${item.isConcept ? '，概念示例暂无视频' : ''}',
        button: true,
        child: Material(
            color: const Color(0xff101a27),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
                onTap: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) {
                    if (item.creatorIndex != null) {
                      final character =
                          characterGateCatalog[item.creatorIndex!];
                      return FreeCharacterDetailPage(
                          characterId: character.$1,
                          name: character.$2,
                          category: character.$3,
                          imagePath: character.$4,
                          repository:
                              const LocalCharacterEntitlementRepository());
                    }
                    return CharacterPackagePage(package: item.package!);
                  }));
                },
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                          aspectRatio: 1,
                          child: Stack(fit: StackFit.expand, children: [
                            Container(
                                color: const Color(0xff080e16),
                                child: Image.asset(item.cover,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.image_not_supported_outlined))),
                            Positioned(
                                right: 5,
                                bottom: 5,
                                child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                        color: const Color(0xdd0a1422),
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Icon(
                                        item.isConcept
                                            ? Icons.layers_outlined
                                            : Icons.play_arrow_rounded,
                                        size: 16,
                                        color: const Color(0xff9ee9ee)))),
                          ])),
                      Padding(
                          padding: const EdgeInsets.fromLTRB(8, 7, 8, 0),
                          child: Text(item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600))),
                      const Spacer(),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(item.credit,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xff8cd6df)))),
                      Padding(
                          padding: const EdgeInsets.fromLTRB(8, 3, 8, 8),
                          child: Text(
                              item.isConcept ? '视频包 · 概念示例' : '单条视频 · Demo',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xff9aabc0)))),
                    ]))),
      );
}
