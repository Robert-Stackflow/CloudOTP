import 'package:flutter/material.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';

class TranslucentTag extends StatelessWidget {
  final String text;
  final bool isCircle;
  final int? width;
  final int? height;
  final double opacity;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? fontSizeDelta;
  final dynamic icon;

  const TranslucentTag({
    super.key,
    required this.text,
    this.isCircle = false,
    this.width,
    this.height,
    this.opacity = 0.4,
    this.borderRadius,
    this.padding,
    this.fontSizeDelta,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: isCircle
          ? padding ?? const EdgeInsets.all(5)
          : padding ?? const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        color: Colors.black.withOpacity(opacity),
        borderRadius: isCircle
            ? null
            : BorderRadius.all(Radius.circular(borderRadius ?? 50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) icon,
          if (icon != null && text.isNotEmpty) const SizedBox(width: 3),
          Text(
            text,
            style: ChewieTheme.bodySmall.apply(
              color: Colors.white,
              fontSizeDelta: fontSizeDelta ?? -1,
            ),
          ),
        ],
      ),
    );
  }
}
