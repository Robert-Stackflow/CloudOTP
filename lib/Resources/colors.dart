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

import '../Utils/utils.dart';
import '../Widgets/Window/window_button.dart';

class MyColors {
  static const Color defaultPrimaryColor = Color(0xFF009BFF);
  static const Color defaultPrimaryColorDark = Color(0xFF009BFF);

  static const Color deepGreenPrimaryColor = Color(0xFF3790a4);
  static const Color deepGreenPrimaryColorDark = Color(0xFF3790a4);

  static const Color biliPinkPrimaryColor = Color(0xFFF588a8);
  static const Color biliPinkPrimaryColorDark = Color(0xFFF588a8);

  static const Color kuanGreenPrimaryColor = Color(0xFF11b667);
  static const Color kuanGreenPrimaryColorDark = Color(0xFF11b667);

  static const Color quietGreyPrimaryColor = Color(0xFF454d66);
  static const Color quietGreyPrimaryColorDark = Color(0xFF454d66);

  static const Color noblePurplePrimaryColor = Color(0xFF272643);
  static const Color noblePurplePrimaryColorDark = Color(0xFF272643);

  static const Color cherryRedPrimaryColor = Color(0xFFe74645);
  static const Color cherryRedPrimaryColorDark = Color(0xFFe74645);

  static const Color mysteriousBrownPrimaryColor = Color(0xFF361d32);
  static const Color mysteriousBrownPrimaryColorDark = Color(0xFF361d32);

  static const Color brightYellowPrimaryColor = Color(0xFFf8be5f);
  static const Color brightYellowPrimaryColorDark = Color(0xFFf8be5f);

  static const Color zhihuBluePrimaryColor = Color(0xFF0084ff);
  static const Color zhihuBluePrimaryColorDark = Color(0xFF0084ff);

  static const Color background = Color(0xFFF7F8F9);
  static const Color backgroundDark = Color(0xFF121212);

  static const Color appBarBackground = Color(0xFFF7F8F9);
  static const Color appBarBackgroundDark = Color(0xFF121212);

  static const Color materialBackground = Color(0xFFFFFFFF);
  static const Color materialBackgroundDark = Color(0xFF252525);

  static const Color splashColor = Color(0x44c8c8c8);
  static const Color splashColorDark = Color(0x20cccccc);

  static const Color highlightColor = Color(0x44bcbcbc);
  static const Color highlightColorDark = Color(0x20cfcfcf);

  static const Color iconColor = Color(0xFF333333);
  static const Color iconColorDark = Color(0xFFB8B8B8);

  static const Color shadowColor = Color(0xFF666666);
  static const Color shadowColorDark = Color(0xFFFFFFFF);

  static const Color textColor = Color(0xFF333333);
  static const Color textColorDark = Color(0xFFB8B8B8);

  static const Color textGrayColor = Color(0xFF999999);
  static const Color textGrayColorDark = Color(0xFF616161);

  static const Color textDisabledColor = Color(0xFFD4E2FA);
  static const Color textDisabledColorDark = Color(0xFFCEDBF2);

  static const Color buttonTextColor = Color(0xFFF2F2F2);
  static const Color buttonTextColorDark = Color(0xFFF2F2F2);

  static const Color buttonDisabledColor = Color(0xFF96BBFA);
  static const Color buttonDisabledColorDark = Color(0xFF83A5E0);

  static const Color dividerColor = Color(0xFFF5F6F7);
  static const Color dividerColorDark = Color(0xFF222222);

  static const Color hotTagBackground = Color(0xFFFFF6F0);
  static const Color hotTagBackgroundDark = Color(0xFF3E2723);
  static const Color hotTagTextColor = Color(0xFFFB923C);
  static const Color hotTagTextColorDark = Color(0xFFF57F17);

  static const Color linkColor = Color(0xFF009BFF);
  static const Color linkColorDark = Color(0xFF009BFF);

  static const Color favoriteButtonColor = Color(0xFFFFD54F);
  static const Color shareButtonColor = Color(0xFF29B6F6);

  static const Color likeButtonColor = Color(0xFFF06292);

  static getStayOnTopButtonColors(BuildContext context) {
    return WindowButtonColors(
      normal: Theme.of(context).splashColor,
      mouseOver: Theme.of(context).splashColor,
      mouseDown: Theme.of(context).splashColor,
      iconNormal: Theme.of(context).iconTheme.color,
      iconMouseOver: Theme.of(context).iconTheme.color,
      iconMouseDown: Theme.of(context).iconTheme.color,
    );
  }

  static getNormalButtonColors(BuildContext context) {
    return WindowButtonColors(
      mouseOver: Theme.of(context).splashColor,
      mouseDown: Theme.of(context).splashColor,
      iconNormal: Theme.of(context).iconTheme.color,
      iconMouseOver: Theme.of(context).iconTheme.color,
      iconMouseDown: Theme.of(context).iconTheme.color,
    );
  }

  static getCloseButtonColors(BuildContext context) {
    return WindowButtonColors(
      mouseOver: const Color(0xFFD32F2F),
      mouseDown: const Color(0xFFB71C1C),
      iconNormal: Theme.of(context).iconTheme.color,
      iconMouseOver: Colors.white,
      iconMouseDown: Colors.white,
    );
  }

  static getLinkColor(BuildContext context) {
    return Utils.currentBrightness(context) == Brightness.light
        ? Theme.of(context).primaryColor
        : Theme.of(context).primaryColor;
  }

  static getHotTagBackground(BuildContext context) {
    return Utils.currentBrightness(context) == Brightness.light
        ? hotTagBackground
        : hotTagBackgroundDark;
  }

  static getHotTagTextColor(BuildContext context) {
    return Utils.currentBrightness(context) == Brightness.light
        ? hotTagTextColor
        : hotTagTextColorDark;
  }

  MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}
