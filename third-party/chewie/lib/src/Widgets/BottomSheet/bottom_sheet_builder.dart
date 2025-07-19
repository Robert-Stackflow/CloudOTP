import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import 'package:awesome_chewie/awesome_chewie.dart';

class BottomSheetBuilder {
  static Future showContextMenu(BuildContext context, FlutterContextMenu menu) {
    if (ResponsiveUtil.isDesktop()) {
      return menu.showAtMousePosition(context, chewieProvider.mousePosition);
    } else {
      return showBottomSheet(
          responsive: true,
          context,
          (context) => ContextMenuBottomSheet(menu: menu));
    }
  }

  static void showGenericContextMenu(BuildContext context, Widget menu) {
    context.genericContextMenuOverlay.show(menu);
  }

  static Future showBottomSheet(
    BuildContext context,
    WidgetBuilder builder, {
    bool enableDrag = true,
    bool responsive = false,
    Color? backgroundColor,
    double? preferMinWidth,
  }) {
    bool isLandScape = ResponsiveUtil.isWideDevice();
    preferMinWidth ??= responsive && isLandScape ? 450 : null;
    if (responsive && isLandScape) {
      return showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: ChewieTheme.barrierColor,
        barrierLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return DialogAnimation(
            animation: animation,
            child: FloatingModal(
              preferMinWidth: preferMinWidth,
              child: builder(context),
            ),
          );
        },
      );
    } else {
      return showCustomModalBottomSheet(
        context: context,
        elevation: 0,
        enableDrag: enableDrag,
        barrierColor: ChewieTheme.barrierColor,
        backgroundColor: backgroundColor ?? ChewieTheme.canvasColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: builder,
        containerWidget: (_, animation, child) => FloatingModal(
          preferMinWidth: preferMinWidth,
          child: child,
        ),
      );
    }
  }
}
