import 'package:flutter/material.dart';

import '../../experience/experience_pack_manifest.dart';
import '../../experience/projection_service.dart';
import 'tarot/tarot_page.dart';
import 'tarot/three_card_tarot_page.dart';

class InteractionPage extends StatefulWidget {
  const InteractionPage({required this.projection, super.key});

  final ProjectionService projection;

  @override
  State<InteractionPage> createState() => _InteractionPageState();
}

class _InteractionPageState extends State<InteractionPage> {
  ExperiencePackManifest? _manifest;
  ExperiencePackStatus? _status;
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadManifest();
  }

  Future<void> _loadManifest() async {
    try {
      final manifest = await ExperiencePackRepository().loadTarotMajor();
      final status = await widget.projection.inspectPack(manifest);
      if (mounted) {
        setState(() {
          _manifest = manifest;
          _status = status;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = '无法读取玩法包：$error');
    }
  }

  Future<void> _inspectPack() async {
    final manifest = _manifest;
    if (manifest == null || _checking) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final status = await widget.projection.inspectPack(
        manifest,
        forceRefresh: true,
      );
      if (mounted) setState(() => _status = status);
    } catch (error) {
      if (mounted) setState(() => _error = '检测玩法包失败：$error');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mystic Portal')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _PackStatusCard(
              manifest: _manifest,
              status: _status,
              checking: _checking,
              error: _error,
              onRefresh: _inspectPack,
              onShowMissing: _showMissingFiles,
            ),
            const SizedBox(height: 24),
            Text('推荐玩法', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TarotPage(projection: widget.projection),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(22),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        child: Icon(Icons.style, size: 30),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '塔罗 · 每日一牌',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text('手机抽牌，全息设备播放对应牌面动画'),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.view_carousel_outlined),
                ),
                title: const Text('塔罗 · 三牌阵'),
                subtitle: const Text('过去、现在、未来三张牌，逐张联动全息视频'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ThreeCardTarotPage(projection: widget.projection),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('更多玩法', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const _ComingSoon(
              icon: Icons.confirmation_number_outlined,
              title: '幸运抽签',
            ),
            const _ComingSoon(icon: Icons.stars_outlined, title: '星座互动'),
            const _ComingSoon(
              icon: Icons.psychology_alt_outlined,
              title: '趣味测试',
            ),
          ],
        ),
      );

  void _showMissingFiles() {
    final missing = _status?.missingFiles ?? const <String>[];
    if (missing.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('缺少 ${missing.length} 个视频'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: missing.length,
            itemBuilder: (_, index) => Text(missing[index]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _PackStatusCard extends StatelessWidget {
  const _PackStatusCard({
    required this.manifest,
    required this.status,
    required this.checking,
    required this.error,
    required this.onRefresh,
    required this.onShowMissing,
  });

  final ExperiencePackManifest? manifest;
  final ExperiencePackStatus? status;
  final bool checking;
  final String? error;
  final VoidCallback onRefresh;
  final VoidCallback onShowMissing;

  @override
  Widget build(BuildContext context) {
    final pack = manifest;
    final state = status;
    final connected = state?.deviceConnected ?? false;
    final title =
        pack == null ? '正在读取塔罗玩法包' : '${pack.title} · ${pack.version}';
    final subtitle = error ??
        (state == null
            ? '正在读取清单…'
            : !connected
                ? '连接设备后可检测 ${state.totalFiles} 个视频素材'
                : state.installed
                    ? '玩法包完整，可以进行全息联动'
                    : '已有 ${state.availableFiles}/${state.totalFiles}，缺少 ${state.missingFiles.length} 个视频');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(state?.installed == true
                    ? Icons.verified
                    : Icons.inventory_2_outlined),
                const SizedBox(width: 10),
                Expanded(child: Text(title)),
                IconButton(
                  onPressed: pack == null || checking ? null : onRefresh,
                  tooltip: '检测设备素材',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle),
            if (checking) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ] else if (connected && state != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: state.progress),
              if (state.missingFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onShowMissing,
                  icon: const Icon(Icons.list_alt),
                  label: const Text('查看缺失清单'),
                ),
                const Text('上传协议细节确认后，这里将提供一键安装玩法包。'),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: const Text('即将上线'),
        ),
      );
}
