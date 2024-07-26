import 'dart:math';

import 'package:flutter/material.dart';

class ColorGenerator {
  ColorGenerator._internal();

  static final ColorGenerator _instance = ColorGenerator._internal();

  factory ColorGenerator() => _instance;

  Random random = Random();

  static final _materialColors = <Color>[
    const Color(0xffe57373),
    const Color(0xfff06292),
    const Color(0xffba68c8),
    const Color(0xff9575cd),
    const Color(0xff7986cb),
    const Color(0xff64b5f6),
    const Color(0xff4fc3f7),
    const Color(0xff4dd0e1),
    const Color(0xff4db6ac),
    const Color(0xff81c784),
    const Color(0xffaed581),
    const Color(0xffff8a65),
    const Color(0xffd4e157),
    const Color(0xffffd54f),
    const Color(0xffffb74d),
    const Color(0xffa1887f),
    const Color(0xff90a4ae)
  ];

  Color getRandomColor() =>
      _materialColors[random.nextInt(_materialColors.length)];
}
