import 'package:cloudotp/Widgets/Dialog/widgets/loading_dialog_widget.dart';
import 'package:cloudotp/Widgets/Dialog/widgets/qrcodes_dialog_widget.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../Utils/app_provider.dart';
import '../Custom/floating_modal.dart';
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
    bool renderHtml = false,
    Alignment align = Alignment.bottomCenter,
    bool topRadius = true,
    bool bottomRadius = true,
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
          renderHtml: renderHtml,
          align: align,
          bottomRadius: bottomRadius,
          topRadius: topRadius,
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
    bool renderHtml = false,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 400),
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
          renderHtml: renderHtml,
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
    bool renderHtml = false,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 400),
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
          renderHtml: renderHtml,
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
    bool renderHtml = false,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 400),
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
          renderHtml: renderHtml,
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
    bool renderHtml = false,
    Alignment align = Alignment.bottomCenter,
    bool topRadius = true,
    bool bottomRadius = true,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierLabel: '',
        barrierColor: Colors.black.withOpacity(0.35),
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
          bottomRadius: bottomRadius,
          topRadius: topRadius,
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
    bool renderHtml = false,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierLabel: '',
        barrierColor: Colors.black.withOpacity(0.35),
        transitionDuration: const Duration(milliseconds: 400),
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
          renderHtml: renderHtml,
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
    bool renderHtml = false,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 400),
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
          renderHtml: renderHtml,
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
    bool renderHtml = false,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        builder: (context) => CustomConfirmDialogWidget(
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
      );

  static Future<T?> showAnimatedFromLeft<T extends Object?>(
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
    bool renderHtml = false,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 400),
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
          messageTextAlign: messageTextAlign,
          onTapCancel: onTapCancel,
          customDialogType: customDialogType,
          color: color,
          textColor: textColor,
          buttonTextColor: buttonTextColor,
          imagePath: imagePath,
          margin: margin,
          padding: padding,
          renderHtml: renderHtml,
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
    TextAlign messageTextAlign = TextAlign.center,
    required VoidCallback onTapConfirm,
    required VoidCallback onTapCancel,
    required CustomDialogType customDialogType,
    Color? color,
    Color? textColor,
    Color? buttonTextColor,
    EdgeInsets? margin,
    EdgeInsets? padding,
    bool barrierDismissible = true,
    bool renderHtml = false,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 400),
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
          messageTextAlign: messageTextAlign,
          margin: margin,
          padding: padding,
          renderHtml: renderHtml,
          align: align,
        ),
      );

  static Future<T?> showAnimatedFromTop<T extends Object?>(
    BuildContext context, {
    String? title,
    required String message,
    TextAlign messageTextAlign = TextAlign.center,
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
    bool renderHtml = false,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 400),
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
          messageTextAlign: messageTextAlign,
          margin: margin,
          padding: padding,
          renderHtml: renderHtml,
          align: align,
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
    bool renderHtml = false,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierLabel: '',
        barrierColor: Colors.black.withOpacity(0.35),
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

  static Future<T?> showAnimatedGrow<T extends Object?>(
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
    bool renderHtml = false,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 400),
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
          messageTextAlign: messageTextAlign,
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
          renderHtml: renderHtml,
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
    TextAlign messageTextAlign = TextAlign.center,
    required VoidCallback onTapConfirm,
    required VoidCallback onTapCancel,
    required CustomDialogType customDialogType,
    Color? color,
    Color? textColor,
    Color? buttonTextColor,
    EdgeInsets? margin,
    EdgeInsets? padding,
    bool barrierDismissible = true,
    bool renderHtml = false,
    Alignment align = Alignment.bottomCenter,
  }) =>
      showGeneralDialog<T>(
        barrierDismissible: barrierDismissible,
        barrierColor: Colors.black.withOpacity(0.35),
        context: context,
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 400),
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
          renderHtml: renderHtml,
          align: align,
        ),
      );
}

class CustomLoadingDialog {
  static void showLoading({
    bool dismissible = false,
    String? title,
    double size = 40,
    double scale = 1,
  }) {
    showDialog(
      barrierDismissible: dismissible,
      context: rootContext,
      builder: (context) {
        return LoadingDialogWidget(
          dismissible: dismissible,
          title: title,
          size: size,
          scale: scale,
        );
      },
    );
  }

  static Future<void> dismissLoading() async {
    return Future.sync(() => Navigator.pop(rootContext));
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
