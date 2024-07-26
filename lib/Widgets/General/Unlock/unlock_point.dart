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
