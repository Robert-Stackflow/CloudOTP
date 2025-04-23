import 'package:awesome_chewie/src/Widgets/Dialog/widgets/loading_dialog_widget.dart';
import 'package:flutter/material.dart';

import 'package:awesome_chewie/src/Providers/chewie_provider.dart';
import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Widgets/Item/Animation/dialog_animation.dart';
import 'animations.dart';
import 'widgets/custom_confirm_dialog_widget.dart';
import 'widgets/custom_info_dialog_widget.dart';

enum CustomDialogType { success, normal, warning, error, custom }

class CustomInfoDialog {
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    String? message,
    Widget? messageChild,
    String? imagePath,
    required String buttonText,
    required VoidCallback onTapDismiss,
    required CustomDialogType customDialogType,
    Color? color,
    Color? textColor,
    Color? buttonTextColor,
    EdgeInsets? margin,
    EdgeInsets? padding,
    bool barrierDismissible = true,
    bool renderHtml = true,
    Alignment align = Alignment.bottomCenter,
    bool topRadius = true,
    bool bottomRadius = true,
  }) =>
      showGeneralDialog<T>(
        barrierColor: ChewieTheme.barrierColor,
        barrierLabel: "",
        barrierDismissible: barrierDismissible,
        context: context,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SizedBox.shrink(),
        transitionBuilder: (context, animation, secondaryAnimation, _) =>
            DialogAnimation(
          animation: animation,
          child: CustomInfoDialogWidget(
            title: title,
            message: message,
            messageChild: messageChild,
            buttonText: buttonText,
            onTapDismiss: onTapDismiss,
            customDialogType: customDialogType,
            color: color,
            textColor: textColor,
            buttonTextColor: buttonTextColor,
            imagePath: imagePath,
            margin: margin,
            padding: padding,
            renderHtml: renderHtml,
            align: align,
            roundbottom: bottomRadius,
            roundTop: topRadius,
          ),
        ),
      );

  static Future<T?> showAnimatedFromBottom<T extends Object?>(
    BuildContext context, {
    String? title,
    String? message,
    Widget? messageChild,
    String? imagePath,
    required String buttonText,
    required VoidCallback onTapDismiss,
    required CustomDialogType customDialogType,
    Color? color,
    Color? textColor,
    Color? buttonTextColor,
    EdgeInsets? margin,
    EdgeInsets? padding,
    bool barrierDismissible = true,
    bool renderHtml = true,
    Alignment align = Alignment.bottomCenter,
    bool topRadius = true,
    bool bottomRadius = true,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierLabel: '',
        barrierColor: ChewieTheme.barrierColor,
        transitionDuration: const Duration(milliseconds: 400),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return CustomDialogAnimations.fromBottom(
            animation,
            secondaryAnimation,
            child,
          );
        },
        pageBuilder: (animation, secondaryAnimation, child) =>
            CustomInfoDialogWidget(
          title: title,
          message: message,
          messageChild: messageChild,
          imagePath: imagePath,
          buttonText: buttonText,
          onTapDismiss: onTapDismiss,
          customDialogType: customDialogType,
          color: color,
          textColor: textColor,
          buttonTextColor: buttonTextColor,
          margin: margin,
          padding: padding,
          renderHtml: renderHtml,
          align: align,
          roundbottom: bottomRadius,
          roundTop: topRadius,
        ),
      );
}

class CustomConfirmDialog {
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required String message,
    String? imagePath,
    TextAlign messageTextAlign = TextAlign.center,
    required String confirmButtonText,
    required String cancelButtonText,
    required VoidCallback onTapConfirm,
    required VoidCallback onTapCancel,
    required CustomDialogType customDialogType,
    Color? color,
    Color? textColor,
    Color? buttonTextColor,
    EdgeInsets? margin,
    EdgeInsets? padding,
    bool barrierDismissible = true,
    bool renderHtml = true,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierColor: ChewieTheme.barrierColor,
        barrierDismissible: barrierDismissible,
        barrierLabel: "",
        context: context,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SizedBox.shrink(),
        transitionBuilder: (context, animation, secondaryAnimation, _) =>
            DialogAnimation(
          animation: animation,
          child: CustomConfirmDialogWidget(
            renderHtml: renderHtml,
            title: title,
            message: message,
            messageTextAlign: messageTextAlign,
            confirmButtonText: confirmButtonText,
            cancelButtonText: cancelButtonText,
            onTapConfirm: onTapConfirm,
            onTapCancel: onTapCancel,
            customDialogType: customDialogType,
            color: color,
            textColor: textColor,
            buttonTextColor: buttonTextColor,
            imagePath: imagePath,
            margin: margin,
            padding: padding,
            align: align,
          ),
        ),
      );

  static Future<T?> showAnimatedFromBottom<T extends Object?>(
    BuildContext context, {
    String? title,
    required String message,
    String? imagePath,
    required String confirmButtonText,
    TextAlign messageTextAlign = TextAlign.center,
    required String cancelButtonText,
    required VoidCallback onTapConfirm,
    required VoidCallback onTapCancel,
    required CustomDialogType customDialogType,
    Color? color,
    Color? textColor,
    Color? buttonTextColor,
    EdgeInsets? margin,
    EdgeInsets? padding,
    bool barrierDismissible = true,
    bool renderHtml = true,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierLabel: '',
        barrierColor: ChewieTheme.barrierColor,
        transitionDuration: const Duration(milliseconds: 400),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return CustomDialogAnimations.fromBottom(
            animation,
            secondaryAnimation,
            child,
          );
        },
        pageBuilder: (animation, secondaryAnimation, child) =>
            CustomConfirmDialogWidget(
          title: title,
          message: message,
          confirmButtonText: confirmButtonText,
          cancelButtonText: cancelButtonText,
          onTapConfirm: onTapConfirm,
          onTapCancel: onTapCancel,
          customDialogType: customDialogType,
          color: color,
          textColor: textColor,
          buttonTextColor: buttonTextColor,
          imagePath: imagePath,
          messageTextAlign: messageTextAlign,
          margin: margin,
          padding: padding,
          renderHtml: renderHtml,
          align: align,
        ),
      );
}

class CustomLoadingDialog {
  static void showLoading({
    bool barrierDismissible = false,
    String? title,
    double size = 40,
    double scale = 1,
  }) {
    showGeneralDialog(
      barrierColor: ChewieTheme.barrierColor,
      barrierDismissible: barrierDismissible,
      barrierLabel: "",
      context: chewieProvider.rootContext,
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, _) =>
          DialogAnimation(
        animation: animation,
        child: LoadingDialogWidget(
          dismissible: barrierDismissible,
          title: title,
          size: size,
        ),
      ),
    );
  }

  static Future<void> dismissLoading() async {
    return Future.sync(() => Navigator.pop(chewieProvider.rootContext));
  }
}
