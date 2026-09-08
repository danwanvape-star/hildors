import 'dart:math';

const familyFriendlyChallenges = <String>[
  '模仿现场一位玩家 10 秒钟，让大家猜是谁。',
  '用播音员的声音介绍右边的玩家。',
  '表演一种动物，直到有人猜对。',
  '不说话，用动作演出“早上起晚了”。',
  '给现场每个人起一个超级英雄名字。',
  '连续说出五种圆形物品，不能停顿。',
  '哼一段大家熟悉的旋律，让其他人猜歌名。',
  '保持最夸张的胜利姿势 10 秒钟。',
  '和左边的玩家完成一次慢动作击掌。',
  '用三个词描述今天的聚会。',
  '讲一个冷笑话；如果没人笑，就自己大笑三声。',
  '选一位玩家，和对方互相模仿 10 秒钟。',
];

class RouletteRound {
  const RouletteRound({required this.player, required this.challenge});

  final String player;
  final String challenge;
}

class RouletteGame {
  RouletteGame({Random? random}) : _random = random ?? Random();

  final Random _random;
  final List<String> _bag = [];
  String? _lastPlayer;

  RouletteRound draw(List<String> players, {List<String>? challenges}) {
    final normalized = players
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalized.length < 2) {
      throw ArgumentError('至少需要两位不同的玩家');
    }

    _bag.removeWhere((name) => !normalized.contains(name));
    if (_bag.isEmpty) {
      _bag.addAll(normalized);
      _bag.shuffle(_random);
      if (_bag.length > 1 && _bag.last == _lastPlayer) {
        final swapIndex = _bag.indexWhere((name) => name != _lastPlayer);
        final value = _bag[swapIndex];
        _bag[swapIndex] = _bag.last;
        _bag[_bag.length - 1] = value;
      }
    }

    final player = _bag.removeLast();
    _lastPlayer = player;
    final deck = challenges ?? familyFriendlyChallenges;
    if (deck.isEmpty) throw ArgumentError('挑战题库不能为空');
    return RouletteRound(
      player: player,
      challenge: deck[_random.nextInt(deck.length)],
    );
  }
}
