import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Dialog/widgets/dialog_wrapper_widget.dart';
import 'package:cloudotp/Widgets/General/Animation/animated_fade.dart';
import 'package:flutter/material.dart';

import '../../generated/l10n.dart';
import 'custom_dialog.dart';

class DialogBuilder {
  static showConfirmDialog(
    BuildContext context, {
    String? title,
    String? message,
    String? imagePath,
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
    bool noImage = true,
    Alignment align = Alignment.bottomCenter,
    bool responsive = true,
  }) {
    if (responsive && ResponsiveUtil.isLandscape()) {
      CustomConfirmDialog.show(
        context,
        message: message ?? "",
        imagePath: imagePath,
        title: title,
        color: color,
        textColor: textColor,
        buttonTextColor: buttonTextColor,
        margin: margin,
        padding: padding,
        barrierDismissible: barrierDismissible,
        noImage: noImage,
        align: Alignment.center,
        confirmButtonText: confirmButtonText ?? S.current.confirm,
        cancelButtonText: cancelButtonText ?? S.current.cancel,
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
        color: color,
        textColor: textColor,
        buttonTextColor: buttonTextColor,
        margin: margin,
        padding: padding,
        barrierDismissible: barrierDismissible,
        noImage: noImage,
        align: Alignment.bottomCenter,
        confirmButtonText: confirmButtonText ?? S.current.confirm,
        cancelButtonText: cancelButtonText ?? S.current.cancel,
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
    bool noImage = true,
    Alignment align = Alignment.bottomCenter,
    bool responsive = true,
  }) {
    if (responsive && ResponsiveUtil.isLandscape()) {
      CustomInfoDialog.show(
        context,
        buttonText: buttonText ?? S.current.confirm,
        message: message,
        messageChild: messageChild,
        imagePath: imagePath,
        title: title,
        color: color,
        textColor: textColor,
        buttonTextColor: buttonTextColor,
        margin: margin,
        padding: padding,
        barrierDismissible: barrierDismissible,
        noImage: noImage,
        align: Alignment.center,
        customDialogType: customDialogType ?? CustomDialogType.normal,
        onTapDismiss: onTapDismiss ?? () {},
      );
    } else {
      CustomInfoDialog.showAnimatedFromBottom(
        context,
        buttonText: buttonText ?? S.current.confirm,
        message: message,
        messageChild: messageChild,
        imagePath: imagePath,
        title: title,
        color: color,
        textColor: textColor,
        buttonTextColor: buttonTextColor,
        margin: margin,
        padding: padding,
        barrierDismissible: barrierDismissible,
        noImage: noImage,
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
    bool showClose = true,
    Function(dynamic)? onThen,
    double? preferMinWidth,
    double? preferMinHeight,
  }) {
    showGeneralDialog(
      barrierDismissible: barrierDismissible,
      context: context,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return AnimatedFade(
          animation: animation,
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) =>
          DialogWrapperWidget(
        key: dialogNavigatorKey,
        showClose: showClose,
        preferMinWidth: preferMinWidth,
        preferMinHeight: preferMinHeight,
        child: child,
      ),
    ).then(onThen ?? (_) => {});
  }
}
