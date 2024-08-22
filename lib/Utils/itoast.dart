import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:local_notifier/local_notifier.dart';

import 'app_provider.dart';

class IToast {
  static FToast show(
    String text, {
    Icon? icon,
    int seconds = 2,
    ToastGravity gravity = ToastGravity.TOP,
  }) {
    FToast toast = FToast().init(rootContext);
    toast.showToast(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(rootContext).canvasColor,
          boxShadow: [
            BoxShadow(
              color: Theme.of(rootContext).shadowColor,
              offset: const Offset(0, 4),
              blurRadius: 10,
              spreadRadius: 1,
            ).scale(2)
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(rootContext).textTheme.bodyMedium,
        ),
      ),
      gravity: gravity,
      toastDuration: Duration(seconds: seconds),
    );
    return toast;
  }

  static FToast? showTop(
    String text, {
    Icon? icon,
  }) {
    if (Utils.isEmpty(text)) return null;
    return show(text, icon: icon);
  }

  static FToast showBottom(
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
    LocalNotification notification = LocalNotification(
      title: title,
      subtitle: subTitle,
      body: body,
      actions: actions.map((e) => LocalNotificationAction(text: e)).toList(),
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
}
