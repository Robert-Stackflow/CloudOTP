import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class BottomSheetWrapperWidget extends StatelessWidget {
  final Widget child;
  final double? preferMinWidth;
  final bool useVerticalMargin;

  const BottomSheetWrapperWidget({
    super.key,
    required this.child,
    this.preferMinWidth,
    this.useVerticalMargin = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isLandScape = ResponsiveUtil.isWideDevice();
    double width = MediaQuery.sizeOf(context).width - 60;
    double height = MediaQuery.sizeOf(context).height - 60;
    double preferWidth = min(width, preferMinWidth ?? 540);
    double preferHeight = min(width, 500);
    double preferHorizontalMargin = isLandScape
        ? width > preferWidth
            ? (width - preferWidth) / 2
            : 0
        : 0;
    double preferVerticalMargin =
        height > preferHeight ? (height - preferHeight) / 2 : 0;
    return BackdropFilter(
      filter: ResponsiveUtil.isDesktop()
          ? ImageFilter.blur(sigmaX: 2, sigmaY: 2)
          : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
      child: Container(
        margin: EdgeInsets.only(
          left: preferHorizontalMargin,
          right: preferHorizontalMargin,
          top: useVerticalMargin
              ? preferVerticalMargin
              : ResponsiveUtil.isLandscapeLayout()
                  ? 0
                  : 100,
          bottom: useVerticalMargin ? preferVerticalMargin : 0,
        ),
        child: child,
      ),
    );
  }
}
