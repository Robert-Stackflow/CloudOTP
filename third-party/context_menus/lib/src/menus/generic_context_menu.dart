import 'dart:async';

import 'package:flutter/material.dart';

import '../../context_menus.dart';

/// Pass a list of ButtonConfigs, and this will create a basic context menu dynamically.
class GenericContextMenu extends StatefulWidget {
  const GenericContextMenu({
    required this.buttonConfigs,
    this.injectDividers = false,
    this.autoClose = true,
    this.buttonStyle,
    super.key,
  });

  final bool injectDividers;
  final bool autoClose;
  final ContextMenuButtonStyle? buttonStyle;
  final List<ContextMenuButtonConfig?> buttonConfigs;

  @override
  GenericContextMenuState createState() => GenericContextMenuState();
}

class GenericContextMenuState extends State<GenericContextMenu>
    with ContextMenuStateMixin {
  @override
  Widget build(BuildContext context) {
    // Guard against an empty list
    if ((widget.buttonConfigs.isEmpty)) {
      // auto-close the menu since it's empty
      scheduleMicrotask(() => context.contextMenuOverlay.hide());
      return Container(); // Need to return something, but it will be thrown away next frame.
    }
    // Interleave dividers into the menu, use null as a marker to indicate a divider at some position.
    if (widget.injectDividers) {
      for (var i = widget.buttonConfigs.length - 2; i-- > 1; i++) {
        widget.buttonConfigs.add(null);
      }
    }
    return cardBuilder.call(
      context,
      // Create a list of Buttons / Dividers
      widget.buttonConfigs.map(
        (config) {
          // build a divider on null
          if (config == null ||
              config.type == ContextMenuButtonConfigType.divider) {
            return buildDivider();
          }
          // If not null, build a btn
          VoidCallback? action = config.onPressed;
          // Wrap external action in handlePressed so menu will auto-close
          if (widget.autoClose && action != null) {
            action = () => handlePressed(context, config.onPressed!);
          }
          // Build btn
          return buttonBuilder.call(
              context,
              ContextMenuButtonConfig(
                config.label,
                icon: config.icon,
                iconHover: config.iconHover,
                shortcutLabel: config.shortcutLabel,
                onPressed: action,
                type: config.type,
                checked: config.checked,
              ),
              widget.buttonStyle);
        },
      ).toList(),
    );
  }
}
