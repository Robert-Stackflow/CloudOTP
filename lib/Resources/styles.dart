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

import 'package:flutter/material.dart';

import 'colors.dart';

class MyStyles {
  static const TextStyle text = TextStyle(
      fontSize: 14,
      color: MyColors.textColor,
      textBaseline: TextBaseline.alphabetic);
  static const TextStyle textDark = TextStyle(
      fontSize: 14,
      color: MyColors.textColorDark,
      textBaseline: TextBaseline.alphabetic);

  static const TextStyle labelSmallDark = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 12,
    letterSpacing: 0.1,
    color: MyColors.textGrayColorDark,
  );

  static const TextStyle labelSmall = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 12,
    letterSpacing: 0.1,
    color: MyColors.textGrayColor,
  );

  static const TextStyle captionDark = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 13,
    letterSpacing: 0.1,
    color: MyColors.textGrayColorDark,
  );

  static const TextStyle caption = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 13,
    letterSpacing: 0.1,
    color: MyColors.textGrayColor,
  );

  static const TextStyle titleDark = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 16,
    letterSpacing: 0.1,
    color: MyColors.textColorDark,
  );

  static const TextStyle title = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 16,
    letterSpacing: 0.1,
    color: MyColors.textColor,
  );

  static const TextStyle titleLargeDark = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 17,
    letterSpacing: 0.18,
    color: MyColors.textColorDark,
  );

  static const TextStyle titleLarge = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 17,
    letterSpacing: 0.18,
    color: MyColors.textColor,
  );

  static const TextStyle bodySmallDark = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 13,
    letterSpacing: 0.1,
    color: MyColors.textColorDark,
  );

  static const TextStyle bodySmall = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 13,
    letterSpacing: 0.1,
    color: MyColors.textColor,
  );

  static const TextStyle bodyMediumDark = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 14,
    letterSpacing: 0.1,
    color: MyColors.textColorDark,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 14,
    letterSpacing: 0.1,
    color: MyColors.textColor,
  );
}
