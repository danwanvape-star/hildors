enum HoloPetAction { feed, play, rest, greet }

class HoloPetState {
  const HoloPetState(
      {this.name = '小光',
      this.level = 1,
      this.experience = 0,
      this.hunger = 72,
      this.happiness = 76,
      this.energy = 68});
  final String name;
  final int level;
  final int experience;
  final int hunger;
  final int happiness;
  final int energy;

  String get mood {
    if (energy < 25) return '困倦';
    if (hunger < 25) return '饿了';
    if (happiness >= 80) return '开心';
    return '平静';
  }

  double get levelProgress => experience / 100;

  HoloPetState perform(HoloPetAction action) {
    var nextHunger = hunger;
    var nextHappiness = happiness;
    var nextEnergy = energy;
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
      case HoloPetAction.play:
        nextHunger -= 8;
        nextHappiness += 20;
        nextEnergy -= 14;
      case HoloPetAction.rest:
        nextHunger -= 4;
        nextEnergy += 28;
      case HoloPetAction.greet:
        nextHappiness += 8;
        nextEnergy -= 2;
    }
    final totalExperience = experience + gained;
    return HoloPetState(
        name: name,
        level: level + totalExperience ~/ 100,
        experience: totalExperience % 100,
        hunger: nextHunger.clamp(0, 100),
        happiness: nextHappiness.clamp(0, 100),
        energy: nextEnergy.clamp(0, 100));
  }

  HoloPetState decay(Duration elapsed) {
    final hours = elapsed.inHours;
    if (hours <= 0) return this;
    return HoloPetState(
        name: name,
        level: level,
        experience: experience,
        hunger: (hunger - hours * 3).clamp(0, 100),
        happiness: (happiness - hours * 2).clamp(0, 100),
        energy: (energy - hours).clamp(0, 100));
  }
}

String videoForPetAction(HoloPetAction action) => switch (action) {
      HoloPetAction.feed => 'holopet_feed.mp4',
      HoloPetAction.play => 'holopet_play.mp4',
      HoloPetAction.rest => 'holopet_sleep.mp4',
      HoloPetAction.greet => 'holopet_greet.mp4',
    };
