import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/interaction/roulette/roulette_game.dart';

void main() {
  test('every player is selected once before the bag resets', () {
    final game = RouletteGame(random: Random(7));
    final players = ['Amy', 'Bo', 'Chen'];

    final firstCycle = List.generate(
      players.length,
      (_) => game.draw(players, challenges: ['test']).player,
    );

    expect(firstCycle.toSet(), players.toSet());
  });

  test('the last player is not immediately repeated in a new cycle', () {
    final game = RouletteGame(random: Random(2));
    final players = ['Amy', 'Bo'];
    final first = game.draw(players, challenges: ['test']).player;
    final second = game.draw(players, challenges: ['test']).player;
    final third = game.draw(players, challenges: ['test']).player;

    expect(second, isNot(first));
    expect(third, isNot(second));
  });

  test('requires at least two distinct non-empty players', () {
    final game = RouletteGame(random: Random(1));

    expect(
      () => game.draw(['Amy', ' Amy ', ''], challenges: ['test']),
      throwsArgumentError,
    );
  });
}
