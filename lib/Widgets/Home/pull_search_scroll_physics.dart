import 'package:flutter/widgets.dart';

class PullSearchScrollPhysics extends AlwaysScrollableScrollPhysics {
  const PullSearchScrollPhysics(
      {required this.isPulling,
      this.clampPullOverscroll = false,
      super.parent});

  final bool Function() isPulling;
  final bool clampPullOverscroll;

  @override
  PullSearchScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      PullSearchScrollPhysics(
        isPulling: isPulling,
        clampPullOverscroll: clampPullOverscroll,
        parent: buildParent(ancestor),
      );

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // The custom hint owns iOS pull distance. Native bouncing would move the
    // list a second time, while changing boundaries mid-ballistic-scroll can
    // violate NestedScrollView's coordinated scroll ranges.
    if (clampPullOverscroll) {
      return const ClampingScrollPhysics()
          .applyBoundaryConditions(position, value);
    }
    // Consume the reverse drag in the pull hint before either scrolls.
    if (isPulling() &&
        position.pixels >= position.minScrollExtent &&
        value > position.pixels) {
      return value - position.pixels;
    }
    return super.applyBoundaryConditions(position, value);
  }
}
