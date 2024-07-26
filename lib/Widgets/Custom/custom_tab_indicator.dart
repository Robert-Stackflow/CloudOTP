import 'package:flutter/material.dart';

import '../../Resources/colors.dart';

class CustomTabIndicator extends Decoration {
  final TabController? tabController;
  final double indicatorBottom;
  final double indicatorWidth;
  final double borderWidth;
  final Color borderColor;

  const CustomTabIndicator({
    this.borderWidth = 4,
    this.borderColor = MyColors.deepGreenPrimaryColor,
    this.tabController,
    this.indicatorBottom = 10,
    this.indicatorWidth = 10,
  });

  getBorderSide() {
    return BorderSide(
      color: borderColor,
      width: borderWidth,
    );
  }

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _UnderlinePainter(
      this,
      onChanged,
      tabController?.animation,
      indicatorWidth,
    );
  }

  Rect _indicatorRectFor(Rect indicator, TextDirection textDirection) {
    double w = indicatorWidth;
    double centerWidth = (indicator.left + indicator.right) / 2;
    return Rect.fromLTWH(
      tabController?.animation == null ? centerWidth - w / 2 : centerWidth - 1,
      indicator.bottom - borderWidth - indicatorBottom,
      w,
      borderWidth,
    );
  }

  @override
  Path getClipPath(Rect rect, TextDirection textDirection) {
    return Path()..addRect(_indicatorRectFor(rect, textDirection));
  }
}

class _UnderlinePainter extends BoxPainter {
  Animation<double>? animation;
  double indicatorWidth;

  _UnderlinePainter(this.decoration, VoidCallback? onChanged, this.animation,
      this.indicatorWidth)
      : super(onChanged);

  final CustomTabIndicator decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration.size != null);
    final Rect rect = offset & configuration.size!;
    final TextDirection textDirection = configuration.textDirection!;
    final Rect indicator = decoration._indicatorRectFor(rect, textDirection)
      ..deflate(decoration.borderWidth / 2.0);
    final Paint paint = decoration.getBorderSide().toPaint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;
    if (animation != null) {
      num x = animation!.value;
      num d = x - x.truncate();
      num? y;
      if (d < 0.5) {
        y = 2 * d;
      } else if (d > 0.5) {
        y = 1 - 2 * (d - 0.5);
      } else {
        y = 1;
      }
      canvas.drawRRect(
          RRect.fromRectXY(
              Rect.fromCenter(
                  center: indicator.centerLeft,
                  width: indicatorWidth * 6 * y + indicatorWidth,
                  height: indicatorWidth),
              2,
              2),
          paint);
    } else {
      canvas.drawLine(indicator.bottomLeft, indicator.bottomRight, paint);
    }
  }
}
