import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../widgets/context_menu_state.dart';

/// Represents an entry in a context menu.
///
/// This class is used to define individual items that can be displayed within a context menu.
///
/// see:
/// - [ContextMenuItem]
///
abstract base class ContextMenuEntry {
  const ContextMenuEntry();

  /// Builds the widget representation of the context menu entry.
  ///
  /// - [context] - The context of the widget.
  /// - [menuState] - The state of the current context menu.
  Widget builder(BuildContext context, ContextMenuState menuState);

  /// Called when the mouse pointer enters the area of the context menu entry.
  void onMouseEnter(PointerEnterEvent event, ContextMenuState menuState) {}

  /// Called when the mouse pointer exits the area of the context menu entry.
  void onMouseExit(PointerExitEvent event, ContextMenuState menuState) {}

  /// Called when the mouse pointer hovers over the context menu entry.
  void onMouseHover(PointerHoverEvent event, ContextMenuState menuState) {}

  String get debugLabel =>
      '$runtimeType ${hashCode.toString().substring(0, 5)}';
}
