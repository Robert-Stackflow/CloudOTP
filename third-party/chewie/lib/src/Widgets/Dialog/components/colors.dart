/*
 * Copyright (c) 2025 Robert-Stackflow.
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
import 'package:awesome_chewie/awesome_chewie.dart';

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
