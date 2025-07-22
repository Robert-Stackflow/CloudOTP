import 'package:flutter/material.dart';

extension BoxConstraintsExtensions on BoxConstraints {
  double maxForDirection(Axis direction) => switch (direction) {
        Axis.horizontal => maxWidth,
        Axis.vertical => maxHeight,
      };
}
