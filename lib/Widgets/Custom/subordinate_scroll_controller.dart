import 'package:flutter/cupertino.dart';

/// https://github.com/flutter/flutter/issues/118713#issuecomment-1416505982

/// A scroll controller subordinate to a parent controller, which
/// [createScrollPosition]s via the parent and attaches/detaches its positions
/// from the parent. This is useful for creating nested scroll controllers
/// for widgets with scrollbars that can actuate a parent scroll controller.
class SubordinateScrollController extends ScrollController {
  SubordinateScrollController(
    this.parent, {
    String subordinateDebugLabel = 'subordinate',
  }) : super(
          debugLabel: parent.debugLabel == null
              ? null
              : '${parent.debugLabel}/$subordinateDebugLabel',
          initialScrollOffset: parent.initialScrollOffset,
          keepScrollOffset: parent.keepScrollOffset,
        );
  final ScrollController parent;

  // Although some use cases might seem to be simplified if parent were made
  // settable, we can't really do this because scroll positions are owned by
  // Scrollables rather than the scroll controller, so the scroll view is
  // responsible for transferring positions from one controller to another. If
  // we were to try to do the transfer here, we would end up trying to dispose
  // of positions that Scrollables may still be holding on to.

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) =>
      parent.createScrollPosition(physics, context, oldPosition);

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    parent.attach(position);
  }

  @override
  void detach(ScrollPosition position) {
    parent.detach(position);
    super.detach(position);
  }

  @override
  void dispose() {
    for (final position in positions) {
      parent.detach(position);
    }

    super.dispose();
  }
}
