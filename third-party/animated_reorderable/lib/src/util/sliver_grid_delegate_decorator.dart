import 'package:flutter/rendering.dart';

typedef LayoutCallback = void Function(SliverGridLayout layout);

abstract class SliverGridDelegateDecorator implements SliverGridDelegate {
  final SliverGridDelegate gridDelegate;

  SliverGridDelegateDecorator({required this.gridDelegate});

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) =>
      gridDelegate.getLayout(constraints);

  @override
  bool shouldRelayout(covariant SliverGridDelegate oldDelegate) {
    if (oldDelegate is SliverGridLayoutNotifier) {
      return gridDelegate.shouldRelayout(oldDelegate.gridDelegate);
    }
    return gridDelegate.shouldRelayout(oldDelegate);
  }
}

class SliverGridLayoutNotifier extends SliverGridDelegateDecorator {
  SliverGridLayoutNotifier({
    required super.gridDelegate,
    this.onLayout,
  });

  final LayoutCallback? onLayout;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final layout = super.getLayout(constraints);
    onLayout?.call(layout);
    return layout;
  }
}
