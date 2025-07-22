import 'package:flutter/material.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class RoundIconButton extends StatelessWidget {
  final dynamic icon;
  final Function()? onPressed;
  final Function()? onLongPress;
  final Color? background;
  final double radius;
  final EdgeInsets? padding;
  final bool disabled;
  final String? tooltip;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.onLongPress,
    this.tooltip,
    this.background,
    this.radius = 8,
    this.padding,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isClickable = !disabled && onPressed != null;
    var backgroundColor = background ?? Colors.transparent;
    backgroundColor =
        disabled ? backgroundColor.withAlpha(127) : backgroundColor;
    final buttonContent = PressableAnimation(
      scaleFactor: isClickable ? 0.02 : 0,
      onTap: isClickable ? onPressed : null,
      child: InkAnimation(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.hardEdge,
        onTap: isClickable ? onPressed : null,
        onLongPress: onLongPress,
        child: Container(
          padding: padding ?? const EdgeInsets.all(10),
          child: icon ?? emptyWidget,
        ),
      ),
    );

    return ToolTipWrapper(
      message: tooltip,
      position: TooltipPosition.top,
      child: buttonContent,
    );
  }
}
