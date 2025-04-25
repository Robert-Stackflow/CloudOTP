import 'package:animated_tree_view/tree_view/tree_node.dart';
import 'package:animated_tree_view/tree_view/tree_view_state_helper.dart';
import 'package:flutter/material.dart';

enum IndentStyle {
  /// Do not apply any indentation or scoping lines
  none,

  /// Apply scoping lines as indents
  scopingLine,

  /// Use square joints as connectors for indents
  squareJoint,

  /// Use round joints as connectors for indents
  roundJoint,
}

/// Configuration class for building the [Indent].
class Indentation {
  static const DEF_INDENT_WIDTH = 24.0;

  /// The [width] that an [Indent] will take before building the actual content
  /// By default [DEF_INDENT_WIDTH]=24.0 is used for [width].
  final double width;

  /// Set an [offset] to move the [Indent] joint in the x, y directions.
  /// Scoping lines will only by affected by the y-component of the [offset].
  /// By default the joint is drawn at the y-center and 12dps left of the content.
  /// By default [Offset.zero] is used for [offset]
  final Offset offset;

  /// Sets the [thickness] of the line used for indents and scoping lines
  /// By default 1 is used for [thickness]
  final double thickness;

  /// The [IndentStyle] used to draw the [Indent]. The scoping lines are not
  /// affected by the [style].
  /// By default [IndentStyle.squareJoint] is used as [style]
  final IndentStyle style;

  /// The [color] used to to draw the lines for indents and scoping lines.
  /// By default light grey [0xFFBDBDBD] is used for [color].
  final Color color;

  const Indentation({
    this.width = DEF_INDENT_WIDTH,
    this.thickness = 1,
    this.style = IndentStyle.squareJoint,
    this.color = const Color(0xFFBDBDBD),
    this.offset = Offset.zero,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Indentation &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          offset == other.offset &&
          thickness == other.thickness &&
          style == other.style &&
          color == other.color;

  @override
  int get hashCode =>
      width.hashCode ^
      offset.hashCode ^
      thickness.hashCode ^
      style.hashCode ^
      color.hashCode;
}

@protected
class Indent extends StatelessWidget {
  final Indentation indentation;
  final ITreeNode node;
  final Widget child;
  final int minLevelToIndent;
  final LastChildCacheManager lastChildCacheManager;

  const Indent({
    super.key,
    required this.indentation,
    required this.child,
    required this.node,
    required this.minLevelToIndent,
    required this.lastChildCacheManager,
  });

  @override
  Widget build(BuildContext context) {
    bool isRtl = Directionality.of(context) == TextDirection.rtl;

    final content = Padding(
      padding: EdgeInsetsDirectional.only(
        start: (indentation.width * (node.level - minLevelToIndent)).clamp(
          0.0,
          double.maxFinite,
        ),
      ),
      child: child,
    );

    if (node.level <= minLevelToIndent || indentation.style == IndentStyle.none)
      return content;

    return CustomPaint(
      foregroundPainter: _IndentationPainter(
        indentation: indentation,
        node: node,
        minLevelToIndent: minLevelToIndent,
        isRtl: isRtl,
        lastChildCacheManager: lastChildCacheManager,
      ),
      child: content,
    );
  }
}

class _IndentationPainter extends CustomPainter {
  final Indentation indentation;
  final ITreeNode node;
  final int minLevelToIndent;
  final LastChildCacheManager lastChildCacheManager;
  final bool isRtl;

  const _IndentationPainter({
    required this.indentation,
    required this.node,
    required this.minLevelToIndent,
    required this.lastChildCacheManager,
    required this.isRtl,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isRtl) {
      canvas.save();
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    final strokeWidth = indentation.thickness;
    final totalWidth = (indentation.width * (node.level - minLevelToIndent))
        .clamp(0.0, double.maxFinite);
    bool shouldDrawBottom = !lastChildCacheManager.isLastChild(node);

    final paint = Paint()
      ..color = indentation.color
      ..style = PaintingStyle.fill;

    final center = Size(totalWidth - 12, size.height / 2);

    final topOrigin = Offset(
      center.width + indentation.offset.dx,
      0,
    );

    final cornerOuter = Offset(
      center.width + indentation.offset.dx - strokeWidth / 2,
      center.height + indentation.offset.dy + strokeWidth / 2,
    );

    final cornerInner = Offset(
      center.width + indentation.offset.dx + (strokeWidth * 1.5),
      center.height + indentation.offset.dy + strokeWidth / 2,
    );

    final end = Offset(
      totalWidth,
      center.height + indentation.offset.dy,
    );

    final bottom = Offset(
      center.width + indentation.offset.dx,
      size.height,
    );

    switch (indentation.style) {
      case IndentStyle.scopingLine:
        canvas.drawRect(
            Rect.fromLTRB(
              topOrigin.dx - 0.35,
              topOrigin.dy,
              topOrigin.dx + strokeWidth - 0.35,
              bottom.dy,
            ),
            paint);
        break;
      case IndentStyle.roundJoint:
        _drawWithRoundedCorners(
          canvas: canvas,
          paint: paint,
          drawBottom: shouldDrawBottom,
          center: center,
          strokeWidth: strokeWidth,
          topOrigin: topOrigin,
          cornerOuter: cornerOuter,
          cornerInner: cornerInner,
          end: end,
          bottom: bottom,
        );
        break;
      case IndentStyle.squareJoint:
      default:
        _drawWithSquareCorners(
          canvas: canvas,
          paint: paint,
          drawBottom: shouldDrawBottom,
          center: center,
          strokeWidth: strokeWidth,
          topOrigin: topOrigin,
          cornerOuter: cornerOuter,
          cornerInner: cornerInner,
          end: end,
          bottom: bottom,
        );
        break;
    }

    if (node.parent != null)
      _drawScopingLines(
        canvas: canvas,
        origin: Offset(topOrigin.dx - indentation.width, topOrigin.dy),
        strokeWidth: strokeWidth,
        bottom: bottom.dy,
        node: node.parent! as ITreeNode,
        paint: paint,
        drawLastChild: indentation.style == IndentStyle.scopingLine,
      );

    if (isRtl) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_IndentationPainter oldDelegate) => true;

  void _drawWithRoundedCorners({
    required Canvas canvas,
    required Paint paint,
    required double strokeWidth,
    required Size center,
    required Offset topOrigin,
    required Offset cornerOuter,
    required Offset cornerInner,
    required Offset end,
    required Offset bottom,
    required bool drawBottom,
  }) {
    final pathTop = Path()
      ..moveTo(topOrigin.dx - strokeWidth / 2, topOrigin.dy)
      ..lineTo(cornerOuter.dx, cornerOuter.dy - (strokeWidth * 2))
      ..relativeArcToPoint(
        Offset(strokeWidth * 2, strokeWidth * 2),
        radius: Radius.circular(strokeWidth * 2),
        clockwise: false,
      )
      ..lineTo(end.dx, cornerOuter.dy)
      ..relativeLineTo(0, -strokeWidth)
      ..lineTo(cornerInner.dx, cornerInner.dy - strokeWidth)
      ..relativeArcToPoint(
        Offset(-strokeWidth, -strokeWidth),
        radius: Radius.circular(strokeWidth),
        clockwise: true,
      )
      ..lineTo(topOrigin.dx + strokeWidth / 2, 0)
      ..close();

    if (!drawBottom) {
      canvas.drawPath(pathTop, paint);
      return;
    }

    final pathBottom = Path()
      ..moveTo(cornerInner.dx, cornerInner.dy - strokeWidth)
      ..relativeArcToPoint(
        Offset(-strokeWidth * 2, strokeWidth * 2),
        radius: Radius.circular(strokeWidth * 2),
        clockwise: false,
      )
      ..lineTo(cornerOuter.dx, bottom.dy)
      ..relativeLineTo(strokeWidth, 0)
      ..lineTo(cornerOuter.dx + strokeWidth, cornerInner.dy + strokeWidth)
      ..relativeArcToPoint(
        Offset(strokeWidth, -strokeWidth),
        radius: Radius.circular(strokeWidth),
        clockwise: true,
      )
      ..close();

    final combinedPath = Path.combine(PathOperation.union, pathTop, pathBottom);
    canvas.drawPath(combinedPath, paint);
  }

  void _drawWithSquareCorners({
    required Canvas canvas,
    required Paint paint,
    required double strokeWidth,
    required Size center,
    required Offset topOrigin,
    required Offset cornerOuter,
    required Offset cornerInner,
    required Offset end,
    required Offset bottom,
    required bool drawBottom,
  }) {
    final pathTop = Path()
      ..moveTo(topOrigin.dx - strokeWidth / 2, topOrigin.dy)
      ..lineTo(cornerOuter.dx, cornerOuter.dy)
      ..lineTo(end.dx, end.dy + strokeWidth / 2)
      ..relativeLineTo(0, -strokeWidth)
      ..lineTo(topOrigin.dx + strokeWidth / 2, end.dy - strokeWidth / 2)
      ..lineTo(topOrigin.dx + strokeWidth / 2, 0)
      ..close();

    if (!drawBottom) {
      canvas.drawPath(pathTop, paint);
      return;
    }

    final pathBottom = Path()
      ..moveTo(cornerOuter.dx, cornerOuter.dy)
      ..lineTo(cornerOuter.dx, bottom.dy)
      ..relativeLineTo(strokeWidth, 0)
      ..lineTo(cornerOuter.dx + strokeWidth, cornerOuter.dy)
      ..close();

    final combinedPath = Path.combine(PathOperation.union, pathTop, pathBottom);
    canvas.drawPath(combinedPath, paint);
  }

  void _drawScopingLines({
    required Canvas canvas,
    required Offset origin,
    required double strokeWidth,
    required double bottom,
    required ITreeNode node,
    required Paint paint,
    bool drawLastChild = false,
  }) {
    if (drawLastChild || lastChildCacheManager.isLastChild(node) == false)
      canvas.drawRect(
          Rect.fromLTRB(
            origin.dx - 0.5,
            origin.dy,
            origin.dx + strokeWidth - 0.5,
            bottom,
          ),
          paint);

    if (node.parent != null) {
      _drawScopingLines(
        canvas: canvas,
        origin: Offset(origin.dx - indentation.width, origin.dy),
        strokeWidth: strokeWidth,
        bottom: bottom,
        node: node.parent! as ITreeNode,
        paint: paint,
        drawLastChild: drawLastChild,
      );
    }
  }
}
