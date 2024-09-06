import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Dialog/widgets/dialog_wrapper_widget.dart';
import 'package:cloudotp/Widgets/General/Animation/animated_fade.dart';
import 'package:flutter/material.dart';

import '../../Utils/app_provider.dart';
import '../../generated/l10n.dart';
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
        messageTextAlign: messageTextAlign,
        color: color,
        textColor: textColor,
        buttonTextColor: buttonTextColor,
        margin: margin,
        padding: padding,
        barrierDismissible: barrierDismissible,
        renderHtml: renderHtml,
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
        buttonText: buttonText ?? S.current.confirm,
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
        buttonText: buttonText ?? S.current.confirm,
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
    bool showClose = true,
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
          ? Colors.black.withOpacity(0.15)
          : Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return AnimatedFade(
          animation: animation,
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) =>
          DialogWrapperWidget(
        key: overrideDialogNavigatorKey ?? dialogNavigatorKey,
        showClose: showClose,
        preferMinWidth: preferMinWidth,
        preferMinHeight: preferMinHeight,
        child: child,
      ),
    ).then(onThen ?? (_) => {});
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
