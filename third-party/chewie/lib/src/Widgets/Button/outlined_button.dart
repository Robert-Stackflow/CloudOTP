import 'package:flutter/material.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class CircleOutlinedButton extends StatelessWidget {
  final Function()? onTap;
  final Color? outline;
  final IconData? iconData;
  final String? tooltip;
  final TooltipPosition tooltipPosition;

  const CircleOutlinedButton({
    super.key,
    required this.onTap,
    this.outline,
    this.iconData,
    this.tooltip,
    this.tooltipPosition = TooltipPosition.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return CustomOutlinedButton(
      padding: const EdgeInsets.symmetric(vertical: 4.8, horizontal: 5.4),
      radius: 50,
      tooltip: tooltip,
      tooltipPosition: tooltipPosition,
      icon: Icon(
        iconData,
        size: 16,
        color: ChewieTheme.iconColor,
      ),
      onPressed: onTap,
    );
  }
}

class CustomOutlinedButton extends StatelessWidget {
  final String? text;
  final Function()? onPressed;
  final Color? outline;
  final Icon? icon;
  final EdgeInsets? padding;
  final double radius;
  final Color? color;
  final double fontSizeDelta;
  final TextStyle? textStyle;
  final double? width;
  final double spacing;
  final String? tooltip;
  final TooltipPosition tooltipPosition;

  const CustomOutlinedButton({
    super.key,
    this.text,
    required this.onPressed,
    this.outline,
    this.icon,
    this.padding,
    this.radius = 50,
    this.color,
    this.fontSizeDelta = 0,
    this.textStyle,
    this.width,
    this.spacing = 0,
    this.tooltip,
    this.tooltipPosition = TooltipPosition.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final buttonContent = PressableAnimation(
      onTap: onPressed,
      child: InkAnimation(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(radius),
        child: ClickableWrapper(
          clickable: onPressed != null,
          child: Container(
            width: width,
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                  color: outline ?? ChewieTheme.borderColor, width: 1),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) icon!,
                if ((text ?? "").isNotEmpty) SizedBox(width: spacing),
                if ((text ?? "").isNotEmpty)
                  Text(
                    text!,
                    style: textStyle ??
                        ChewieTheme.titleSmall.apply(
                          color: color ?? ChewieTheme.primaryColor,
                          fontWeightDelta: 2,
                          fontSizeDelta: fontSizeDelta,
                        ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return ToolTipWrapper(
      message: tooltip,
      position: tooltipPosition,
      child: buttonContent,
    );
  }
}
