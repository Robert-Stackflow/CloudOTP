import 'dart:math';

import 'package:flutter/material.dart';
import '../flutter_resizable_container.dart';

@visibleForTesting
class DividerPainter extends CustomPainter {
  const DividerPainter({
    required this.color,
    required this.direction,
    required this.thickness,
    required this.padding,
    required this.length,
    required this.crossAxisAlignment,
    required this.mainAxisAlignment,
  });

  final Axis direction;
  final double thickness;
  final double padding;
  final ResizableSize length;
  final Color color;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _getPath(size);
    final paint = _getPaint();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  Paint _getPaint() {
    return Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
  }

  Path _getPath(Size size) {
    final startingPoint = _getStartingPoint(size);
    final endingPoint = _getEndingPoint(size);

    return Path()
      ..moveTo(startingPoint.x, startingPoint.y)
      ..lineTo(endingPoint.x, endingPoint.y)
      ..close();
  }

  Point<double> _getStartingPoint(Size size) {
    if (direction == Axis.horizontal) {
      // If the direction is horizontal, the divider is a vertical line and the
      // "start" is at the top.

      final double xCoord = switch (mainAxisAlignment) {
        // If the mainAxisAlignment is `start`, the divider should sit at the
        // very left edge of the available space.
        MainAxisAlignment.start => thickness / 2,
        // If the mainAxisAlignment is `end`, we want to draw the line at the
        // very right edge of the available space.
        MainAxisAlignment.end => size.width - (thickness / 2),
        // In all other cases, we want to draw the line down the middle of the
        // available space.
        _ => size.width / 2,
      };

      return Point(xCoord, 0);
    }

    // If the direction is vertical, the divider is a horizontal line and the
    // "start" is at the left.

    final double yCoord = switch (mainAxisAlignment) {
      // If the mainAxisAlignment is `start`, the divider should be at the very
      // top of the available space.
      MainAxisAlignment.start => thickness / 2,
      // If the mainAxisAlignment is `end`, the divider should sit at the very
      // bottom edge of the available space.
      MainAxisAlignment.end => size.height - (thickness / 2),
      // In all other cases, the divider should sit in the middle of the
      // available space.
      _ => size.height / 2,
    };

    return Point(0, yCoord);
  }

  Point<double> _getEndingPoint(Size size) {
    if (direction == Axis.horizontal) {
      // If the direction is horizontal, the divider is a vertical line.

      final double xCoord = switch (mainAxisAlignment) {
        // If the mainAxisAlignment is "start", the divider should sit at the
        // left edge of the available space.
        MainAxisAlignment.start => thickness / 2,
        // If the mainAxisAlignment is `end`, the divider should sit at the
        // right edge of the available space.
        MainAxisAlignment.end => size.width - (thickness / 2),
        // In all other cases, the divider should sit in the middle of the
        // available space.
        _ => size.width / 2,
      };

      return Point(xCoord, size.height);
    }

    // If the direction is vertical, the divider is a horizontal line.

    final double yCoord = switch (mainAxisAlignment) {
      // If the mainAxisAlignment is `start`, the divider should sit at the top
      // edge of the available space.
      MainAxisAlignment.start => thickness / 2,
      // If the mainAxisAlignment is `end`, the divider should sit at the bottom
      // edge of the available space.
      MainAxisAlignment.end => size.height - (thickness / 2),
      // In all other cases, the divider should sit in the middle of the
      // available space.
      _ => size.height / 2,
    };

    return Point(size.width, yCoord);
  }
}
