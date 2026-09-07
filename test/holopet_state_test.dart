import 'package:flutter_test/flutter_test.dart';
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
}
