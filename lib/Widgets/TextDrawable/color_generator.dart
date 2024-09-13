/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

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

  Color getColorByString(String text) {
    final int hash = text.hashCode;
    final int index = hash % _materialColors.length;
    return _materialColors[index];
  }
}
