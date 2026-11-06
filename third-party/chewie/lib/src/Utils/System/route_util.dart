import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:awesome_chewie/awesome_chewie.dart';

class RouteUtil {
  // Keep navigation on the system-style edge. Page-content drags belong to
  // controls such as gesture passwords, token actions, sliders and lists.
  static PageRoute<T> createIOSPageRoute<T>(Widget page) =>
      cupertino.CupertinoPageRoute<T>(builder: (context) => page);

  static PageRoute<T> createIOSRootRoute<T>(Widget page) => PageRouteBuilder<T>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, _, __) => ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor, child: page),
      );

  static void pushRootPage(Widget page) {
    Navigator.of(chewieProvider.globalNavigatorContext)
        .pushAndRemoveUntil(RouteUtil.getFadeRoute(page), (_) => false);
  }

  static pushMaterialRoute(
    BuildContext context,
    Widget page, {
    Function(dynamic)? onThen,
    bool popAll = false,
  }) {
    if (ResponsiveUtil.isIOS()) {
      return Navigator.push(context, createIOSPageRoute(page))
          .then(onThen ?? (_) => {});
    }
    return Navigator.push(
            context, MaterialPageRoute(builder: (context) => page))
        .then(onThen ?? (_) => {});
  }

  static pushCupertinoRoute(
    BuildContext context,
    Widget page, {
    Function(dynamic)? onThen,
    bool popAll = false,
    bool? modalSheet,
  }) {
    if (ResponsiveUtil.isIOS()) {
      return pushIOSPageRoute(context, page, popAll: popAll)
          .then(onThen ?? (_) => {});
    }
    final bool effectiveModalSheet = modalSheet ??
        !ChewieHiveUtil.getBool("enableModalSheet", defaultValue: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ResponsiveUtil.isLandscapeLayout()) {
        pushFadeRoute(context, page, onThen: onThen);
      } else {
        if (popAll) {
          Navigator.pushAndRemoveUntil(
              context,
              CustomCupertinoPageRoute(
                  builder: (context) => page,
                  fullscreenDialog: true,
                  modalSheet: effectiveModalSheet),
              (_) => false).then(onThen ?? (_) => {});
        } else {
          Navigator.push(
                  context,
                  CustomCupertinoPageRoute(
                      builder: (context) => page,
                      fullscreenDialog: true,
                      modalSheet: effectiveModalSheet))
              .then(onThen ?? (_) => {});
        }
      }
    });
  }

  /// Preserve the existing Cupertino navigation contract: callers can finish
  /// closing a loading/password overlay before the destination is presented.
  /// The route itself still provides native iOS interactive back navigation.
  static Future<T?> pushIOSPageRoute<T>(
    BuildContext context,
    Widget page, {
    bool popAll = false,
  }) {
    final result = Completer<T?>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        result.complete(null);
        return;
      }
      try {
        final navigator = Navigator.of(context);
        final route = createIOSPageRoute<T>(page);
        result.complete(popAll
            ? navigator.pushAndRemoveUntil(route, (_) => false)
            : navigator.push(route));
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    // An asynchronous download can finish while no frame is scheduled.
    WidgetsBinding.instance.ensureVisualUpdate();
    return result.future;
  }

  static pushPanelCupertinoRoute(BuildContext context, Widget page) {
    chewieProvider.panelScreenState?.pushPage(page);
  }

  static getFadeRoute(
    Widget page, {
    Duration? duration,
  }) {
    if (ResponsiveUtil.isIOS()) return createIOSRootRoute(page);
    return PageRouteBuilder(
      transitionDuration: duration ?? const Duration(milliseconds: 300),
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation secondaryAnimation) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: page,
        );
      },
    );
  }

  static pushFadeRoute(
    BuildContext context,
    Widget page, {
    Function(dynamic)? onThen,
    bool popAll = false,
  }) {
    return Navigator.push(
      context,
      getFadeRoute(page),
    ).then(onThen ?? (_) => {});
  }

  static pushDialogRoute(
    BuildContext context,
    Widget page, {
    bool barrierDismissible = true,
    bool showClose = true,
    bool fullScreen = false,
    double? preferMinWidth,
    double? preferMinHeight,
    Function(dynamic)? onThen,
    bool useFade = false,
    bool popAll = false,
    bool? modalSheet,
  }) {
    final bool effectiveModalSheet = modalSheet ??
        !ChewieHiveUtil.getBool("enableModalSheet", defaultValue: false);
    if (ResponsiveUtil.isLandscapeLayout()) {
      if (DialogNavigatorHelper.isMounted()) {
        DialogNavigatorHelper.pushPage(page);
      } else {
        DialogBuilder.showPageDialog(
          context,
          child: page,
          barrierDismissible: barrierDismissible,
          showCloseButton: showClose,
          fullScreen: fullScreen,
          onThen: onThen,
          preferMinWidth: preferMinWidth,
          preferMinHeight: preferMinHeight,
        );
      }
    } else {
      if (useFade) {
        pushFadeRoute(context, page, onThen: onThen, popAll: popAll);
      } else {
        pushCupertinoRoute(context, page,
            onThen: onThen, popAll: popAll, modalSheet: effectiveModalSheet);
      }
    }
  }
}
