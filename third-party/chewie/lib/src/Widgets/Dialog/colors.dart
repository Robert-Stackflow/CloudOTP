import 'package:awesome_chewie/src/Widgets/Dialog/custom_dialog.dart';
import 'package:flutter/material.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';

class CustomDialogColors {
  /// All the Colors used in the Dialog themes
  /// <h3>Hex Code: #61D800</h3>
  static Color success = const Color(0xFF61D800);

  /// <h3>Hex Code: #179DFF</h3>
  static Color normal = const Color(0xFF179DFF);

  /// <h3>Hex Code: #FF8B17</h3>
  static Color warning = const Color(0xFFFF8B17);

  /// <h3>Hex Code: #FF4D17</h3>
  static Color error = const Color(0xFFFF4D17);

  /// <h3>Hex Code: #707070</h3>
  static Color defaultTextColor = const Color(0xFF707070);

  static getBgColor(BuildContext context, CustomDialogType customDialogType,
      Color? defaultColor) {
    return customDialogType == CustomDialogType.normal
        ? ChewieTheme.primaryColor
        : customDialogType == CustomDialogType.success
            ? CustomDialogColors.success
            : customDialogType == CustomDialogType.warning
                ? CustomDialogColors.warning
                : customDialogType == CustomDialogType.error
                    ? CustomDialogColors.error
                    : defaultColor;
  }
}
