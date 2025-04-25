import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  Rect? getWidgetBounds() {
    final widgetRenderBox = findRenderObject() as RenderBox?;
    if (widgetRenderBox == null) return null;
    final widgetPosition = widgetRenderBox.localToGlobal(Offset.zero);
    final widgetSize = widgetRenderBox.size;
    return widgetPosition & widgetSize;
  }

  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
}
