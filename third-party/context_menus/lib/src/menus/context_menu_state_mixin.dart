import 'package:flutter/widgets.dart';
import '../../context_menus.dart';

/// Optional mixin for ContextMenu's. Provides:
/// handlePressed method that takes care of closing the menu after some action has been run.
/// card, button and divider builders, that check the for a  parent [ContextMenuOverlay]
mixin ContextMenuStateMixin<T extends StatefulWidget> on State<T> {
  /// Convenience method to auto-close the context menu when an action is triggered
  /// which you almost always want to do in a context menu.
  void handlePressed(BuildContext context, VoidCallback action) {
    action.call();
    overlay.hide();
  }

  /// Shortcut call to [ContextMenuOverlay].of(context)
  ContextMenuOverlayState get overlay => ContextMenuOverlay.of(context);

  /// Receives a list of buttons, and should wrap them with some container and layout widget (col/row).
  /// Defaults to a [ContextMenuCard] which is just a column with a background.
  ContextMenuCardBuilder get cardBuilder => overlay.cardBuilder ?? (_, children) => ContextMenuCard(children: children);

  /// Passed a config and (optional) style, should return a single button.
  /// Defaults to [ContextMenuButton]
  ContextMenuButtonBuilder get buttonBuilder {
    return overlay.buttonBuilder ??
        (_, config, [style]) {
          return ContextMenuButton(config, style: style ?? overlay.buttonStyle);
        };
  }

  /// Builds divider to separate sections in the menu
  Widget buildDivider() => overlay.dividerBuilder?.call(context) ?? ContextMenuDivider();
}
