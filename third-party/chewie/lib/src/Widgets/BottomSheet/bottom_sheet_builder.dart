import 'dart:async';

import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import 'package:awesome_chewie/src/Providers/chewie_provider.dart';
import 'package:awesome_chewie/src/Widgets/Item/Animation/dialog_animation.dart';
import 'floating_modal.dart';
import 'generic_context_menu_bottom_sheet.dart';

class BottomSheetBuilder {
  static Future showContextMenu(BuildContext context, FlutterContextMenu menu) {
    if (ResponsiveUtil.isLandscape()) {
      return menu.showAtMousePosition(
          chewieProvider.rootContext, chewieProvider.mousePosition);
    } else {
      return showBottomSheet(
          context, (context) => ContextMenuBottomSheet(menu: menu));
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
    bool showBorder = false,
    bool useFloatModal = true,
    bool useWideLandscape = true,
    Color? backgroundColor,
    double? preferMinWidth,
    bool useVerticalMargin = false,
    ShapeBorder shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  }) {
    bool isLandScape = useWideLandscape
        ? ResponsiveUtil.isWideLandscape()
        : ResponsiveUtil.isWideLandscape();
    preferMinWidth ??= responsive && isLandScape ? 450 : null;
    if (responsive && isLandScape) {
      return showGeneralDialog(
        barrierColor: ChewieTheme.barrierColor,
        context: context,
        barrierDismissible: true,
        barrierLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, anim1, anim2) {
          return const SizedBox.shrink();
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return DialogAnimation(
            animation: animation,
            child: FloatingModal(
              preferMinWidth: preferMinWidth,
              useWideLandscape: useWideLandscape,
              useVerticalMargin: useVerticalMargin,
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
        shape: shape,
        builder: builder,
        containerWidget: (_, animation, child) => useFloatModal
            ? FloatingModal(
                preferMinWidth: preferMinWidth,
                useWideLandscape: useWideLandscape,
                child: child,
              )
            : child,
      );
    }
  }
}
