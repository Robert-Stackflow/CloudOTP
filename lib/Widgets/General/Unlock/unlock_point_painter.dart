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

import 'gesture_unlock_view.dart';
import 'unlock_point.dart';

class UnlockPointPainter extends CustomPainter {
  final UnlockType type;
  final List<UnlockPoint> points;
  final double radius;
  final double solidRadius;
  final double lineWidth;
  final Color defaultColor;
  final Color selectedColor;
  final Color failedColor;
  final Color disableColor;

  UnlockPointPainter(
      {required this.type,
      required this.points,
      required this.radius,
      required this.solidRadius,
      required this.lineWidth,
      required this.defaultColor,
      required this.selectedColor,
      required this.failedColor,
      required this.disableColor});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();

    if (type == UnlockType.solid) {
      ///画圆
      _paintPoint(canvas, paint);
    } else {
      _paintPointWithHollow(canvas, paint);
    }
  }

  void _paintPointWithHollow(Canvas canvas, Paint paint) {
    paint.strokeWidth = lineWidth;
    for (UnlockPoint point in points) {
      switch (point.status) {
        case UnlockStatus.normal:
          {
            paint.color = defaultColor;
            paint.style = PaintingStyle.stroke;
            canvas.drawCircle(point.toOffset(), radius, paint);
            break;
          }
        case UnlockStatus.success:
          {
            paint.style = PaintingStyle.fill;
            paint.color = selectedColor;
            canvas.drawCircle(point.toOffset(), solidRadius, paint);
            paint.style = PaintingStyle.stroke;
            canvas.drawCircle(point.toOffset(), radius, paint);
            break;
          }
        case UnlockStatus.failed:
          {
            paint.style = PaintingStyle.fill;
            paint.color = failedColor;
            canvas.drawCircle(point.toOffset(), solidRadius, paint);
            paint.style = PaintingStyle.stroke;
            canvas.drawCircle(point.toOffset(), radius, paint);
            break;
          }
        case UnlockStatus.disable:
          {
            paint.color = disableColor;
            canvas.drawCircle(point.toOffset(), solidRadius, paint);
            break;
          }
      }
    }
  }

  void _paintPoint(Canvas canvas, Paint paint) {
    for (UnlockPoint point in points) {
      switch (point.status) {
        case UnlockStatus.normal:
          {
            paint.color = defaultColor;
            paint.style = PaintingStyle.fill;
            canvas.drawCircle(point.toOffset(), solidRadius, paint);
            break;
          }
        case UnlockStatus.success:
          {
            paint.color = selectedColor;
            canvas.drawCircle(point.toOffset(), solidRadius, paint);
            paint.color = selectedColor.withAlpha(14);
            canvas.drawCircle(point.toOffset(), radius, paint);
            break;
          }
        case UnlockStatus.failed:
          {
            paint.color = failedColor;
            canvas.drawCircle(point.toOffset(), solidRadius, paint);
            paint.color = failedColor.withAlpha(14);
            canvas.drawCircle(point.toOffset(), radius, paint);
            break;
          }
        case UnlockStatus.disable:
          {
            paint.color = disableColor;
            canvas.drawCircle(point.toOffset(), solidRadius, paint);
            break;
          }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
