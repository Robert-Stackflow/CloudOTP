import 'package:flutter/material.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';

class ContainerItem extends StatelessWidget {
  final double radius;
  final EdgeInsetsGeometry? padding;
  final bool roundTop;
  final bool roundBottom;
  final Widget child;
  final Color? backgroundColor;
  final Border? border;

  const ContainerItem({
    super.key,
    this.radius = 8,
    this.padding,
    this.roundTop = false,
    this.roundBottom = false,
    required this.child,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? ChewieTheme.canvasColor,
        borderRadius: BorderRadius.vertical(
          top: roundTop ? Radius.circular(radius) : const Radius.circular(0),
          bottom:
              roundBottom ? Radius.circular(radius) : const Radius.circular(0),
        ),
        border: border,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: ChewieTheme.dividerColor,
              width: 0.05,
              style: roundBottom ? BorderStyle.none : BorderStyle.solid,
            ),
            top: BorderSide(
              color: ChewieTheme.dividerColor,
              width: 0.05,
              style: roundTop ? BorderStyle.none : BorderStyle.solid,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}
