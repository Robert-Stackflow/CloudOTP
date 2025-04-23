import 'package:flutter/material.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';

class MyDivider extends StatelessWidget {
  final double vertical;
  final double horizontal;
  final double? width;
  final EdgeInsets? margin;

  const MyDivider({
    super.key,
    this.vertical = 8,
    this.horizontal = 16,
    this.width,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ??
          EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal),
      height: width ?? 0.5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: ChewieTheme.dividerColor,
      ),
    );
  }
}
