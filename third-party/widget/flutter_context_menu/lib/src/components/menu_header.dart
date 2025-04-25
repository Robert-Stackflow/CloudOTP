import 'package:flutter/material.dart';

import '../core/models/context_menu_entry.dart';
import '../widgets/context_menu_state.dart';
import 'menu_divider.dart';
import 'menu_item.dart';

/// Represents a text header in a context menu.
///
/// This class is used to define a header that can be displayed within a context menu.
///
/// #### Parameters:
/// - [text] - The text of the header.
/// - [disableUppercase] - Whether to disable the text in uppercase.
///
/// see:
/// - [ContextMenuEntry]
/// - [MenuDivider]
/// - [FlutterContextMenuItem]
///
final class MenuHeader extends ContextMenuEntry {
  final String text;
  final bool disableUppercase;

  const MenuHeader({
    required this.text,
    this.disableUppercase = false,
  });

  @override
  Widget builder(BuildContext context, ContextMenuState menuState) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          disableUppercase ? text : text.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
              ),
        ),
      ),
    );
  }
}
