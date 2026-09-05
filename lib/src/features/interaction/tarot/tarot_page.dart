import 'dart:math';

import 'package:flutter/material.dart';

import '../../../experience/projection_service.dart';
import 'tarot_deck.dart';

class TarotPage extends StatefulWidget {
  const TarotPage({required this.projection, super.key});

  final ProjectionService projection;

  @override
  State<TarotPage> createState() => _TarotPageState();
}

class _TarotPageState extends State<TarotPage> {
  final _random = Random();
  TarotCardResult? _result;
  bool _drawing = false;
  String? _projectionMessage;

  Future<void> _draw() async {
    if (_drawing) return;
    setState(() {
      _drawing = true;
      _projectionMessage = null;
    });
    final result = createTarotResult(
      _random.nextInt(majorArcanaNames.length),
      reversed: _random.nextBool(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() => _result = result);
    try {
      final outcome = await widget.projection.present(result);
      if (!mounted) return;
      setState(() {
        _projectionMessage = switch (outcome) {
          ProjectionOutcome.projected => '已同步到全息设备',
          ProjectionOutcome.missingMaterial =>
            '设备缺少 ${result.deviceVideo}，请先上传对应素材',
          ProjectionOutcome.phoneOnly => '手机独立模式 · 连接设备后可同步全息视频',
        };
      });
    } catch (error) {
      if (mounted) setState(() => _projectionMessage = '设备投影失败：$error');
    } finally {
      if (mounted) setState(() => _drawing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('每日一牌')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Icon(widget.projection.deviceConnected
                    ? Icons.cast_connected
                    : Icons.phone_android),
                const SizedBox(width: 8),
                Text(widget.projection.deviceConnected ? '全息联动模式' : '手机独立模式'),
              ],
            ),
            const SizedBox(height: 20),
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              height: 360,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _result == null
                      ? [
                          colors.surfaceContainerHighest,
                          colors.primaryContainer
                        ]
                      : [colors.primaryContainer, colors.tertiaryContainer],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colors.primary.withValues(alpha: .5)),
              ),
              child: Center(
                child: _drawing
                    ? const CircularProgressIndicator()
                    : _result == null
                        ? const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 72),
                              SizedBox(height: 16),
                              Text('静下心来，抽取今天的指引'),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_result!.number.toString().padLeft(2, '0'),
                                  style:
                                      Theme.of(context).textTheme.displayLarge),
                              const SizedBox(height: 12),
                              Text(_result!.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium),
                              const SizedBox(height: 20),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 28),
                                child: Text(_result!.description,
                                    textAlign: TextAlign.center),
                              ),
                            ],
                          ),
              ),
            ),
            if (_projectionMessage != null) ...[
              const SizedBox(height: 12),
              Text(_projectionMessage!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _drawing ? null : _draw,
              icon: const Icon(Icons.style),
              label: Text(_result == null ? '抽一张牌' : '重新抽牌'),
            ),
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
}
