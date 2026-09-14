import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/holopet/holopet_behavior_scheduler.dart';
import 'package:hildors_cockpit/src/features/holopet/holopet_state.dart';

void main() {
  test('feeding improves hunger and grants experience', () {
    final pet = const HoloPetState(hunger: 50).perform(HoloPetAction.feed);
    expect(pet.hunger, 74);
    expect(pet.experience, 12);
  });
  test('playing trades energy and hunger for happiness', () {
    final pet = const HoloPetState().perform(HoloPetAction.play);
    expect(pet.happiness, 96);
    expect(pet.energy, 54);
    expect(pet.hunger, 64);
  });
  test('experience carries into a new level', () {
    final pet = const HoloPetState(level: 2, experience: 92)
        .perform(HoloPetAction.feed);
    expect(pet.level, 3);
    expect(pet.experience, 4);
  });
  test('decay clamps stats and maps actions to P20 assets', () {
    final pet = const HoloPetState(hunger: 4, happiness: 3, energy: 2)
        .decay(const Duration(hours: 3));
    expect(pet.hunger, 0);
    expect(pet.happiness, 0);
    expect(pet.energy, 0);
    expect(videoForPetAction(HoloPetAction.greet), 'holopet_greet.mp4');
  });

  test('behavior is discovered through repeated interaction', () {
    var pet = const HoloPetState();
    for (var i = 0; i < 3; i++) {
      pet = pet.perform(HoloPetAction.play);
    }
    expect(pet.discoveredTraits, contains('喜欢玩耍'));
    expect(pet.observation, contains('玩具'));
  });

  test('first interaction creates one memory only', () {
    final pet = const HoloPetState()
        .perform(HoloPetAction.greet)
        .perform(HoloPetAction.feed);
    expect(pet.memories, hasLength(1));
    expect(pet.memories.single.id, 'first_interaction');
  });

  test('companion mode preserves state and encourages calm behavior', () {
    final pet = const HoloPetState().setCompanionMode(true);
    expect(pet.companionMode, isTrue);
    expect(pet.calmness, 1);
    expect(pet.name, '小光');
  });

  test('pet state survives a JSON round trip', () {
    final original = const HoloPetState(name: '豆豆')
        .perform(HoloPetAction.play)
        .setCompanionMode(true);
    final restored = HoloPetState.fromJson(original.toJson());
    expect(restored.name, '豆豆');
    expect(restored.happiness, original.happiness);
    expect(restored.playfulness, original.playfulness);
    expect(restored.companionMode, isTrue);
    expect(restored.memories.single.id, 'first_interaction');
  });

  test('autonomous behavior respects sleep, hunger, and personality', () {
    const scheduler = HoloPetBehaviorScheduler();
    expect(
      scheduler.select(const HoloPetState(), DateTime(2026, 9, 8, 1)),
      HoloPetAutonomousBehavior.sleep,
    );
    expect(
      scheduler.select(
          const HoloPetState(hunger: 10), DateTime(2026, 9, 8, 12)),
      HoloPetAutonomousBehavior.approach,
    );
    expect(
      scheduler.select(
          const HoloPetState(playfulness: 4), DateTime(2026, 9, 8, 12, 1)),
      HoloPetAutonomousBehavior.play,
    );
  });
}
