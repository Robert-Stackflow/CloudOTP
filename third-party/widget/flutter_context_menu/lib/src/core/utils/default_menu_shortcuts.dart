import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../widgets/context_menu_state.dart';
import '../models/context_menu_item.dart';

Map<ShortcutActivator, VoidCallback> defaultMenuShortcuts(
  BuildContext context,
  BaseContextMenuItem item,
  ContextMenuState menuState,
) {
  return {
    const SingleActivator(LogicalKeyboardKey.arrowRight): () {
      final bool isSubmenuOpen = menuState.isSubmenuOpen;
      final focusedItemIsNotTheSelectedItem =
          menuState.focusedEntry != menuState.selectedItem;
      if (item.isSubmenuItem &&
          !isSubmenuOpen &&
          focusedItemIsNotTheSelectedItem) {
        item.handleItemSelection(context);
      }
    },
    const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
      if (menuState.isSubmenu) {
        menuState.selfClose?.call();
      }
    },
    const SingleActivator(LogicalKeyboardKey.space): () =>
        item.handleItemSelection(context),
    const SingleActivator(LogicalKeyboardKey.enter): () =>
        item.handleItemSelection(context),
    const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
        item.handleItemSelection(context),
  };
}
