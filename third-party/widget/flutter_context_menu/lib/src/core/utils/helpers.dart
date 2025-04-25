import 'package:flutter/widgets.dart';

import '../../widgets/context_menu_state.dart';
import '../../widgets/context_menu_widget.dart';
import '../models/context_menu.dart';

/// Shows the root context menu popup.
Future<T?> showContextMenu<T>(
  BuildContext context, {
  required FlutterContextMenu contextMenu,
  RouteSettings? routeSettings,
  bool? opaque,
  bool? barrierDismissible,
  Color? barrierColor,
  String? barrierLabel,
  Duration? transitionDuration,
  Duration? reverseTransitionDuration,
  RouteTransitionsBuilder? transitionsBuilder,
  bool allowSnapshotting = true,
  bool maintainState = false,
  FocusNode? focusNode,
}) async {
  final menuState = ContextMenuState(menu: contextMenu);
  return await Navigator.push<T>(
    context,
    PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            ContextMenuWidget(menuState: menuState, focusNode: focusNode)
          ],
        );
      },
      settings: routeSettings ?? const RouteSettings(name: "context-menu"),
      fullscreenDialog: true,
      barrierDismissible: barrierDismissible ?? true,
      opaque: opaque ?? false,
      transitionDuration: transitionDuration ?? Duration.zero,
      reverseTransitionDuration: reverseTransitionDuration ?? Duration.zero,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      transitionsBuilder: transitionsBuilder ?? _defaultTransitionsBuilder,
      allowSnapshotting: allowSnapshotting,
      maintainState: maintainState,
    ),
  );
}

Widget _defaultTransitionsBuilder(
    context, animation, secondaryAnimation, child) {
  return child;
}
