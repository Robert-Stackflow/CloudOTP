import 'dart:math';

import 'package:flutter/material.dart';

class FloatingModal extends StatelessWidget {
  final Widget child;
  final double? preferMinWidth;
  final double? horizontalMargin;

  const FloatingModal({
    super.key,
    required this.child,
    this.preferMinWidth,
    this.horizontalMargin,
  });

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width - 60;
    double preferWidth = min(width, preferMinWidth ?? 540);
    double preferMargin = width > preferWidth ? (width - preferWidth) / 2 : 0;
    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: horizontalMargin ?? preferMargin),
        child: child,
      ),
    );
  }
}
