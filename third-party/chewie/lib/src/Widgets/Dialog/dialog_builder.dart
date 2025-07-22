import 'package:flutter/material.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

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
    if (responsive && ResponsiveUtil.isWideDevice()) {
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
        confirmButtonText: confirmButtonText ?? chewieLocalizations.confirm,
        cancelButtonText: cancelButtonText ?? chewieLocalizations.cancel,
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
        confirmButtonText: confirmButtonText ?? chewieLocalizations.confirm,
        cancelButtonText: cancelButtonText ?? chewieLocalizations.cancel,
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
    if (responsive && ResponsiveUtil.isWideDevice()) {
      CustomInfoDialog.show(
        context,
        buttonText: buttonText ?? chewieLocalizations.confirm,
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
        buttonText: buttonText ?? chewieLocalizations.confirm,
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
  }) {
    showGeneralDialog(
      barrierDismissible: barrierDismissible,
      context: context,
      barrierLabel: '',
      barrierColor: ChewieTheme.barrierColor,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, _) {
        return DialogAnimation(
          animation: animation,
          child: DialogWrapperWidget(
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
