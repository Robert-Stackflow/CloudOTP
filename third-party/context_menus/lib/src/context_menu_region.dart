// Helper widget, to dispatch Notifications when a right-click is detected on some child
import 'package:flutter/widgets.dart';

import '../context_menus.dart';

enum ContextMenuShowBehavior { tap, secondaryTap, longPress }

/// Wraps any widget in a GestureDetector and calls [ContextMenuOverlay].show
class ContextMenuRegion extends StatelessWidget {
  const ContextMenuRegion({
    super.key,
    required this.child,
    required this.contextMenu,
    this.isEnabled = true,
    this.behavior = const [
      ContextMenuShowBehavior.secondaryTap,
      ContextMenuShowBehavior.longPress
    ],
  });

  final Widget child;
  final Widget contextMenu;
  final bool isEnabled;
  final List<ContextMenuShowBehavior> behavior;

  @override
  Widget build(BuildContext context) {
    void showMenu() {
      // calculate widget position on screen
      context.contextMenuOverlay.show(contextMenu);
    }

    if (isEnabled == false) return child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: behavior.contains(ContextMenuShowBehavior.tap) ? showMenu : null,
      onSecondaryTap: behavior.contains(ContextMenuShowBehavior.secondaryTap)
          ? showMenu
          : null,
      onLongPress: behavior.contains(ContextMenuShowBehavior.longPress)
          ? showMenu
          : null,
      child: child,
    );
  }
}
