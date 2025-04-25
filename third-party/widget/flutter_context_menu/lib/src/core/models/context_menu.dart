import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../utils/default_menu_shortcuts.dart';
import '../utils/helpers.dart';
import 'context_menu_entry.dart';

/// Represents a context menu data model.
class FlutterContextMenu {
  /// The position of the context menu.
  Offset? position;

  /// The entries of the context menu.
  List<ContextMenuEntry> entries;

  /// The padding of the context menu.
  ///
  /// Defaults to [EdgeInsets.all(4.0)]
  EdgeInsets padding;

  /// The border radius around the context menu.
  BorderRadiusGeometry? borderRadius;

  /// The maximum width of the context menu.
  ///
  /// Defaults to 350.0
  double maxWidth;

  /// The clip behavior of the context menu.
  ///
  /// Defaults to [Clip.antiAlias]
  Clip clipBehavior;

  /// The decoration of the context menu.
  BoxDecoration? boxDecoration;

  /// A map of shortcuts to be bound to the context menu and the nested context menus.
  ///
  /// Note: This overides the default shortcuts in [defaultMenuShortcuts] if any of the keys match.
  Map<ShortcutActivator, VoidCallback> shortcuts;

  FocusNode? focusNode;

  FlutterContextMenu({
    required this.entries,
    this.position,
    EdgeInsets? padding,
    this.borderRadius,
    double? maxWidth,
    Clip? clipBehavior,
    this.boxDecoration,
    this.focusNode,
    Map<ShortcutActivator, VoidCallback>? shortcuts,
  })  : padding = padding ?? const EdgeInsets.all(8.0),
        maxWidth = maxWidth ?? 480.0,
        clipBehavior = clipBehavior ?? Clip.antiAlias,
        shortcuts = shortcuts ?? const {};

  /// A shortcut method to show the context menu.
  ///
  /// For a more customized context menu, use [showContextMenu]
  Future<T?> show<T>(BuildContext context) {
    return showContextMenu(context, contextMenu: this, focusNode: focusNode);
  }

  Future<T?> showAtMousePosition<T>(
      BuildContext context, Offset position) async {
    return showContextMenu(context,
        contextMenu: copyWith(position: position), focusNode: focusNode);
  }

  FlutterContextMenu copyWith({
    Offset? position,
    List<ContextMenuEntry>? entries,
    EdgeInsets? padding,
    BorderRadiusGeometry? borderRadius,
    double? maxWidth,
    Clip? clipBehavior,
    BoxDecoration? boxDecoration,
  }) {
    return FlutterContextMenu(
      position: position ?? this.position,
      entries: entries ?? this.entries,
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
      maxWidth: maxWidth ?? this.maxWidth,
      clipBehavior: clipBehavior ?? this.clipBehavior,
      boxDecoration: boxDecoration ?? this.boxDecoration,
    );
  }
}
