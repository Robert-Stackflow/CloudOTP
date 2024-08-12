import 'package:flutter/widgets.dart';

class OffsetAnimation {
  OffsetAnimation({
    required this.controller,
    this.begin = Offset.zero,
    this.end = Offset.zero,
  });

  final AnimationController controller;
  Offset begin;
  Offset end;
  Curve curve = Curves.linear;

  Offset get value =>
      Offset.lerp(begin, end, curve.transform(controller.value))!;

  void shift(Offset delta) {
    begin += delta;
    end += delta;
  }

  void scale(double scaleFactor) {
    begin *= scaleFactor;
    end *= scaleFactor;
  }

  void dispose() => controller.dispose();
}
