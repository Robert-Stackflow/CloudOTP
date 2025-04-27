import 'package:flutter/material.dart';

import '../core/models/context_menu.dart';
import '../core/utils/helpers.dart';

/// A widget that shows a context menu when the user long presses or right clicks on the widget.
class ContextMenuRegion extends StatelessWidget {
  final FlutterContextMenu contextMenu;
  final Widget child;
  final ValueChanged<dynamic>? onItemSelected;
  final bool showOnClicked;
  final bool enable;

  const ContextMenuRegion({
    super.key,
    required this.contextMenu,
    required this.child,
    this.onItemSelected,
    this.showOnClicked = false,
    this.enable = true,
  });

  @override
  Widget build(BuildContext context) {
    Offset mousePosition = Offset.zero;

    return Listener(
      onPointerDown: (event) {
        mousePosition = event.position;
      },
      child: GestureDetector(
        onLongPress: enable ? () => _showMenu(context, mousePosition) : null,
        onSecondaryTap: enable ? () => _showMenu(context, mousePosition) : null,
        onTap: showOnClicked ? () => _showMenu(context, mousePosition) : null,
        child: child,
      ),
    );
  }

  void _showMenu(BuildContext context, Offset mousePosition) async {
    final menu =
        contextMenu.copyWith(position: contextMenu.position ?? mousePosition);
    final value = await showContextMenu(context, contextMenu: menu);
    onItemSelected?.call(value);
  }
}
