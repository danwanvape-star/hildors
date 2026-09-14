import 'dart:async';

import 'package:flutter/material.dart';

import '../../experience/projection_service.dart';
import 'holopet_behavior_scheduler.dart';
import 'holopet_profile.dart';
import 'holopet_repository.dart';
import 'holopet_state.dart';

class HoloPetPage extends StatefulWidget {
  const HoloPetPage(
      {required this.projection,
      this.profile = const HoloPetProfile.neonShiba(),
      this.store,
      super.key});
  final ProjectionService projection;
  final HoloPetProfile profile;
  final HoloPetStore? store;
  @override
  State<HoloPetPage> createState() => _HoloPetPageState();
}

class _HoloPetPageState extends State<HoloPetPage> {
  late var _pet = HoloPetState(name: widget.profile.name);
  late final HoloPetStore _store = widget.store ?? FileHoloPetStore();
  final _scheduler = const HoloPetBehaviorScheduler();
  HoloPetAction? _busy;
  HoloPetAutonomousBehavior? _autonomousBehavior;
  Timer? _companionTimer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final snapshot = await _store.load(widget.profile.id);
    final restored = snapshot == null
        ? _pet
        : snapshot.pet.decay(DateTime.now().difference(snapshot.updatedAt));
    if (!mounted) return;
    setState(() {
      _pet = restored;
      _loading = false;
    });
    _configureCompanionTimer();
    unawaited(_save());
  }

  Future<void> _save() async {
    try {
      await _store.save(
        widget.profile.id,
        HoloPetSnapshot(pet: _pet, updatedAt: DateTime.now()),
      );
    } on Object {
      // A storage failure must not interrupt interaction or projection.
    }
  }

  void _configureCompanionTimer() {
    _companionTimer?.cancel();
    if (!_pet.companionMode) return;
    _companionTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => unawaited(_runAutonomousBehavior()),
    );
    unawaited(_runAutonomousBehavior());
  }

  Future<void> _runAutonomousBehavior() async {
    if (!_pet.companionMode || !widget.projection.deviceConnected) return;
    final behavior = _scheduler.select(_pet, DateTime.now());
    if (_autonomousBehavior == behavior) return;
    if (!mounted) return;
    setState(() => _autonomousBehavior = behavior);
    try {
      await widget.projection.present(ExperienceResult(
        id: 'holopet_auto_${behavior.name}',
        title: behavior.label,
        deviceVideo: behavior.deviceVideo,
      ));
    } on Object {
      // Autonomous playback is best-effort and never blocks phone-side care.
    }
  }

  void _setCompanionMode(bool enabled) {
    setState(() {
      _pet = _pet.setCompanionMode(enabled);
      if (!enabled) _autonomousBehavior = null;
    });
    _configureCompanionTimer();
    unawaited(_save());
  }

  @override
  void dispose() {
    _companionTimer?.cancel();
    unawaited(_save());
    super.dispose();
  }

  Future<void> _act(HoloPetAction action) async {
    if (_busy != null) return;
    setState(() {
      _busy = action;
      _pet = _pet.perform(action);
    });
    unawaited(_save());
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
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                    _PetStage(
                        pet: _pet, onGreet: () => _act(HoloPetAction.greet)),
                    const SizedBox(height: 18),
                    _IdentityCard(profile: widget.profile, pet: _pet),
                    const SizedBox(height: 12),
                    Card(
                      child: SwitchListTile(
                        value: _pet.companionMode,
                        onChanged: _setCompanionMode,
                        secondary: const Icon(Icons.nightlight_round),
                        title: const Text('陪伴模式'),
                        subtitle: Text(_pet.companionMode
                            ? (_autonomousBehavior == null
                                ? '宠物将自主生活，连接 P20 后自动呈现动作。'
                                : '${_autonomousBehavior!.label} · P20 自主呈现中')
                            : '开启后不需要持续操作宠物。'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ObservationCard(text: _pet.observation),
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
                              label: '活力',
                              value: _pet.energy,
                              icon: Icons.bolt))
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
                    _MemoriesCard(memories: _pet.memories),
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

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile, required this.pet});
  final HoloPetProfile profile;
  final HoloPetState pet;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.badge_outlined)),
          title: Text(profile.characterName),
          subtitle: Text(
            pet.discoveredTraits.isEmpty
                ? '性格仍在观察中 · ${profile.originLabel}'
                : '${pet.discoveredTraits.join(' · ')} · ${profile.originLabel}',
          ),
          trailing: Text('${pet.interactions} 次互动'),
        ),
      );
}

class _ObservationCard extends StatelessWidget {
  const _ObservationCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.visibility_outlined,
                color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今日观察', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(text),
              ],
            )),
          ]),
        ),
      );
}

class _MemoriesCard extends StatelessWidget {
  const _MemoriesCard({required this.memories});
  final List<HoloPetMemory> memories;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.auto_stories_outlined),
              const SizedBox(width: 10),
              Text('共同记忆', style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 10),
            if (memories.isEmpty)
              const Text('完成第一次互动后，这里会记录属于你们的故事。')
            else
              for (final memory in memories)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.brightness_1, size: 10),
                  title: Text(memory.title),
                  subtitle: Text(memory.detail),
                ),
          ]),
        ),
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
