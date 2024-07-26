import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class MeasuredSizeWidget extends SingleChildRenderObjectWidget {
  const MeasuredSizeWidget({
    required this.onChange,
    required super.child,
    super.key,
  });

  final void Function(Size size) onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _MeasureSizeRenderObject(onChange);
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  _MeasureSizeRenderObject(this.onChange);

  void Function(Size size) onChange;

  Size? _prevSize;

  @override
  void performLayout() {
    super.performLayout();
    Size newSize = child?.size ?? Size.zero;
    if (_prevSize == newSize) return;
    _prevSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(newSize));
  }
}
