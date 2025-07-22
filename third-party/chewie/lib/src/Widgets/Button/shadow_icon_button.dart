import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class ShadowIconButton extends StatelessWidget {
  final dynamic icon;
  final Function()? onTap;
  final Function()? onLongPress;
  final double radius;
  final EdgeInsets? padding;

  const ShadowIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.onLongPress,
    this.radius = 8,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return PressableAnimation(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: ChewieTheme.dividerColor, width: 0.8),
          borderRadius: BorderRadius.circular(radius + 1),
          boxShadow: ChewieTheme.defaultBoxShadow,
        ),
        child: InkAnimation(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: padding ?? const EdgeInsets.all(10),
            child: icon ?? emptyWidget,
          ),
        ),
      ),
    );
  }
}
