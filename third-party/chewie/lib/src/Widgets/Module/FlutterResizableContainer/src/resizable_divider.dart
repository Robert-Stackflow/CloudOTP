import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'resizable_size.dart';

class ResizableDivider extends Equatable {
  const ResizableDivider({
    this.thickness = 1.0,
    this.length = const ResizableSize.expand(),
    this.padding = 0,
    this.color,
    this.onHoverEnter,
    this.onHoverExit,
    this.onTapDown,
    this.onTapUp,
    this.cursor,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  })  : assert(thickness > 0, '[thickness] must be > 0.'),
        assert(
          length is! ResizableSizeShrink,
          'length does not support the "shrink" size',
        );

  @override
  bool get stringify => true;

  /// The thickness of the line drawn within the divider.
  ///
  /// Defaults to 1.0.
  final double thickness;

  /// The length of the divider along the cross-axis.
  ///
  /// Defaults to `ResizableSize.expand()`, which will take up the full length.
  /// If given a pixel value, the length will be the smaller of the provided value
  /// and the available space.
  final ResizableSize length;

  /// The main-axis padding around the divider line. The position of the line
  /// within this padding is dictated by the [alignment] property.
  final double padding;

  /// The alignment of the divider within its main-axis padding; `spaceAround`,
  /// `spaceBetween`, and `spaceEvenly` will have no effect.
  ///
  /// For example, use [MainAxisAlignment.center] to position the divider in the
  /// middle of the padding.
  final MainAxisAlignment mainAxisAlignment;

  /// The alignment of the divider along the cross-axis. If the divider takes up
  /// the full available space, this setting will have no effect. `stretch` and
  /// `baseline` will also have no effect.
  ///
  /// For example, use [CrossAxisAlignment.center] to position the divider in the
  /// middle of its cross-axis space. This is useful for creating a small "handle"
  /// in the middle of the space.
  final CrossAxisAlignment crossAxisAlignment;

  /// The color of the dividers between children.
  ///
  /// Defaults to [ThemeData.dividerColor].
  final Color? color;

  /// Triggers when the user's cursor begins hovering over this divider.
  final VoidCallback? onHoverEnter;

  /// Triggers when the user's cursor ends hovering over this divider.
  final VoidCallback? onHoverExit;

  /// Triggers when the user's tap is detected on this divider.
  final VoidCallback? onTapDown;

  /// Triggers when the user's tap is released on this divider.
  final VoidCallback? onTapUp;

  /// The cursor to display when hovering over this divider.
  final MouseCursor? cursor;

  @override
  List<Object?> get props => [
        thickness,
        length,
        padding,
        color,
        onHoverEnter,
        onHoverExit,
        onTapDown,
        onTapUp,
        cursor,
        mainAxisAlignment,
        crossAxisAlignment,
      ];
}
