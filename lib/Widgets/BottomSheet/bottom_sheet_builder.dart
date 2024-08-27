import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../Custom/floating_modal.dart';

class BottomSheetBuilder {
  static void showBottomSheet(
    BuildContext context,
    WidgetBuilder builder, {
    bool enableDrag = true,
    bool responsive = false,
    bool useWideLandscape = true,
    Color? backgroundColor,
    double? preferMinWidth,
    ShapeBorder shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  }) {
    bool isLandScape = useWideLandscape
        ? ResponsiveUtil.isWideLandscape()
        : ResponsiveUtil.isWideLandscape();
    preferMinWidth ??= responsive && isLandScape ? 450 : null;
    if (responsive && isLandScape) {
      showDialog(
        context: context,
        builder: (context) {
          return FloatingModal(
            preferMinWidth: preferMinWidth,
            useWideLandscape: useWideLandscape,
            child: builder(context),
          );
        },
      );
    } else {
      showCustomModalBottomSheet(
        context: context,
        elevation: 0,
        enableDrag: enableDrag,
        backgroundColor: backgroundColor ?? Theme.of(context).canvasColor,
        shape: shape,
        builder: builder,
        containerWidget: (_, animation, child) => FloatingModal(
          preferMinWidth: preferMinWidth,
          useWideLandscape: useWideLandscape,
          child: child,
        ),
      );
    }
  }

  static void showListBottomSheet(
    BuildContext context,
    WidgetBuilder builder, {
    Color? backgroundColor,
    ShapeBorder shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
    ),
  }) {
    showCustomModalBottomSheet(
      context: context,
      elevation: 0,
      backgroundColor: backgroundColor ?? Theme.of(context).canvasColor,
      shape: shape,
      builder: builder,
      containerWidget: (_, animation, child) => child,
    );
  }
}
