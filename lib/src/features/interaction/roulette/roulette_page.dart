import 'package:flutter/material.dart';

import '../../../experience/experience_pack_manifest.dart';
import '../../../experience/projection_service.dart';
import 'roulette_demo_player.dart';
import 'roulette_game.dart';

class RoulettePage extends StatefulWidget {
  const RoulettePage({required this.projection, super.key});

  final ProjectionService projection;

  @override
  State<RoulettePage> createState() => _RoulettePageState();
}

class _RoulettePageState extends State<RoulettePage> {
  static const _demoRoot = 'assets/videos/chaos_party_demo';
  final _game = RouletteGame();
  final _nameController = TextEditingController();
  final _players = <String>[];
  RouletteRound? _round;
  ExperiencePackStatus? _packStatus;
  bool _drawing = false;
  String? _message;
  String _demoStage = 'idle';

  @override
  void initState() {
    super.initState();
    _inspectPack();
  }

  Future<void> _inspectPack() async {
    try {
      final manifest = await ExperiencePackRepository().loadChaosParty();
      final status = await widget.projection.inspectPack(manifest);
      if (mounted) setState(() => _packStatus = status);
    } catch (error) {
      if (mounted) setState(() => _message = '无法检测派对素材：$error');
    }
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_players.any((player) => player.toLowerCase() == name.toLowerCase())) {
      setState(() => _message = '玩家名称不能重复');
      return;
    }
    if (_players.length >= 10) {
      setState(() => _message = '首版最多支持 10 位玩家');
      return;
    }
    setState(() {
      _players.add(name);
      _nameController.clear();
      _message = null;
    });
  }

  Future<void> _draw() async {
    if (_drawing) return;
    if (_players.length < 2) {
      setState(() => _message = '请先添加至少两位玩家');
      return;
    }
    setState(() {
      _drawing = true;
      _round = null;
      _message = '轮盘正在旋转…';
      _demoStage = 'roulette';
    });

    try {
      final spinOutcome =
          await widget.projection.present(const ExperienceResult(
        id: 'chaos_roulette',
        title: '轮盘旋转',
        deviceVideo: 'chaos_roulette.mp4',
      ));
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;

      final result = _game.draw(_players);
      setState(() {
        _round = result;
        _message = _projectionMessage(spinOutcome);
        _demoStage = 'point';
      });
      final revealOutcome = await widget.projection.present(ExperienceResult(
        id: 'chaos_point',
        title: result.player,
        deviceVideo: 'chaos_point.mp4',
        description: result.challenge,
      ));
      if (mounted) setState(() => _message = _projectionMessage(revealOutcome));
    } catch (error) {
      if (mounted) setState(() => _message = '全息联动失败，游戏可继续：$error');
    } finally {
      if (mounted) setState(() => _drawing = false);
    }
  }

  String _projectionMessage(ProjectionOutcome outcome) => switch (outcome) {
        ProjectionOutcome.projected => '已同步到全息设备',
        ProjectionOutcome.missingMaterial => '设备缺少派对素材，当前使用手机模式',
        ProjectionOutcome.phoneOnly => '手机独立模式 · 连接设备后可同步全息动画',
      };

  Future<void> _finishRound(bool success) async {
    try {
      await widget.projection.present(ExperienceResult(
        id: success ? 'chaos_success' : 'chaos_fail',
        title: success ? '挑战成功' : '挑战跳过',
        deviceVideo: success ? 'chaos_success.mp4' : 'chaos_fail.mp4',
      ));
    } catch (_) {
      // The phone game remains usable when the device disconnects mid-round.
    }
    if (!mounted) return;
    setState(() {
      _round = null;
      _message = success ? '挑战成功！准备下一轮' : '已跳过，准备下一轮';
      _demoStage = success ? 'success' : 'fail';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Holo Roulette')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('派对挑战轮盘', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text('添加 2–10 位玩家。每轮不会重复抽取，直到所有人都被抽中过。',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            _DeviceStatus(status: _packStatus),
            const SizedBox(height: 18),
            RouletteDemoPlayer(
              assetPath: '$_demoRoot/chaos_$_demoStage.mp4',
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  enabled: !_drawing,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addPlayer(),
                  decoration: const InputDecoration(
                    labelText: '玩家名字',
                    hintText: '例如 Jason',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _drawing ? null : _addPlayer,
                tooltip: '添加玩家',
                icon: const Icon(Icons.person_add_alt_1),
              ),
            ]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final player in _players)
                  InputChip(
                    label: Text(player),
                    onDeleted: _drawing
                        ? null
                        : () => setState(() => _players.remove(player)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              constraints: const BoxConstraints(minHeight: 260),
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primaryContainer, colors.tertiaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child: _drawing
                    ? const Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.casino_outlined, size: 72),
                        SizedBox(height: 18),
                        CircularProgressIndicator(),
                      ])
                    : _round == null
                        ? const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Icon(Icons.groups_2_outlined, size: 72),
                                SizedBox(height: 14),
                                Text('谁是下一位？'),
                              ])
                        : Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(_round!.player,
                                textAlign: TextAlign.center,
                                style:
                                    Theme.of(context).textTheme.displaySmall),
                            const SizedBox(height: 18),
                            Text(_round!.challenge,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge),
                          ]),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),
            if (_round == null)
              FilledButton.icon(
                onPressed: _drawing ? null : _draw,
                icon: const Icon(Icons.casino),
                label: const Text("WHO'S NEXT?"),
              )
            else
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _finishRound(false),
                    icon: const Icon(Icons.skip_next),
                    label: const Text('跳过'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _finishRound(true),
                    icon: const Icon(Icons.celebration),
                    label: const Text('挑战成功'),
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

class _DeviceStatus extends StatelessWidget {
  const _DeviceStatus({required this.status});

  final ExperiencePackStatus? status;

  @override
  Widget build(BuildContext context) {
    final value = status;
    final text = value == null
        ? '正在检测 Chaos Party Pack…'
        : !value.deviceConnected
            ? '手机独立模式'
            : value.installed
                ? '全息联动已就绪'
                : '全息设备缺少 ${value.missingFiles.length} 个素材';
    return Row(children: [
      Icon(value?.installed == true
          ? Icons.cast_connected
          : Icons.phone_android),
      const SizedBox(width: 8),
      Expanded(child: Text(text)),
    ]);
  }
}
