import 'package:awesome_chewie/src/Providers/chewie_provider.dart';
import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Widgets/Dialog/widgets/dialog_wrapper_widget.dart';
import 'package:flutter/material.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/generated/l10n.dart';
import 'package:awesome_chewie/src/Widgets/Item/Animation/dialog_animation.dart';
import 'custom_dialog.dart';

class DialogBuilder {
  static showConfirmDialog(
    BuildContext context, {
    String? title,
    String? message,
    String? imagePath,
    TextAlign messageTextAlign = TextAlign.center,
    String? confirmButtonText,
    String? cancelButtonText,
    VoidCallback? onTapConfirm,
    VoidCallback? onTapCancel,
    CustomDialogType? customDialogType,
    Color? color,
    Color? textColor,
    Color? buttonTextColor,
    EdgeInsets? margin,
    EdgeInsets? padding,
    bool barrierDismissible = true,
    bool renderHtml = true,
    Alignment align = Alignment.bottomCenter,
    bool responsive = true,
  }) {
    if (responsive && ResponsiveUtil.isWideLandscape()) {
      CustomConfirmDialog.show(
        context,
        message: message ?? "",
        messageTextAlign: messageTextAlign,
        imagePath: imagePath,
        title: title,
        color: color,
        textColor: textColor,
        buttonTextColor: buttonTextColor,
        margin: margin,
        padding: padding,
        barrierDismissible: barrierDismissible,
        renderHtml: renderHtml,
        align: Alignment.center,
        confirmButtonText: confirmButtonText ?? ChewieS.current.confirm,
        cancelButtonText: cancelButtonText ?? ChewieS.current.cancel,
        onTapConfirm: onTapConfirm ?? () {},
        onTapCancel: onTapCancel ?? () {},
        customDialogType: customDialogType ?? CustomDialogType.normal,
      );
    } else {
      CustomConfirmDialog.showAnimatedFromBottom(
        context,
        message: message ?? "",
        imagePath: imagePath,
        title: title,
        messageTextAlign: messageTextAlign,
        color: color,
        textColor: textColor,
        buttonTextColor: buttonTextColor,
        margin: margin,
        padding: padding,
        barrierDismissible: barrierDismissible,
        renderHtml: renderHtml,
        align: Alignment.bottomCenter,
        confirmButtonText: confirmButtonText ?? ChewieS.current.confirm,
        cancelButtonText: cancelButtonText ?? ChewieS.current.cancel,
        onTapConfirm: onTapConfirm ?? () {},
        onTapCancel: onTapCancel ?? () {},
        customDialogType: customDialogType ?? CustomDialogType.normal,
      );
    }
  }

  static showInfoDialog(
    BuildContext context, {
    String? title,
    String? message,
    Widget? messageChild,
    String? imagePath,
    String? buttonText,
    VoidCallback? onTapDismiss,
    CustomDialogType? customDialogType,
    Color? color,
    Color? textColor,
    Color? buttonTextColor,
    EdgeInsets? margin,
    EdgeInsets? padding,
    bool barrierDismissible = true,
    bool renderHtml = true,
    Alignment align = Alignment.bottomCenter,
    bool responsive = true,
    bool topRadius = true,
    bool bottomRadius = true,
    bool forceNoMarginAtMobile = false,
  }) {
    if (responsive && ResponsiveUtil.isWideLandscape()) {
      CustomInfoDialog.show(
        context,
        buttonText: buttonText ?? ChewieS.current.confirm,
        message: message,
        messageChild: messageChild,
        imagePath: imagePath,
        bottomRadius: bottomRadius,
        margin: margin,
        topRadius: topRadius,
        title: title,
        color: color,
        textColor: textColor,
        buttonTextColor: buttonTextColor,
        padding: padding,
        barrierDismissible: barrierDismissible,
        renderHtml: renderHtml,
        align: Alignment.center,
        customDialogType: customDialogType ?? CustomDialogType.normal,
        onTapDismiss: onTapDismiss ?? () {},
      );
    } else {
      CustomInfoDialog.showAnimatedFromBottom(
        context,
        buttonText: buttonText ?? ChewieS.current.confirm,
        message: message,
        messageChild: messageChild,
        imagePath: imagePath,
        title: title,
        color: color,
        bottomRadius: forceNoMarginAtMobile ? false : bottomRadius,
        margin: forceNoMarginAtMobile ? EdgeInsets.zero : margin,
        topRadius: topRadius,
        textColor: textColor,
        buttonTextColor: buttonTextColor,
        padding: padding,
        barrierDismissible: barrierDismissible,
        renderHtml: renderHtml,
        align: Alignment.bottomCenter,
        customDialogType: customDialogType ?? CustomDialogType.normal,
        onTapDismiss: onTapDismiss ?? () {},
      );
    }
  }

  static showPageDialog(
    BuildContext context, {
    required Widget child,
    bool barrierDismissible = true,
    bool showCloseButton = true,
    bool fullScreen = false,
    Function(dynamic)? onThen,
    double? preferMinWidth,
    double? preferMinHeight,
    GlobalKey<DialogWrapperWidgetState>? overrideDialogNavigatorKey,
  }) {
    showGeneralDialog(
      barrierDismissible: barrierDismissible,
      context: context,
      barrierLabel: '',
      barrierColor: overrideDialogNavigatorKey != null
          ? ChewieTheme.barrierColor
          : ChewieTheme.scaffoldBackgroundColor
              .withValues(alpha: fullScreen ? 0.55 : 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, _) {
        return DialogAnimation(
          animation: animation,
          child: DialogWrapperWidget(
            key:
                overrideDialogNavigatorKey ?? chewieProvider.dialogNavigatorKey,
            showCloseButton: showCloseButton,
            fullScreen: fullScreen,
            preferMinWidth: preferMinWidth,
            preferMinHeight: preferMinHeight,
            barrierDismissible: barrierDismissible,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
    ).then(onThen ?? (_) => {});
  }
}
