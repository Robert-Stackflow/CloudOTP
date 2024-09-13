/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';

class TabIndicator extends Decoration {
  final TabController? tabController;
  final double indicatorBottom;
  final double indicatorWidth;

  const TabIndicator({
    this.borderSide = const BorderSide(width: 6),
    this.tabController,
    this.indicatorBottom = 16,
    this.indicatorWidth = 34,
  });

  final BorderSide borderSide;

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
      indicator.bottom - borderSide.width - indicatorBottom,
      w,
      borderSide.width,
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

  final TabIndicator decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration.size != null);
    final Rect rect = offset & configuration.size!;
    final TextDirection textDirection = configuration.textDirection!;
    final Rect indicator = decoration._indicatorRectFor(rect, textDirection)
      ..deflate(decoration.borderSide.width / 2.0);
    final Paint paint = decoration.borderSide.toPaint()
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
