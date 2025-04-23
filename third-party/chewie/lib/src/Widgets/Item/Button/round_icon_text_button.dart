import 'package:flutter/material.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Widgets/Item/Animation/pressable_animation.dart';
import 'package:awesome_chewie/src/Widgets/Item/General/clickable_wrapper.dart';
import 'package:awesome_chewie/src/Widgets/Item/General/tooltip_wrapper.dart';

class RoundIconTextButton extends StatelessWidget {
  final String? text;
  final String? tooltip;
  final Function()? onPressed;
  final Color? background;
  final Widget? icon;
  final EdgeInsets? padding;
  final double radius;
  final Color? color;
  final double fontSizeDelta;
  final TextStyle? textStyle;
  final double? width;
  final double height;
  final Border? border;
  final bool disabled;

  const RoundIconTextButton({
    super.key,
    this.text,
    this.tooltip,
    this.onPressed,
    this.background,
    this.icon,
    this.padding,
    this.radius = 8,
    this.color,
    this.fontSizeDelta = 0,
    this.textStyle,
    this.width,
    this.height = 36,
    this.border,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isClickable = !disabled && onPressed != null;
    var backgroundColor = background ?? ChewieTheme.cardColor;
    backgroundColor =
        disabled ? backgroundColor.withAlpha(127) : backgroundColor;
    return ToolTipWrapper(
      message: tooltip,
      child: SizedBox(
        height: height,
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
                  padding:
                      padding ?? const EdgeInsets.symmetric(horizontal: 24),
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
                      Text(
                        text ?? "",
                        style: textStyle ??
                            ChewieTheme.titleSmall.apply(
                              color: (color ??
                                  (background != null
                                      ? Colors.white
                                      : ChewieTheme.titleSmall.color)),
                              fontWeightDelta: 2,
                              fontSizeDelta: fontSizeDelta,
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
