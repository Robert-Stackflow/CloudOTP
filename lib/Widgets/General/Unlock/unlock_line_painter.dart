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

import './unlock_point.dart';
import 'gesture_unlock_view.dart';

class UnlockLinePainter extends CustomPainter {
  final List<UnlockPoint> pathPoints;
  final Color selectColor;
  final Color failedColor;
  final UnlockStatus status;
  final double lineWidth;
  final UnlockPoint curPoint;

  UnlockLinePainter(
      {required this.pathPoints,
      required this.status,
      required this.selectColor,
      required this.failedColor,
      required this.lineWidth,
      required this.curPoint});

  @override
  void paint(Canvas canvas, Size size) {
    int length = pathPoints.length;

    if (length < 1) return;

    final linePaint = Paint()
      ..isAntiAlias = true
      ..color = status == UnlockStatus.failed ? failedColor : selectColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = lineWidth;

    for (int i = 0; i < length - 1; i++) {
      canvas.drawLine(Offset(pathPoints[i].x, pathPoints[i].y),
          Offset(pathPoints[i + 1].x, pathPoints[i + 1].y), linePaint);
    }

    double endX = curPoint.x;
    double endY = curPoint.y;
    if (endX < 0) {
      endX = 0;
    } else if (endX > size.width) {
      endX = size.width;
    }
    if (endY < 0) {
      endY = 0;
    } else if (endY > size.height) {
      endY = size.height;
    }

    canvas.drawLine(Offset(pathPoints[length - 1].x, pathPoints[length - 1].y),
        Offset(endX, endY), linePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
