import 'package:flutter/material.dart';
import 'package:cloudotp/Widgets/Dialog/widgets/loading_dialog_widget.dart';

import '../../Utils/app_provider.dart';
import './animations.dart';
import './widgets/custom_confirm_dialog_widget.dart';
import './widgets/custom_info_dialog_widget.dart';

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
    bool noImage = true,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        builder: (context) => CustomInfoDialogWidget(
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
          noImage: noImage,
          align: align,
        ),
      );

  static Future<T?> showAnimatedFromLeft<T extends Object?>(
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
    bool noImage = true,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return CustomDialogAnimations.fromLeft(
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
          noImage: noImage,
          align: align,
        ),
      );

  static Future<T?> showAnimatedFromRight<T extends Object?>(
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
    bool noImage = true,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return CustomDialogAnimations.fromRight(
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
          noImage: noImage,
          align: align,
        ),
      );

  static Future<T?> showAnimatedFromTop<T extends Object?>(
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
    bool noImage = true,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return CustomDialogAnimations.fromTop(
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
          noImage: noImage,
          align: align,
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
    bool noImage = true,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierLabel: '',
        barrierColor: Colors.black.withOpacity(0.35),
        transitionDuration: const Duration(milliseconds: 300),
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
          noImage: noImage,
          align: align,
        ),
      );

  static Future<T?> showAnimatedGrow<T extends Object?>(
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
    bool noImage = true,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierLabel: '',
        barrierColor: Colors.black.withOpacity(0.35),
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return CustomDialogAnimations.grow(
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
          noImage: noImage,
          align: align,
        ),
      );

  static Future<T?> showAnimatedShrink<T extends Object?>(
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
    bool noImage = true,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return CustomDialogAnimations.shrink(
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
          noImage: noImage,
          align: align,
        ),
      );
}

class CustomConfirmDialog {
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required String message,
    String? imagePath,
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
    bool noImage = true,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        builder: (context) => CustomConfirmDialogWidget(
          noImage: noImage,
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
          margin: margin,
          padding: padding,
          align: align,
        ),
      );

  static Future<T?> showAnimatedFromLeft<T extends Object?>(
    BuildContext context, {
    String? title,
    required String message,
    String? imagePath,
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
    bool noImage = true,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return CustomDialogAnimations.fromLeft(
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
          margin: margin,
          padding: padding,
          noImage: noImage,
          align: align,
        ),
      );

  static Future<T?> showAnimatedFromRight<T extends Object?>(
    BuildContext context, {
    String? title,
    required String message,
    String? imagePath,
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
    bool noImage = true,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return CustomDialogAnimations.fromRight(
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
          margin: margin,
          padding: padding,
          noImage: noImage,
          align: align,
        ),
      );

  static Future<T?> showAnimatedFromTop<T extends Object?>(
    BuildContext context, {
    String? title,
    required String message,
    String? imagePath,
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
    bool noImage = true,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return CustomDialogAnimations.fromTop(
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
          margin: margin,
          padding: padding,
          noImage: noImage,
          align: align,
        ),
      );

  static Future<T?> showAnimatedFromBottom<T extends Object?>(
    BuildContext context, {
    String? title,
    required String message,
    String? imagePath,
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
    bool noImage = true,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierLabel: '',
        barrierColor: Colors.black.withOpacity(0.35),
        transitionDuration: const Duration(milliseconds: 300),
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
          margin: margin,
          padding: padding,
          noImage: noImage,
          align: align,
        ),
      );

  static Future<T?> showAnimatedGrow<T extends Object?>(
    BuildContext context, {
    String? title,
    required String message,
    String? imagePath,
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
    bool noImage = true,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return CustomDialogAnimations.grow(
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
          margin: margin,
          padding: padding,
          noImage: noImage,
          align: align,
        ),
      );

  static Future<T?> showAnimatedShrink<T extends Object?>(
    BuildContext context, {
    String? title,
    required String message,
    String? imagePath,
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
    bool noImage = true,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        barrierColor: Colors.black.withOpacity(0.35),
        context: context,
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return CustomDialogAnimations.shrink(
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
          margin: margin,
          padding: padding,
          noImage: noImage,
          align: align,
        ),
      );
}

class CustomLoadingDialog {
  static void showLoading({
    bool dismissible = false,
    String? title,
    double size = 40,
  }) {
    showDialog(
        barrierDismissible: dismissible,
        context: globalNavigatorKey.currentState!.context,
        builder: (context) {
          return LoadingDialogWidget(
            dismissible: dismissible,
            title: title,
            size: size,
          );
        });
  }

  static Future<void> dismissLoading() async {
    return Future.sync(
        () => Navigator.pop(globalNavigatorKey.currentState!.context));
  }
}
