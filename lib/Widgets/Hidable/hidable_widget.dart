//
// Copyright 2021-2022 present Insolite. All rights reserved.
// Use of this source code is governed by Apache 2.0 license
// that can be found in the LICENSE file.
//

import 'package:flutter/material.dart';

import 'hidable_controller.dart';

/// Hidable is a widget that makes any static located widget hideable while scrolling.
///
/// To use Hidable, wrap your static located widget with [Hidable].
/// This will enable scroll-to-hide functionality for the widget.
///
/// Note: The scroll controller provided to [Hidable] must also be given to your scrollable widget,
/// such as [ListView], [GridView], etc.
///
/// For more information, refer to the [documentation](https://github.com/insolite-dev/hidable#readme).
class Hidable extends StatelessWidget implements PreferredSizeWidget {
  /// The child widget to which you want to add scroll-to-hide effect.
  ///
  /// This should be a static located widget, such as [BottomNavigationBar], [FloatingActionButton], [AppBar], etc.
  final Widget child;

  /// The main scroll controller that listens to user's scrolls.
  ///
  /// This scroll controller must also be provided to your scrollable widget.
  final ScrollController controller;

  /// Enable or disable opacity animation.
  ///
  /// This property is deprecated. Use [enableOpacityAnimation] instead.
  @Deprecated('Use enableOpacityAnimation instead.')
  final bool wOpacity;

  /// Enable or disable opacity animation.
  ///
  /// Defaults to `true`.
  final bool enableOpacityAnimation;

  /// A customization field for [Hidable]'s `preferredSize`.
  ///
  /// As default the preferred size is is the [AppBar]'s `preferredSize`.
  /// (56 heights with page-size width).
  final Size preferredWidgetSize;

  /// This parameter allows you to define a custom visibility behavior for the [child] widget
  /// based on scrolling actions. You can provide a function of type [HidableVisibility]
  /// to determine when and how the widget should be hidden or revealed during scrolling.
  ///
  /// Example usage:
  /// ```dart
  /// Hidable(
  ///   child: MyWidget(),
  ///   controller: scrollController,
  ///   visibility: (position, currentVisibility) {
  ///     // Custom visibility logic here.
  ///     // Return the updated visibility value.
  ///   },
  /// )
  /// ```
  ///
  /// If not provided, the default visibility behavior will be used.
  final HidableVisibility? visibility;

  /// A factor that determines the speed at which the [child] widget's visibility changes
  /// when scrolling occurs.
  ///
  /// The `deltaFactor` value should be a double between 0.0 and 1.0, where:
  /// - 0.0 indicates that the [child] widget's visibility won't change when scrolling.
  /// - 1.0 indicates that the [child] widget's visibility will change rapidly when scrolling.
  ///
  /// A lower `deltaFactor` value results in a slower change in visibility, making the
  /// [child] widget's hiding/revealing behavior more gradual. Conversely, a higher value
  /// makes the change in visibility more immediate.
  ///
  /// The default value is 0.04, which provides a moderate speed of visibility change.
  final double deltaFactor;

  const Hidable({
    super.key,
    required this.child,
    required this.controller,
    @deprecated this.wOpacity = true,
    this.enableOpacityAnimation = true,
    this.preferredWidgetSize = const Size.fromHeight(56),
    this.visibility,
    this.deltaFactor = 0.06,
  });

  @override
  Size get preferredSize => preferredWidgetSize;

  @override
  Widget build(BuildContext context) {
    final hidable = controller.hidable(hashCode, visibility, deltaFactor);
    return ValueListenableBuilder<double>(
      valueListenable: hidable.visibilityNotifier,
      builder: (_, factor, __) => Align(
        heightFactor: factor,
        alignment: const Alignment(0, -1),
        child: SizedBox(
          height: preferredWidgetSize.height,
          child: enableOpacityAnimation
              ? Opacity(opacity: factor, child: child)
              : child,
        ),
      ),
    );
  }
}
