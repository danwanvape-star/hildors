import 'dart:math';

import '../../../experience/projection_service.dart';

class TarotCardResult extends ExperienceResult {
  TarotCardResult({
    required this.number,
    required this.cardName,
    required this.reversed,
    required super.description,
  }) : super(
          id: 'tarot_$number',
          title: reversed ? '$cardName · 逆位' : '$cardName · 正位',
          deviceVideo: 'tarot_${number.toString().padLeft(2, '0')}.mp4',
        );

  final int number;
  final String cardName;
  final bool reversed;
}

const majorArcanaNames = <String>[
  '愚者',
  '魔术师',
  '女祭司',
  '皇后',
  '皇帝',
  '教皇',
  '恋人',
  '战车',
  '力量',
  '隐者',
  '命运之轮',
  '正义',
  '倒吊人',
  '死神',
  '节制',
  '恶魔',
  '高塔',
  '星星',
  '月亮',
  '太阳',
  '审判',
  '世界',
];

TarotCardResult createTarotResult(int index, {required bool reversed}) {
  if (index < 0 || index >= majorArcanaNames.length) {
    throw RangeError.range(index, 0, majorArcanaNames.length - 1, 'index');
  }
  final orientation =
      reversed ? '换个角度审视阻力，也许答案藏在被忽略的细节里。' : '顺着当下的能量行动，同时保持清醒与耐心。';
  return TarotCardResult(
    number: index,
    cardName: majorArcanaNames[index],
    reversed: reversed,
    description: orientation,
  );
}

List<TarotCardResult> drawTarotSpread(Random random, int count) {
  if (count < 1 || count > majorArcanaNames.length) {
    throw RangeError.range(count, 1, majorArcanaNames.length, 'count');
  }
  final indexes = List<int>.generate(majorArcanaNames.length, (index) => index)
    ..shuffle(random);
  return indexes
      .take(count)
      .map((index) => createTarotResult(index, reversed: random.nextBool()))
      .toList(growable: false);
}
