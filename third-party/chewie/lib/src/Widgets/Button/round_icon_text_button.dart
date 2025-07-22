import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:awesome_chewie/awesome_chewie.dart';

class RoundIconTextButton extends StatelessWidget {
  final String? text;
  final String? tooltip;
  final Function()? onPressed;
  final Color? background;
  final Widget? icon;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final double fontSizeDelta;
  final TextStyle? textStyle;
  final double? width;
  final double? height;
  final double? minHeight;
  final double spacing;
  final Border? border;
  final bool disabled;

  const RoundIconTextButton({
    super.key,
    this.text,
    this.tooltip,
    this.onPressed,
    this.background,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.radius = 8,
    this.spacing = 4,
    this.color,
    this.fontSizeDelta = 0,
    this.textStyle,
    this.width,
    this.height = 48,
    this.minHeight = 32,
    this.border,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isClickable = !disabled && onPressed != null;
    Color backgroundColor = background ?? ChewieTheme.cardColor;
    backgroundColor =
        disabled ? backgroundColor.withAlpha(127) : backgroundColor;
    Color textColor = color ??
        (background != null ? Colors.white : ChewieTheme.titleSmall.color!);
    textColor = disabled ? textColor.withAlpha(127) : textColor;
    return ToolTipWrapper(
      message: tooltip,
      child: Container(
        height: height,
        constraints: BoxConstraints(
          minHeight: math.min(
            minHeight ?? double.infinity,
            height ?? double.infinity,
          ),
        ),
        child: PressableAnimation(
          scaleFactor: isClickable ? 0.02 : 0,
          onTap: isClickable ? onPressed : null,
          child: Material(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(radius),
            child: InkWell(
              onTap: isClickable ? onPressed : null,
              borderRadius: BorderRadius.circular(radius),
              child: ClickableWrapper(
                clickable: isClickable,
                child: Container(
                  width: width,
                  padding: padding,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(radius),
                    border: border,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) icon!,
                      if (icon != null && text != null)
                        SizedBox(width: spacing),
                      Flexible(
                        child: Text(
                          text ?? "",
                          style: textStyle ??
                              ChewieTheme.titleSmall.apply(
                                color: textColor,
                                fontWeightDelta: 2,
                                fontSizeDelta: fontSizeDelta,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
