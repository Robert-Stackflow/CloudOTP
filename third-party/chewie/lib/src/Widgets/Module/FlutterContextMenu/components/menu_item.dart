import 'package:flutter/material.dart';

import '../core/models/context_menu_entry.dart';
import '../core/models/context_menu_item.dart';
import '../widgets/context_menu_state.dart';
import 'menu_divider.dart';
import 'menu_header.dart';

enum MenuItemType { normal, text, divider, checkbox }

enum MenuItemStatus { normal, success, warning, error }

class MenuItemStyle {
  const MenuItemStyle({
    this.backgroundColor,
    this.normalColor,
    this.successColor,
    this.warningColor,
    this.errorColor,
    this.padding,
    this.textStyle,
    this.shortcutTextStyle,
    this.disabledOpacity = 0.7,
    this.radius = 8,
    this.focusedBorder,
  });

  final double radius;
  final Color? backgroundColor;
  final Color? normalColor;
  final Color? successColor;
  final Color? warningColor;
  final Color? errorColor;
  final Border? focusedBorder;
  final EdgeInsets? padding;
  final TextStyle? textStyle;
  final TextStyle? shortcutTextStyle;
  final double disabledOpacity;

  MenuItemStyle copyWith({
    Color? backgroundColor,
    Color? normalColor,
    Color? successColor,
    Color? warningColor,
    Color? errorColor,
    EdgeInsets? padding,
    TextStyle? textStyle,
    TextStyle? shortcutTextStyle,
    double disabledOpacity = 0.7,
    double radius = 8,
    Border? focusedBorder,
  }) {
    return MenuItemStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      normalColor: normalColor ?? this.normalColor,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      errorColor: errorColor ?? this.errorColor,
      padding: padding ?? this.padding,
      textStyle: textStyle ?? this.textStyle,
      shortcutTextStyle: shortcutTextStyle ?? this.shortcutTextStyle,
      disabledOpacity: disabledOpacity,
      radius: radius,
      focusedBorder: focusedBorder ?? this.focusedBorder,
    );
  }
}

/// Represents a selectable item in a context menu.
///
/// This class is used to define individual items that can be displayed within
/// a context menu.
///
/// #### Parameters:
/// - [label] - The title of the context menu item
/// - [iconData] - The icon of the context menu item.
/// - [constraints] - The height of the context menu item.
/// - [focusNode] - The focus node of the context menu item.
/// - [value] - The value associated with the context menu item.
/// - [items] - The list of subitems associated with the context menu item.
/// - [onPressed] - The callback that is triggered when the context menu item
///   is selected. If the item has subitems, it toggles the visibility of the
///   submenu. If not, it pops the current context menu and returns the
///   associated value.
/// - [constraints] - The constraints of the context menu item.
///
/// see:
/// - [ContextMenuEntry]
/// - [MenuHeader]
/// - [MenuDivider]
///
final class FlutterContextMenuItem<T> extends BaseContextMenuItem<T> {
  final String label;
  final IconData? iconData;
  final MenuItemStyle? style;
  final MenuItemStatus status;
  final MenuItemType type;
  final bool checked;

  const FlutterContextMenuItem(
    this.label, {
    this.iconData,
    super.value,
    super.onPressed,
    this.style,
    this.status = MenuItemStatus.normal,
  })  : type = MenuItemType.normal,
        checked = false;

  const FlutterContextMenuItem.submenu(
    this.label, {
    required List<ContextMenuEntry> items,
    this.iconData,
    super.onPressed,
    this.style,
    this.status = MenuItemStatus.normal,
  })  : type = MenuItemType.normal,
        checked = false,
        super.submenu(items: items);

  const FlutterContextMenuItem.checkbox(
    this.label, {
    super.value,
    super.onPressed,
    this.style,
    required this.checked,
    this.status = MenuItemStatus.normal,
  })  : type = MenuItemType.checkbox,
        iconData = Icons.check_rounded;

  FlutterContextMenuItem.divider()
      : label = '',
        iconData = null,
        style = null,
        checked = false,
        status = MenuItemStatus.normal,
        type = MenuItemType.divider;

  @override
  Widget builder(BuildContext context, ContextMenuState menuState,
      [FocusNode? focusNode]) {
    if (type == MenuItemType.divider) {
      return MenuDivider.buildDivider(context);
    }

    bool isFocused = menuState.focusedEntry == this;
    const background = Colors.transparent;

    final ThemeData theme = Theme.of(context);
    final MenuItemStyle mStyle = MenuItemStyle(
      textStyle: style?.textStyle ?? theme.textTheme.bodyMedium,
      shortcutTextStyle:
          style?.shortcutTextStyle ?? theme.textTheme.labelMedium,
      backgroundColor: style?.backgroundColor ?? Colors.transparent,
      padding: style?.padding ??
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      focusedBorder: style?.focusedBorder,
      normalColor: style?.normalColor,
      successColor: style?.successColor ?? Colors.green,
      warningColor: style?.warningColor ?? Colors.orange,
      errorColor: style?.errorColor ?? Colors.red,
      radius: 8,
      disabledOpacity: 0.6,
    );

    Color? iconTextColor = mStyle.normalColor ?? mStyle.textStyle?.color;
    switch (status) {
      case MenuItemStatus.normal:
        iconTextColor = mStyle.normalColor ?? mStyle.textStyle?.color;
        break;
      case MenuItemStatus.success:
        iconTextColor = mStyle.successColor;
        break;
      case MenuItemStatus.warning:
        iconTextColor = mStyle.warningColor;
        break;
      case MenuItemStatus.error:
        iconTextColor = mStyle.errorColor;
        break;
    }

    TextStyle labelTextStyle = mStyle.textStyle!;
    labelTextStyle = labelTextStyle.copyWith(color: iconTextColor);
    final normalTextColor = labelTextStyle.color!.withValues(alpha: 0.8);
    final foregroundColor = isFocused ? labelTextStyle.color : normalTextColor;

    final Border? focusedBorder = isFocused ? mStyle.focusedBorder : null;

    return Material(
      color: isFocused ? Theme.of(context).hoverColor : background,
      borderRadius: BorderRadius.circular(mStyle.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(mStyle.radius),
        onTap: () => handleItemSelection(context),
        canRequestFocus: false,
        child: Container(
          constraints: const BoxConstraints(minWidth: 160.0),
          padding: mStyle.padding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: focusedBorder,
            borderRadius: BorderRadius.circular(mStyle.radius),
          ),
          child: Row(
            children: [
              if (type != MenuItemType.checkbox && iconData != null)
                Icon(
                  iconData,
                  size: 20,
                  color: foregroundColor,
                ),
              if (type == MenuItemType.checkbox && checked)
                Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: foregroundColor,
                ),
              if (type == MenuItemType.checkbox && !checked)
                const SizedBox(width: 20, height: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelTextStyle.apply(color: foregroundColor),
                ),
              ),
              const SizedBox(width: 8.0),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Icon(
                  isSubmenuItem ? Icons.arrow_right : null,
                  size: 16.0,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  String get debugLabel => "[${hashCode.toString().substring(0, 5)}] $label";
}
