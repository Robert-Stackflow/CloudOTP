import 'dart:math';

import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:flutter/material.dart';

class FloatingModal extends StatelessWidget {
  final Widget child;
  final double? preferMinWidth;
  final bool useVerticalMargin;

  const FloatingModal({
    super.key,
    required this.child,
    this.preferMinWidth,
    this.useVerticalMargin = false,
  });

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width - 60;
    double height = MediaQuery.sizeOf(context).height - 60;
    double preferWidth = min(width, preferMinWidth ?? 540);
    double preferHeight = min(width, 500);
    double preferHorizontalMargin =
        width > preferWidth ? (width - preferWidth) / 2 : 0;
    double preferVerticalMargin =
        height > preferHeight ? (height - preferHeight) / 2 : 0;
    return SafeArea(
      child: Container(
        margin: EdgeInsets.only(
          left: preferHorizontalMargin,
          right: preferHorizontalMargin,
          top: useVerticalMargin
              ? preferVerticalMargin
              : ResponsiveUtil.isLandscape()
                  ? 0
                  : 100,
          bottom: useVerticalMargin ? preferVerticalMargin : 0,
        ),
        child: child,
      ),
    );
  }
}
