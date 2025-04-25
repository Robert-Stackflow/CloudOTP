import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';

/// Controls the sizing parameters for the [child] Widget.
class ResizableChild extends Equatable {
  /// Create a new instance of the [ResizableChild] class.
  const ResizableChild({
    required this.child,
    this.size = const ResizableSize.expand(),
    this.divider = const ResizableDivider(),
  });

  /// The size of the corresponding widget. May use a ratio of the
  /// available space, an absolute size in logical pixels, or it can
  /// auto-expand to fill available space.
  ///
  /// ```dart
  /// // Ratio of available space
  /// size: const ResizableSize.ratio(0.25);
  ///
  /// // Absolute size in logical pixels
  /// size: const ResizableSize.pixels(300);
  ///
  /// // Auto-fill available space
  /// size: const ResizableSize.expand(),
  ///
  /// // Conform to the child's intrinsic size
  /// size: const ResizableSize.shrink(),
  /// ```
  final ResizableSize size;

  /// The child [Widget] to be displayed.
  final Widget child;

  /// The divider configuration to be used after this child.
  ///
  /// If not provided, the default divider will be used.
  ///
  /// If this is the last child, the divider will not be used.
  final ResizableDivider divider;

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [size, child.runtimeType, divider];
}
