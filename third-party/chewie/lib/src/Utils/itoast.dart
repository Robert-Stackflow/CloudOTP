import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Utils/General/string_util.dart';
import 'package:awesome_chewie/src/Widgets/Component/Notification/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:smart_snackbars/enums/animate_from.dart';
import 'package:smart_snackbars/smart_snackbars.dart';
import 'package:smart_snackbars/widgets/snackbars/base_snackbar.dart';

import 'package:awesome_chewie/src/Providers/chewie_provider.dart';
import 'package:awesome_chewie/src/Widgets/Component/Notification/floating_notification.dart';
import 'package:awesome_chewie/src/Widgets/Item/Button/round_icon_text_button.dart';

class IToast {
  static FToast? show(
    String text, {
    Icon? icon,
    String? decription,
    int seconds = 2,
    ToastGravity gravity = ToastGravity.TOP,
  }) {
    if (ResponsiveUtil.isLandscape()) {
      NotificationManager().show(
        chewieProvider.rootContext,
        text,
        description: decription,
        duration: Duration(seconds: seconds),
        style: NotificationStyle(icon: icon?.icon, iconColor: icon?.color),
      );
    } else {
      FToast toast = FToast().init(chewieProvider.rootContext);
      toast.showToast(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: ChewieTheme.defaultDecoration,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(chewieProvider.rootContext).textTheme.bodyMedium,
          ),
        ),
        gravity: gravity,
        toastDuration: Duration(seconds: seconds),
      );
      return toast;
    }
    return null;
  }

  static FToast? showTop(
    String text, {
    Icon? icon,
    String? decription,
  }) {
    if (text.nullOrEmpty) return null;
    return show(
      text,
      icon: icon,
      decription: decription,
    );
  }

  static FToast? showBottom(
    String text, {
    Icon? icon,
  }) {
    return show(text, icon: icon, gravity: ToastGravity.BOTTOM);
  }

  static LocalNotification? showDesktopNotification(
    String title, {
    String? subTitle,
    String? body,
    List<String> actions = const [],
    Function()? onClick,
    Function(int)? onClickAction,
  }) {
    if (!ResponsiveUtil.isDesktop()) return null;
    var nActions =
        actions.map((e) => LocalNotificationAction(text: e)).toList();
    LocalNotification notification = LocalNotification(
      identifier: StringUtil.generateUid(),
      title: title,
      subtitle: subTitle,
      body: body,
      actions: nActions,
    );
    notification.onShow = () {};
    notification.onClose = (closeReason) {
      switch (closeReason) {
        case LocalNotificationCloseReason.userCanceled:
          break;
        case LocalNotificationCloseReason.timedOut:
          break;
        default:
      }
    };
    notification.onClick = onClick;
    notification.onClickAction = onClickAction;
    notification.show();
    return notification;
  }

  static CustomSnackBarController showCustomSnackbar({
    required Widget child,
    Widget? icon,
    bool persist = false,
    Duration? duration,
    EdgeInsets? padding,
    EdgeInsets? outerPadding,
    double? maxWidth,
    CustomSnackBarController? controller,
    Function()? onDismiss,
  }) {
    controller ??= CustomSnackBarController();
    SmartSnackBars.showCustomSnackBar(
      context: chewieProvider.rootContext,
      controller: controller,
      duration: duration,
      animateFrom: ResponsiveUtil.isLandscape()
          ? AnimateFrom.fromTop
          : AnimateFrom.fromBottom,
      animationCurve: Curves.easeInOut,
      distanceToTravel: 0.0,
      persist: persist,
      maxWidth: maxWidth,
      outerPadding: outerPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        padding: padding ?? const EdgeInsets.all(10),
        decoration: ChewieTheme.defaultDecoration,
        child: child,
      ),
    );
    return controller;
  }

  static CustomSnackBarController showSnackbar(
    String message, {
    String? buttonText,
    Function()? onTap,
    Function()? onDismiss,
    Widget? icon,
    bool persist = false,
  }) {
    return showCustomSnackbar(
      icon: icon,
      persist: persist,
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      maxWidth: ResponsiveUtil.isLandscape() ? 400 : null,
      onDismiss: onDismiss,
      child: Row(
        children: [
          if (icon != null) icon,
          const SizedBox(width: 12),
          Text(
            message,
            style: Theme.of(chewieProvider.rootContext).textTheme.titleMedium,
          ),
          const Spacer(),
          if (buttonText.notNullOrEmpty)
            RoundIconTextButton(
              text: buttonText!,
              onPressed: onTap ?? () {},
              background: Theme.of(chewieProvider.rootContext).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
        ],
      ),
    );
  }

  static CustomSnackBarController _showLoadingSnackbar(
    String message, {
    String? buttonText,
    Function()? onTap,
    Function()? onDismiss,
  }) {
    return showSnackbar(
      message,
      buttonText: buttonText,
      onTap: onTap,
      persist: true,
      onDismiss: onDismiss,
      icon: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(
              Theme.of(chewieProvider.rootContext).textTheme.titleLarge?.color),
          strokeWidth: 3,
          strokeCap: StrokeCap.round,
        ),
      ),
    );
  }

  static Future<dynamic> showLoadingSnackbar(
    String message,
    Function() future, {
    String? buttonText,
    Function()? onTap,
    Function()? onDismiss,
  }) async {
    var controller = _showLoadingSnackbar(
      message,
      buttonText: buttonText,
      onTap: onTap,
      onDismiss: onDismiss,
    );
    var res = await future();
    controller.close?.call();
    return res;
  }
}
