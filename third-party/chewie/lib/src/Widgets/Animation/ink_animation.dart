import 'package:flutter/material.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class InkAnimation extends StatelessWidget {
  final Widget child;
  final Function()? onTap;
  final Function()? onLongPress;
  final Function()? onLongPressUp;
  final Function()? onDoubleTap;
  final Function()? onSecondaryTap;
  final BorderRadius? borderRadius;
  final Clip clipBehavior;
  final ShapeBorder? shape;
  final Color? color;
  final bool ink;

  const InkAnimation({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onLongPressUp,
    this.onDoubleTap,
    this.onSecondaryTap,
    this.borderRadius,
    this.clipBehavior = Clip.none,
    this.shape,
    this.color,
    this.ink = true,
  });

  @override
  Widget build(BuildContext context) {
    BorderRadius effectiveBorderRadius =
        borderRadius ?? ChewieDimens.borderRadius8;

    if (ink) {
      return Material(
        color: color,
        clipBehavior: clipBehavior,
        shape: shape,
        borderRadius: shape != null ? null : effectiveBorderRadius,
        child: MyInkWell(
          onTap: onTap,
          onSecondaryTap: onSecondaryTap,
          onLongPress: onLongPress,
          onLongPressUp: onLongPressUp,
          onDoubleTap: onDoubleTap,
          borderRadius: effectiveBorderRadius,
          child: child,
        ),
      );
    } else {
      return GestureDetector(
        onTap: onTap,
        onLongPressUp: onLongPressUp,
        onLongPress: onLongPress,
        onSecondaryTap: onSecondaryTap,
        onDoubleTap: onDoubleTap,
        child: child,
      );
    }
  }
}
