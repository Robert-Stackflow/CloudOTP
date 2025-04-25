import 'package:flutter/widgets.dart';

import 'context_menu_state.dart';

class ContextMenuProvider extends InheritedNotifier<ContextMenuState> {
  const ContextMenuProvider({
    super.key,
    required super.child,
    required ContextMenuState state,
  }) : super(notifier: state);
}
