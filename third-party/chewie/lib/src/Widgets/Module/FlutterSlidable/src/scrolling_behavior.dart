import 'package:flutter/widgets.dart';

import 'controller.dart';

// INTERNAL USE
// ignore_for_file: public_member_api_docs

class SlidableScrollingBehavior extends StatefulWidget {
  const SlidableScrollingBehavior({
    super.key,
    required this.controller,
    this.closeOnScroll = true,
    required this.child,
  });

  final SlidableController controller;

  /// Specifies to close the closest [Slidable] after the closest [Scrollable]'s
  /// position changed.
  ///
  /// Defaults to true.
  final bool closeOnScroll;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  _SlidableScrollingBehaviorState createState() =>
      _SlidableScrollingBehaviorState();
}

class _SlidableScrollingBehaviorState extends State<SlidableScrollingBehavior> {
  ScrollPosition? scrollPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    removeScrollingNotifierListener();
    addScrollingNotifierListener();
  }

  @override
  void didUpdateWidget(covariant SlidableScrollingBehavior oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.closeOnScroll != widget.closeOnScroll) {
      removeScrollingNotifierListener();
      addScrollingNotifierListener();
    }
  }

  @override
  void dispose() {
    removeScrollingNotifierListener();
    super.dispose();
  }

  void addScrollingNotifierListener() {
    if (widget.closeOnScroll) {
      scrollPosition = Scrollable.maybeOf(context)?.position;
      if (scrollPosition != null) {
        scrollPosition!.isScrollingNotifier.addListener(handleScrollingChanged);
      }
    }
  }

  void removeScrollingNotifierListener() {
    scrollPosition?.isScrollingNotifier.removeListener(handleScrollingChanged);
  }

  void handleScrollingChanged() {
    if (widget.closeOnScroll &&
        scrollPosition != null &&
        scrollPosition!.isScrollingNotifier.value) {
      widget.controller.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
