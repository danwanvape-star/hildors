import 'package:flutter/material.dart';

import '../../experience/projection_service.dart';
import 'holopet_profile.dart';
import 'holopet_state.dart';

class HoloPetPage extends StatefulWidget {
  const HoloPetPage(
      {required this.projection,
      this.profile = const HoloPetProfile.neonShiba(),
      super.key});
  final ProjectionService projection;
  final HoloPetProfile profile;
  @override
  State<HoloPetPage> createState() => _HoloPetPageState();
}

class _HoloPetPageState extends State<HoloPetPage> {
  late var _pet = HoloPetState(name: widget.profile.name);
  HoloPetAction? _busy;

  Future<void> _act(HoloPetAction action) async {
    if (_busy != null) return;
    setState(() {
      _busy = action;
      _pet = _pet.perform(action);
    });
    ProjectionOutcome outcome;
    try {
      outcome = await widget.projection.present(ExperienceResult(
          id: 'holopet_${action.name}',
          title: action.name,
          deviceVideo: videoForPetAction(action)));
    } catch (_) {
      outcome = ProjectionOutcome.phoneOnly;
    }
    if (!mounted) return;
    setState(() => _busy = null);
    final message = switch (outcome) {
      ProjectionOutcome.projected => '${_pet.name} 已在 P20 上回应你',
      ProjectionOutcome.missingMaterial =>
        '养成状态已更新；P20 缺少 ${videoForPetAction(action)}',
      ProjectionOutcome.phoneOnly => '养成状态已更新；连接 P20 后可全息呈现',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('HOLOPET'), actions: [
          Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                  avatar: Icon(
                      widget.projection.deviceConnected
                          ? Icons.wifi
                          : Icons.wifi_off,
                      size: 16),
                  label: Text(
                      widget.projection.deviceConnected ? 'P20 在线' : '手机模式')))
        ]),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _PetStage(pet: _pet, onGreet: () => _act(HoloPetAction.greet)),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                    child: _Meter(
                        label: '饱食',
                        value: _pet.hunger,
                        icon: Icons.restaurant)),
                const SizedBox(width: 10),
                Expanded(
                    child: _Meter(
                        label: '心情',
                        value: _pet.happiness,
                        icon: Icons.favorite)),
                const SizedBox(width: 10),
                Expanded(
                    child: _Meter(
                        label: '活力', value: _pet.energy, icon: Icons.bolt))
              ]),
              const SizedBox(height: 22),
              Text('陪伴互动', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _Action(
                        icon: Icons.restaurant,
                        label: '喂食',
                        busy: _busy == HoloPetAction.feed,
                        onTap: () => _act(HoloPetAction.feed))),
                const SizedBox(width: 10),
                Expanded(
                    child: _Action(
                        icon: Icons.sports_esports,
                        label: '玩耍',
                        busy: _busy == HoloPetAction.play,
                        onTap: () => _act(HoloPetAction.play))),
                const SizedBox(width: 10),
                Expanded(
                    child: _Action(
                        icon: Icons.bedtime,
                        label: '休息',
                        busy: _busy == HoloPetAction.rest,
                        onTap: () => _act(HoloPetAction.rest)))
              ]),
              const SizedBox(height: 18),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        const Icon(Icons.view_in_ar_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(widget.projection.deviceConnected
                                ? '动作调用 P20 内的预制视频；素材缺失时仍保留手机端养成结果。'
                                : '当前可离线养成。连接 P20 局域网后，互动动作将同步到全息设备。'))
                      ]))),
            ]),
      );
}

class _PetStage extends StatelessWidget {
  const _PetStage({required this.pet, required this.onGreet});
  final HoloPetState pet;
  final VoidCallback onGreet;
  @override
  Widget build(BuildContext context) => Container(
      height: 300,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const RadialGradient(colors: [
            Color(0xFF124C55),
            Color(0xFF141225),
            Color(0xFF050509)
          ]),
          border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: .35))),
      child: Stack(alignment: Alignment.center, children: [
        Positioned(
            top: 18,
            left: 20,
            child: Text('LV.${pet.level}',
                style: const TextStyle(fontWeight: FontWeight.w700))),
        Positioned(top: 20, right: 20, child: Text(pet.mood)),
        Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: .08),
                boxShadow: [
                  BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: .2),
                      blurRadius: 50)
                ])),
        ClipRRect(
            borderRadius: BorderRadius.circular(90),
            child: Image.asset('assets/holopet/holopet_master.png',
                width: 170, height: 170, fit: BoxFit.cover)),
        Positioned(
            bottom: 22,
            left: 22,
            right: 22,
            child: Column(children: [
              Text(pet.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: pet.levelProgress),
              const SizedBox(height: 10),
              FilledButton.icon(
                  onPressed: onGreet,
                  icon: const Icon(Icons.waving_hand),
                  label: const Text('呼唤它'))
            ])),
      ]));
}

class _Meter extends StatelessWidget {
  const _Meter({required this.label, required this.value, required this.icon});
  final String label;
  final int value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Icon(icon, size: 20),
            const SizedBox(height: 6),
            Text('$value', style: Theme.of(context).textTheme.titleMedium),
            Text(label, style: Theme.of(context).textTheme.labelSmall)
          ])));
}

class _Action extends StatelessWidget {
  const _Action(
      {required this.icon,
      required this.label,
      required this.busy,
      required this.onTap});
  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FilledButton.tonal(
      onPressed: busy ? null : onTap,
      style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18)),
      child: Column(children: [
        busy
            ? const SizedBox.square(
                dimension: 22, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon),
        const SizedBox(height: 6),
        Text(label)
      ]));
}
