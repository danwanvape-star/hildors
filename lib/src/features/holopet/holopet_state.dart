enum HoloPetAction { feed, play, rest, greet }

class HoloPetMemory {
  const HoloPetMemory(
      {required this.id, required this.title, required this.detail});

  final String id;
  final String title;
  final String detail;

  factory HoloPetMemory.fromJson(Map<String, dynamic> json) => HoloPetMemory(
        id: json['id'] as String? ?? 'memory',
        title: json['title'] as String? ?? '共同记忆',
        detail: json['detail'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'detail': detail,
      };
}

class HoloPetState {
  const HoloPetState(
      {this.name = '小光',
      this.level = 1,
      this.experience = 0,
      this.hunger = 72,
      this.happiness = 76,
      this.energy = 68,
      this.interactions = 0,
      this.playfulness = 0,
      this.affection = 0,
      this.calmness = 0,
      this.companionMode = false,
      this.memories = const []});
  final String name;
  final int level;
  final int experience;
  final int hunger;
  final int happiness;
  final int energy;
  final int interactions;
  final int playfulness;
  final int affection;
  final int calmness;
  final bool companionMode;
  final List<HoloPetMemory> memories;

  factory HoloPetState.fromJson(Map<String, dynamic> json) {
    int number(String key, int fallback) =>
        (json[key] as num?)?.toInt() ?? fallback;
    final rawMemories = json['memories'];
    return HoloPetState(
      name: json['name'] as String? ?? '小光',
      level: number('level', 1).clamp(1, 999),
      experience: number('experience', 0).clamp(0, 99),
      hunger: number('hunger', 72).clamp(0, 100),
      happiness: number('happiness', 76).clamp(0, 100),
      energy: number('energy', 68).clamp(0, 100),
      interactions: number('interactions', 0).clamp(0, 1000000),
      playfulness: number('playfulness', 0).clamp(0, 1000000),
      affection: number('affection', 0).clamp(0, 1000000),
      calmness: number('calmness', 0).clamp(0, 1000000),
      companionMode: json['companionMode'] as bool? ?? false,
      memories: rawMemories is List
          ? rawMemories
              .whereType<Map>()
              .map((item) =>
                  HoloPetMemory.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'level': level,
        'experience': experience,
        'hunger': hunger,
        'happiness': happiness,
        'energy': energy,
        'interactions': interactions,
        'playfulness': playfulness,
        'affection': affection,
        'calmness': calmness,
        'companionMode': companionMode,
        'memories': memories.map((memory) => memory.toJson()).toList(),
      };

  String get mood {
    if (energy < 25) return '困倦';
    if (hunger < 25) return '饿了';
    if (happiness >= 80) return '开心';
    return '平静';
  }

  double get levelProgress => experience / 100;

  List<String> get discoveredTraits {
    final traits = <String>[];
    if (interactions >= 3 && playfulness >= 2) traits.add('喜欢玩耍');
    if (interactions >= 3 && affection >= 2) traits.add('亲近主人');
    if (interactions >= 3 && calmness >= 2) traits.add('安静独立');
    return traits;
  }

  String get observation {
    if (energy < 25) return '$name 今天有些困，正在寻找舒服的位置。';
    if (hunger < 25) return '$name 开始四处寻找食物。';
    if (playfulness > affection && playfulness > calmness) {
      return '$name 最近更喜欢主动追逐玩具。';
    }
    if (affection > calmness) return '$name 看到你时更容易靠近前景。';
    if (calmness > 0) return '$name 独处时会安静地巡视自己的空间。';
    return '$name 正在观察你，继续相处会逐渐发现它的性格。';
  }

  HoloPetState perform(HoloPetAction action) {
    var nextHunger = hunger;
    var nextHappiness = happiness;
    var nextEnergy = energy;
    var nextPlayfulness = playfulness;
    var nextAffection = affection;
    var nextCalmness = calmness;
    final gained = switch (action) {
      HoloPetAction.feed => 12,
      HoloPetAction.play => 16,
      HoloPetAction.rest => 8,
      HoloPetAction.greet => 5,
    };
    switch (action) {
      case HoloPetAction.feed:
        nextHunger += 24;
        nextHappiness += 4;
        nextAffection += 1;
      case HoloPetAction.play:
        nextHunger -= 8;
        nextHappiness += 20;
        nextEnergy -= 14;
        nextPlayfulness += 2;
      case HoloPetAction.rest:
        nextHunger -= 4;
        nextEnergy += 28;
        nextCalmness += 2;
      case HoloPetAction.greet:
        nextHappiness += 8;
        nextEnergy -= 2;
        nextAffection += 2;
    }
    final totalExperience = experience + gained;
    final nextInteractions = interactions + 1;
    final nextMemories = [...memories];
    if (interactions == 0) {
      nextMemories.add(const HoloPetMemory(
        id: 'first_interaction',
        title: '第一次回应',
        detail: '你们完成了第一次互动。',
      ));
    }
    return HoloPetState(
        name: name,
        level: level + totalExperience ~/ 100,
        experience: totalExperience % 100,
        hunger: nextHunger.clamp(0, 100),
        happiness: nextHappiness.clamp(0, 100),
        energy: nextEnergy.clamp(0, 100),
        interactions: nextInteractions,
        playfulness: nextPlayfulness,
        affection: nextAffection,
        calmness: nextCalmness,
        companionMode: companionMode,
        memories: nextMemories);
  }

  HoloPetState setCompanionMode(bool enabled) => HoloPetState(
        name: name,
        level: level,
        experience: experience,
        hunger: hunger,
        happiness: happiness,
        energy: energy,
        interactions: interactions,
        playfulness: playfulness,
        affection: affection,
        calmness: calmness + (enabled && !companionMode ? 1 : 0),
        companionMode: enabled,
        memories: memories,
      );

  HoloPetState decay(Duration elapsed) {
    final hours = elapsed.inHours;
    if (hours <= 0) return this;
    return HoloPetState(
        name: name,
        level: level,
        experience: experience,
        hunger: (hunger - hours * 3).clamp(0, 100),
        happiness: (happiness - hours * 2).clamp(0, 100),
        energy: (energy - hours).clamp(0, 100),
        interactions: interactions,
        playfulness: playfulness,
        affection: affection,
        calmness: calmness,
        companionMode: companionMode,
        memories: memories);
  }
}

String videoForPetAction(HoloPetAction action) => switch (action) {
      HoloPetAction.feed => 'holopet_feed.mp4',
      HoloPetAction.play => 'holopet_play.mp4',
      HoloPetAction.rest => 'holopet_sleep.mp4',
      HoloPetAction.greet => 'holopet_greet.mp4',
    };
