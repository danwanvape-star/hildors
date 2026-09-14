import 'package:flutter/material.dart';
import 'remote_catalog_repository.dart';

class RemoteCatalogPage extends StatefulWidget {
  const RemoteCatalogPage({super.key, required this.load, this.clipActions});
  final Future<List<RemoteCatalogPackage>> Function() load;

  /// Supplied only by a configured authenticated download integration.
  final Widget Function(RemoteCatalogPackage package, RemoteCatalogClip clip)?
      clipActions;
  @override
  State<RemoteCatalogPage> createState() => _RemoteCatalogPageState();
}

class _RemoteCatalogPageState extends State<RemoteCatalogPage> {
  late Future<List<RemoteCatalogPackage>> _request;
  String query = '', source = '全部';
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _request = Future.sync(widget.load);
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<RemoteCatalogPackage>>(
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
                  onPressed: () => setState(_reload), child: const Text('重试')),
            ]));
          }
          final items = (snapshot.data ?? [])
              .where((p) =>
                  (source == '全部' || p.source == source) &&
                  '${p.title} ${p.tags.join(' ')}'
                      .toLowerCase()
                      .contains(query.trim().toLowerCase()))
              .toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              const Expanded(
                  child: Text('内容库',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold))),
              IconButton(
                  tooltip: '刷新目录',
                  onPressed: () => setState(_reload),
                  icon: const Icon(Icons.refresh))
            ]),
            Text(
                widget.clipActions == null
                    ? '内容同步预览 · 下载与设备交付尚未开放'
                    : '包内视频可分别管理 · 设备交付尚未开放',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                    hintText: '搜索角色、视频或题材', prefixIcon: Icon(Icons.search))),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              for (final entry in const {
                '全部': '全部',
                'hildors': 'HILDORS 出品',
                'creator': '创作者作品'
              }.entries)
                ChoiceChip(
                    label: Text(entry.value),
                    selected: source == entry.key,
                    onSelected: (_) => setState(() => source = entry.key))
            ]),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(24), child: Text('暂无符合条件的内容')),
            LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth < 340 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.3
                  ? 2
                  : 3;
              final width =
                  (constraints.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(spacing: 10, runSpacing: 12, children: [
                for (final item in items)
                  SizedBox(
                      width: width,
                      child: Card(
                          clipBehavior: Clip.antiAlias,
                          margin: EdgeInsets.zero,
                          child: InkWell(
                              onTap: () => _details(item),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const AspectRatio(
                                        aspectRatio: 1,
                                        child: ColoredBox(
                                            color: Color(0xff101d2c),
                                            child: Center(
                                                child: Icon(
                                                    Icons
                                                        .video_library_outlined,
                                                    size: 36)))),
                                    Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(item.title,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                              const SizedBox(height: 6),
                                              Text(
                                                  '${item.format == 'single' ? '单条视频' : '角色视频包'} · ${item.clips.length}条',
                                                  style: const TextStyle(
                                                      fontSize: 11)),
                                            ])),
                                  ])))),
              ]);
            }),
          ]);
        },
      );

  void _details(RemoteCatalogPackage item) {
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => Scaffold(
              appBar: AppBar(title: Text(item.title)),
              body: ListView(padding: const EdgeInsets.all(16), children: [
                Text(item.source == 'hildors' ? 'HILDORS 出品' : '创作者作品'),
                const SizedBox(height: 12),
                Text(item.tags.join(' / ')),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('包内视频')),
                for (final clip in item.clips)
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                            leading: const Icon(Icons.movie_outlined),
                            title: Text(clip.title),
                            subtitle: Text(clip.durationSeconds == null
                                ? '时长待确认'
                                : '${clip.durationSeconds!.toStringAsFixed(1)} 秒')),
                        if (widget.clipActions != null)
                          widget.clipActions!(item, clip),
                      ]),
                const SizedBox(height: 16),
                Text(widget.clipActions == null
                    ? '当前仅支持浏览视频清单。下载与设备交付开放后，可选择包内视频加入播放列表。'
                    : '下载仅保存到App本地，不代表已发送到硬件。'),
              ]),
            )));
  }
}
