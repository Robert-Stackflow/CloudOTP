import 'package:flutter/material.dart';

import 'package:awesome_chewie/src/Utils/utils.dart';
import 'package:awesome_chewie/src/Widgets/Item/Button/window_button.dart';
import 'package:awesome_chewie/src/Resources/theme.dart';

class ChewieColors {
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
  static const Color starButtonColor = Color(0xFFf97316);
  static const Color unreadButtonColor = Color(0xFFff5c00);

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
      normal: Colors.transparent,
      mouseOver: Theme.of(context).splashColor,
      mouseDown: Theme.of(context).splashColor,
      iconNormal: Theme.of(context).iconTheme.color,
      iconMouseOver: Theme.of(context).iconTheme.color,
      iconMouseDown: Theme.of(context).iconTheme.color,
      selected: ChewieTheme.primaryColor40,
      iconSelected: ChewieTheme.primaryColor,
    );
  }

  static getCloseButtonColors(BuildContext context) {
    return WindowButtonColors(
      mouseOver: const Color(0xFFD32F2F),
      mouseDown: const Color(0xFFB71C1C),
      iconNormal: Theme.of(context).iconTheme.color,
      iconMouseOver: Colors.white,
      iconMouseDown: Colors.white,
      selected: ChewieTheme.primaryColor,
      iconSelected: Colors.white,
    );
  }

  static getLinkColor(BuildContext context) {
    return ChewieUtils.currentBrightness(context) == Brightness.light
        ? ChewieTheme.primaryColor
        : ChewieTheme.primaryColor;
  }

  static getHotTagBackground(BuildContext context) {
    return ChewieUtils.currentBrightness(context) == Brightness.light
        ? hotTagBackground
        : hotTagBackgroundDark;
  }

  static getHotTagTextColor(BuildContext context) {
    return ChewieUtils.currentBrightness(context) == Brightness.light
        ? hotTagTextColor
        : hotTagTextColorDark;
  }
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    return hexString.toColor();
  }

  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${a.toInt().toRadixString(16).padLeft(2, '0')}'
      '${r.toInt().toRadixString(16).padLeft(2, '0')}'
      '${g.toInt().toRadixString(16).padLeft(2, '0')}'
      '${b.toInt().toRadixString(16).padLeft(2, '0')}';
}

extension HexColorString on String {
  Color toColor() {
    final buffer = StringBuffer();
    if (length == 6 || length == 7) buffer.write('ff');
    buffer.write(replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
