import 'holopet_state.dart';

enum HoloPetAutonomousBehavior { sleep, explore, play, approach }

extension HoloPetAutonomousBehaviorDetails on HoloPetAutonomousBehavior {
  String get label => switch (this) {
        HoloPetAutonomousBehavior.sleep => '正在休息',
        HoloPetAutonomousBehavior.explore => '正在巡视',
        HoloPetAutonomousBehavior.play => '正在玩耍',
        HoloPetAutonomousBehavior.approach => '正在靠近你',
      };

  String get deviceVideo => switch (this) {
        HoloPetAutonomousBehavior.sleep => 'holopet_sleep.mp4',
        HoloPetAutonomousBehavior.explore => 'holopet_play.mp4',
        HoloPetAutonomousBehavior.play => 'holopet_play.mp4',
        HoloPetAutonomousBehavior.approach => 'holopet_greet.mp4',
      };
}

class HoloPetBehaviorScheduler {
  const HoloPetBehaviorScheduler();

  HoloPetAutonomousBehavior select(HoloPetState pet, DateTime now) {
    if (pet.energy < 30 || now.hour >= 23 || now.hour < 7) {
      return HoloPetAutonomousBehavior.sleep;
    }
    if (pet.hunger < 30 || pet.affection > pet.playfulness + 1) {
      return HoloPetAutonomousBehavior.approach;
    }
    if (pet.playfulness > pet.calmness || now.minute.isEven) {
      return HoloPetAutonomousBehavior.play;
    }
    return HoloPetAutonomousBehavior.explore;
  }
}
