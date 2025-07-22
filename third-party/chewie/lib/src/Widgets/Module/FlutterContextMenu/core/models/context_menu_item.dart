import 'package:flutter/material.dart';

import '../../widgets/context_menu_state.dart';
import '../../widgets/menu_entry_widget.dart';
import 'context_menu_entry.dart';

/// Represents a selectable item in a context menu.
///
/// The [BaseContextMenuItem] class is used to define individual items that can be displayed
/// within a context menu. It extends the [ContextMenuEntry] class, providing additional
/// functionality for handling item selection, submenus, and associated values.
///
/// A [BaseContextMenuItem] can have an associated [value] that can be returned when the item
/// is selected. It can also contain a list of [items] to represent submenus, enabling a
/// hierarchical structure within the context menu.
///
/// When a [BaseContextMenuItem] is selected, it triggers the [handleItemSelection] method, which
/// determines whether the item has subitems. If it does, it toggles the visibility of
/// the submenu associated with the item. If not, it pops the current context menu and
/// returns the associated [value].
///
/// #### Parameters:
/// - [value] - The value associated with the context menu item.
/// - [items] - The list of subitems associated with the context menu item.
/// - [onPressed] - The callback that is triggered when the context menu item is selected.
///
/// see:
/// - [ContextMenuEntry]
/// - [MenuItem]
/// - [MenuHeader]
/// - [MenuDivider]
///
abstract base class BaseContextMenuItem<T> extends ContextMenuEntry {
  final T? value;
  final List<ContextMenuEntry>? items;
  final VoidCallback? onPressed;

  const BaseContextMenuItem({
    this.value,
    this.onPressed,
  }) : items = null;

  const BaseContextMenuItem.submenu({
    required this.items,
    this.onPressed,
  }) : value = null;

  /// Indicates whether the menu item has subitems.
  ///
  /// Can be used to determine whether the item is a submenu.
  ///
  /// see:
  /// - [MenuItem]
  bool get isSubmenuItem => items != null;

  /// Indicates whether the menu item is using the focus node in a child widget.
  ///
  /// Used internally by the [MenuEntryWidget]
  bool get isFocusMaintained => false;

  /// Handles the selection of the context menu item.
  ///
  /// If the item has subitems, it toggles the submenu's visibility.
  /// Otherwise, it pops the current context menu and returns the [value].
  void handleItemSelection(BuildContext context) {
    final menuState = ContextMenuState.of(context);

    if (isSubmenuItem) {
      _toggleSubmenu(context, menuState);
    } else {
      menuState.setSelectedItem(this);
      if (Navigator.canPop(context)) {
        Navigator.pop(context, value);
      }
    }
    onPressed?.call();
  }

  /// Toggles the visibility of the submenu associated with this menu item.
  void _toggleSubmenu(BuildContext context, ContextMenuState menuState) {
    if (menuState.isSubmenuOpen &&
        menuState.focusedEntry == menuState.selectedItem) {
      menuState.closeSubmenu();
    } else {
      menuState.showSubmenu(context: context, parent: this);
    }
  }

  @override
  Widget builder(BuildContext context, ContextMenuState menuState,
      [FocusNode? focusNode]);
}
