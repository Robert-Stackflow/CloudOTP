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

import 'dart:math';

import 'package:flutter/material.dart';

import 'gesture_unlock_view.dart';

class UnlockPoint {
  double x;
  double y;
  bool isSelect = false;
  UnlockStatus status = UnlockStatus.normal;
  int position;

  UnlockPoint({required this.x, required this.y, required this.position});

  Offset toOffset() {
    return Offset(x, y);
  }

  bool contains(Offset offset, radius) {
    return sqrt(pow(offset.dx - x, 2) + pow(offset.dy - y, 2)) < radius;
  }

  @override
  String toString() {
    return "($x,$y)";
  }
}
