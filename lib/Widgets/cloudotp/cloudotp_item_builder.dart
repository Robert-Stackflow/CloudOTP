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

import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Widgets/cloudotp/qrcodes_dialog_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:group_button/group_button.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../Models/opt_token.dart';
import '../../Utils/asset_util.dart';

class CloudOTPItemBuilder {
  static buildSliverAppBar({
    required BuildContext context,
    Widget? backgroundWidget,
    List<Widget>? actions,
    Widget? flexibleSpace,
    PreferredSizeWidget? bottom,
    Widget? title,
    bool center = false,
    bool floating = false,
    bool pinned = false,
    Widget? leading,
    Color? leadingColor,
    Function()? onLeadingTap,
    Color? backgroundColor,
    double expandedHeight = 320,
    double? collapsedHeight,
    SystemUiOverlayStyle? systemOverlayStyle,
    bool useBackdropFilter = false,
  }) {
    bool showLeading = !ResponsiveUtil.isLandscape();
    center = ResponsiveUtil.isLandscape() ? false : center;
    return MySliverAppBar(
      useBackdropFilter: useBackdropFilter,
      systemOverlayStyle: systemOverlayStyle,
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight ??
          max(100, kToolbarHeight + MediaQuery.of(context).padding.top),
      pinned: pinned,
      floating: floating,
      leadingWidth: showLeading ? 56 : 0,
      leading: showLeading
          ? Container(
              margin: const EdgeInsets.only(left: 0),
              child: CircleIconButton(
                icon: leading,
                onTap: onLeadingTap,
              ),
            )
          : null,
      automaticallyImplyLeading: false,
      backgroundWidget: backgroundWidget,
      actions: actions,
      title: showLeading
          ? center
              ? Center(child: title)
              : title ?? emptyWidget
          : center
              ? Center(
                  child: Container(
                    margin: const EdgeInsets.only(left: 20),
                    child: title,
                  ),
                )
              : Container(
                  margin: const EdgeInsets.only(left: 20),
                  child: title,
                ),
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor:
          backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
    );
  }

  static buildGroupTokenButtons({
    required List<OtpToken> tokens,
    GroupButtonController? controller,
    bool enableDeselect = true,
    bool disabled = false,
    bool isRadio = false,
    double height = 32,
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
          height: height,
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

  static Widget buildRoundButton(
    BuildContext context, {
    String? text,
    Function()? onTap,
    Color? background,
    Widget? icon,
    EdgeInsets? padding,
    double radius = 50,
    Color? color,
    double fontSizeDelta = 0,
    TextStyle? textStyle,
    double? width,
    bool align = false,
    bool disabled = false,
    bool feedback = false,
    bool reversePosition = false,
  }) {
    Widget titleWidget = AutoSizeText(
      text ?? "",
      textAlign: TextAlign.center,
      style: textStyle ??
          ChewieTheme.titleSmall?.apply(
            color: color ??
                (background != null
                    ? Colors.white
                    : disabled
                        ? Colors.grey
                        : ChewieTheme.titleSmall?.color),
            fontWeightDelta: 2,
            fontSizeDelta: fontSizeDelta,
          ),
      maxLines: 1,
    );
    Color fBackground = background ?? ChewieTheme.cardColor;
    return PressableAnimation(
      child: Material(
        color: fBackground.withAlpha(fBackground.alpha ~/ (disabled ? 1.5 : 1)),
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap != null && !disabled
              ? () {
                  onTap();
                  if (feedback) HapticFeedback.lightImpact();
                }
              : null,
          enableFeedback: true,
          borderRadius: BorderRadius.circular(radius),
          child: ClickableWrapper(
            clickable: onTap != null,
            child: Container(
              width: width,
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icon != null && !reversePosition) icon,
                  if (icon != null && !reversePosition && text.notNullOrEmpty)
                    const SizedBox(width: 5),
                  align
                      ? Expanded(flex: 100, child: titleWidget)
                      : Flexible(child: titleWidget),
                  if (icon != null && reversePosition && text.notNullOrEmpty)
                    const SizedBox(width: 5),
                  if (icon != null && reversePosition) icon,
                  if (align) const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
      showGeneralDialog(
        barrierColor: ChewieTheme.barrierColor,
        barrierDismissible: true,
        barrierLabel: "",
        context: context,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SizedBox.shrink(),
        transitionBuilder: (context, animation, secondaryAnimation, _) =>
            DialogAnimation(
          animation: animation,
          child: QrcodesDialogWidget(
            title: title,
            qrcodes: qrcodes,
            message: message,
            align: align,
            asset: asset,
          ),
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
        backgroundColor: ChewieTheme.canvasColor,
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
