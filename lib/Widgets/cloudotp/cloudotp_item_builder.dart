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

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Widgets/cloudotp/qrcodes_dialog_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:group_button/group_button.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../Models/opt_token.dart';
import '../../Utils/asset_util.dart';

class CloudOTPItemBuilder {
  static buildGroupTokenButtons({
    required List<OtpToken> tokens,
    GroupButtonController? controller,
    bool enableDeselect = true,
    bool disabled = false,
    bool isRadio = false,
    Function(dynamic value, int index, bool isSelected)? onSelected,
  }) {
    return GroupButton(
      isRadio: isRadio,
      enableDeselect: enableDeselect,
      options: const GroupButtonOptions(
        mainGroupAlignment: MainGroupAlignment.center,
        runSpacing: 6,
        spacing: 6,
      ),
      disabled: disabled,
      onSelected: onSelected,
      controller: controller,
      buttons: tokens,
      buttonBuilder: (selected, token, context, onTap, disabled) {
        return RoundIconTextButton(
          radius: 8,
          icon: buildTokenImage(token, size: 12),
          text: token.issuer,
          onPressed: onTap,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          background: selected
              ? disabled
                  ? ChewieTheme.primaryColor.withAlpha(80)
                  : ChewieTheme.primaryColor
              : null,
          textStyle: ChewieTheme.titleSmall
              .apply(fontSizeDelta: 1, color: selected ? Colors.white : null),
        );
      },
    );
  }

  static buildTokenImage(OtpToken token, {double size = 80}) {
    if (token.imagePath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: AssetFiles.loadBrand(token.imagePath,
            width: size, height: size, fit: BoxFit.contain),
      );
    } else {
      return TextDrawable(
        text: token.issuer,
        boxShape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(5),
        width: size,
        height: size,
      );
    }
  }

  static showQrcodesDialog(
    BuildContext context, {
    required List<String> qrcodes,
    String? title,
    String? message,
    String? asset,
    Alignment align = Alignment.bottomCenter,
    bool responsive = true,
  }) {
    if (responsive && ResponsiveUtil.isWideLandscape()) {
      QrcodeDialog.show(
        context,
        title: title,
        message: message,
        qrcodes: qrcodes,
        align: Alignment.center,
        asset: asset,
      );
    } else {
      QrcodeDialog.showAnimatedFromBottom(
        context,
        title: title,
        qrcodes: qrcodes,
        message: message,
        align: align,
        asset: asset,
      );
    }
  }
}

class QrcodeDialog {
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    String? message,
    String? asset,
    required List<String> qrcodes,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showDialog<T>(
        barrierDismissible: true,
        context: context,
        builder: (context) => QrcodesDialogWidget(
          title: title,
          qrcodes: qrcodes,
          message: message,
          align: align,
          asset: asset,
        ),
      );

  static Future<T?> showAnimatedFromBottom<T>(
    BuildContext context, {
    String? title,
    String? message,
    String? asset,
    required List<String> qrcodes,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showCustomModalBottomSheet(
        context: context,
        elevation: 0,
        enableDrag: true,
        backgroundColor: Theme.of(context).canvasColor,
        builder: (context) => QrcodesDialogWidget(
          title: title,
          message: message,
          qrcodes: qrcodes,
          align: align,
          asset: asset,
        ),
        containerWidget: (_, animation, child) => FloatingModal(
          child: child,
        ),
      );
}
