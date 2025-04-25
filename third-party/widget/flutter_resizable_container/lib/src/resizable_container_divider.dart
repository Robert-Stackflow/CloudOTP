import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/divider_painter.dart';
import 'package:flutter_resizable_container/src/resizable_divider.dart';
import 'package:flutter_resizable_container/src/resizable_size.dart';

class ResizableContainerDivider extends StatefulWidget {
  const ResizableContainerDivider({
    super.key,
    required this.direction,
    required this.config,
    required void Function(double) this.onResizeUpdate,
  });

  const ResizableContainerDivider.placeholder({
    super.key,
    required this.config,
    required this.direction,
  }) : onResizeUpdate = null;

  final Axis direction;
  final void Function(double)? onResizeUpdate;
  final ResizableDivider config;

  @override
  State<ResizableContainerDivider> createState() =>
      _ResizableContainerDividerState();
}

class _ResizableContainerDividerState extends State<ResizableContainerDivider> {
  bool isDragging = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = _getWidth(constraints.maxWidth);
      final height = _getHeight(constraints.maxHeight);

      return Align(
        alignment: switch (widget.config.crossAxisAlignment) {
          CrossAxisAlignment.start => switch (widget.direction) {
              Axis.horizontal => Alignment.topCenter,
              Axis.vertical => Alignment.centerLeft,
            },
          CrossAxisAlignment.end => switch (widget.direction) {
              Axis.horizontal => Alignment.bottomCenter,
              Axis.vertical => Alignment.bottomRight,
            },
          _ => Alignment.center,
        },
        child: MouseRegion(
          cursor: _getCursor(),
          onEnter: _onEnter,
          onExit: _onExit,
          child: GestureDetector(
            onVerticalDragStart: _onVerticalDragStart,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            onHorizontalDragStart: _onHorizontalDragStart,
            onHorizontalDragUpdate: _getOnHorizontalDragUpdate(
              Directionality.of(context),
            ),
            onHorizontalDragEnd: _onHorizontalDragEnd,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            child: CustomPaint(
              size: Size(width, height),
              painter: DividerPainter(
                direction: widget.direction,
                color: widget.config.color ?? Theme.of(context).dividerColor,
                thickness: widget.config.thickness,
                crossAxisAlignment: widget.config.crossAxisAlignment,
                length: widget.config.length,
                mainAxisAlignment: widget.config.mainAxisAlignment,
                padding: widget.config.padding,
              ),
            ),
          ),
        ),
      );
    });
  }

  MouseCursor _getCursor() {
    return switch (widget.direction) {
      Axis.horizontal =>
        widget.config.cursor ?? SystemMouseCursors.resizeLeftRight,
      Axis.vertical => widget.config.cursor ?? SystemMouseCursors.resizeUpDown,
    };
  }

  double _getHeight(double maxHeight) {
    return switch (widget.direction) {
      Axis.horizontal => switch (widget.config.length) {
          ResizableSizePixels(:final pixels) => min(pixels, maxHeight),
          ResizableSizeExpand() => maxHeight,
          ResizableSizeRatio(:final ratio) => maxHeight * ratio,
          ResizableSizeShrink() => 0.0,
        },
      Axis.vertical => widget.config.thickness + widget.config.padding,
    };
  }

  double _getWidth(double maxWidth) {
    return switch (widget.direction) {
      Axis.horizontal => widget.config.thickness + widget.config.padding,
      Axis.vertical => switch (widget.config.length) {
          ResizableSizePixels(:final pixels) => min(pixels, maxWidth),
          ResizableSizeExpand() => maxWidth,
          ResizableSizeRatio(:final ratio) => maxWidth * ratio,
          ResizableSizeShrink() => 0.0,
        },
    };
  }

  void _onEnter(PointerEnterEvent _) {
    setState(() => isHovered = true);
    widget.config.onHoverEnter?.call();
  }

  void _onExit(PointerExitEvent _) {
    setState(() => isHovered = false);

    if (!isDragging) {
      widget.config.onHoverExit?.call();
    }
  }

  void _onVerticalDragStart(DragStartDetails _) {
    if (widget.direction == Axis.vertical) {
      setState(() => isDragging = true);
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (widget.direction == Axis.vertical) {
      widget.onResizeUpdate?.call(details.delta.dy);
    }
  }

  void _onVerticalDragEnd(DragEndDetails _) {
    if (widget.direction == Axis.vertical) {
      setState(() => isDragging = false);

      if (!isHovered) {
        widget.config.onHoverExit?.call();
      }
    }
  }

  void _onHorizontalDragStart(DragStartDetails _) {
    if (widget.direction == Axis.horizontal) {
      setState(() => isDragging = true);
    }
  }

  void Function(DragUpdateDetails) _getOnHorizontalDragUpdate(
    TextDirection textDirection,
  ) {
    return (details) {
      if (widget.direction == Axis.horizontal) {
        final delta = details.delta.dx;

        widget.onResizeUpdate?.call(switch (textDirection) {
          TextDirection.ltr => delta,
          TextDirection.rtl => -delta,
        });
      }
    };
  }

  void _onHorizontalDragEnd(DragEndDetails _) {
    if (widget.direction == Axis.horizontal) {
      setState(() => isDragging = false);

      if (!isHovered) {
        widget.config.onHoverExit?.call();
      }
    }
  }

  void _onTapDown(TapDownDetails _) {
    widget.config.onTapDown?.call();
  }

  void _onTapUp(TapUpDetails _) {
    widget.config.onTapUp?.call();
  }
}
