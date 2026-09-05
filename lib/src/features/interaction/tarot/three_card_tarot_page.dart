import 'dart:math';

import 'package:flutter/material.dart';

import '../../../experience/projection_service.dart';
import 'tarot_deck.dart';

class ThreeCardTarotPage extends StatefulWidget {
  const ThreeCardTarotPage({required this.projection, super.key});

  final ProjectionService projection;

  @override
  State<ThreeCardTarotPage> createState() => _ThreeCardTarotPageState();
}

class _ThreeCardTarotPageState extends State<ThreeCardTarotPage> {
  static const _positions = ['过去', '现在', '未来'];
  final _random = Random();
  List<TarotCardResult> _cards = const [];
  int? _projectingIndex;
  String? _message;

  void _draw() {
    setState(() {
      _cards = drawTarotSpread(_random, 3);
      _projectingIndex = null;
      _message = widget.projection.deviceConnected
          ? '点击任意牌，同步到全息设备'
          : '手机独立模式 · 连接设备后可同步牌面';
    });
  }

  Future<void> _project(int index) async {
    if (_projectingIndex != null) return;
    setState(() {
      _projectingIndex = index;
      _message = null;
    });
    try {
      final outcome = await widget.projection.present(_cards[index]);
      if (!mounted) return;
      setState(() {
        _message = switch (outcome) {
          ProjectionOutcome.projected => '“${_positions[index]}”牌已同步到全息设备',
          ProjectionOutcome.missingMaterial =>
            '设备缺少 ${_cards[index].deviceVideo}，请先上传对应素材',
          ProjectionOutcome.phoneOnly => '当前为手机独立模式，未发送到设备',
        };
      });
    } catch (error) {
      if (mounted) setState(() => _message = '设备投影失败：$error');
    } finally {
      if (mounted) setState(() => _projectingIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('三牌阵')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('在心中默念问题，三张牌分别象征过去、现在与未来。'),
              const SizedBox(height: 20),
              if (_cards.isEmpty)
                _EmptySpread(onDraw: _draw)
              else ...[
                for (var index = 0; index < _cards.length; index++) ...[
                  _SpreadCard(
                    position: _positions[index],
                    card: _cards[index],
                    busy: _projectingIndex == index,
                    onTap: () => _project(index),
                  ),
                  if (index < _cards.length - 1) const SizedBox(height: 10),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _projectingIndex == null ? _draw : null,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('重新抽取'),
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 14),
                Text(_message!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 12),
              Text(
                '娱乐体验内容，不构成医疗、法律、投资或其他专业建议。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
}

class _EmptySpread extends StatelessWidget {
  const _EmptySpread({required this.onDraw});
  final VoidCallback onDraw;

  @override
  Widget build(BuildContext context) => Container(
        height: 340,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.view_carousel_outlined, size: 72),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onDraw,
              icon: const Icon(Icons.style),
              label: const Text('抽取三张牌'),
            ),
          ],
        ),
      );
}

class _SpreadCard extends StatelessWidget {
  const _SpreadCard({
    required this.position,
    required this.card,
    required this.busy,
    required this.onTap,
  });

  final String position;
  final TarotCardResult card;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(child: Text(position.substring(0, 1))),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(position,
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(card.title,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 5),
                      Text(card.description),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                busy
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cast_outlined),
              ],
            ),
          ),
        ),
      );
}
