import 'package:flutter/material.dart';

import 'context_menu_provider.dart';
import 'context_menu_state.dart';
import 'menu_entry_widget.dart';

/// Widget that displays the context menu.
///
/// This widget is used internally.
///
/// see:
/// - [ContextMenuState]

class ContextMenuWidget extends StatelessWidget {
  final ContextMenuState menuState;
  final FocusNode? focusNode;

  const ContextMenuWidget({
    super.key,
    required this.menuState,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return ContextMenuProvider(
      state: menuState,
      child: Builder(
        builder: (context) {
          final state = ContextMenuState.of(context);
          state.verifyPosition(context);
          return Positioned(
            left: state.position.dx,
            top: state.position.dy,
            child: OverlayPortal(
              controller: state.overlayController,
              overlayChildBuilder: state.submenuBuilder,
              child: FocusScope(
                autofocus: true,
                node: state.focusScopeNode,
                child: Opacity(
                  opacity: state.isPositionVerified ? 1.0 : 0.0,
                  child: _buildMenuView(context, state),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the context menu view.
  Widget _buildMenuView(BuildContext context, ContextMenuState state) {
    // final parentItem = state.parentItem;
    // if (parentItem?.isSubmenuItem == true) {
    //   print(parentItem?.debugLabel);
    // }

    var boxDecoration = BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).shadowColor,
          offset: const Offset(0, 4),
          blurRadius: 10,
          spreadRadius: 1,
        ).scale(2),
      ],
      borderRadius: state.borderRadius ?? BorderRadius.circular(8.0),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: 0.8,
        end: 1.0,
      ),
      duration: const Duration(milliseconds: 60),
      builder: (context, value, child) {
        return Transform.scale(
          alignment: state.spawnAlignment,
          scale: value,
          child: Container(
            padding: state.padding,
            // constraints: BoxConstraints(maxWidth: state.maxWidth),
            clipBehavior: state.clipBehavior,
            decoration: state.boxDecoration ?? boxDecoration,
            child: Material(
              type: MaterialType.transparency,
              child: IntrinsicWidth(
                child: Column(
                  children: [
                    for (final item in state.entries)
                      MenuEntryWidget(entry: item, focusNode: focusNode),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
