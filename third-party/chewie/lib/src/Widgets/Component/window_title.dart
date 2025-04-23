import 'package:awesome_chewie/src/Widgets/Component/window_caption.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'package:awesome_chewie/src/Resources/colors.dart';
import 'package:awesome_chewie/src/Resources/dimens.dart';
import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Utils/System/hive_util.dart';
import 'package:awesome_chewie/src/Widgets/Item/Button/window_button.dart';

class WindowTitleWrapper extends StatelessWidget {
  final Color? backgroundColor;
  final List<Widget> leftWidgets;
  final List<Widget> rightButtons;
  final bool isStayOnTop;
  final bool isMaximized;
  final Function() onStayOnTopTap;
  final bool forceClose;
  final double height;

  const WindowTitleWrapper({
    super.key,
    this.backgroundColor,
    this.leftWidgets = const [],
    this.rightButtons = const [],
    required this.isStayOnTop,
    required this.isMaximized,
    required this.onStayOnTopTap,
    this.forceClose = false,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: backgroundColor ?? ChewieTheme.appBarBackgroundColor,
      child: WindowTitleBar(
        hasMoveHandle: ResponsiveUtil.isDesktop(),
        titlebarHeight: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...leftWidgets,
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 8),
                ...rightButtons,
                StayOnTopWindowButton(
                  context: context,
                  rotateTurns: isStayOnTop ? 0 : 0.25,
                  colors: isStayOnTop
                      ? ChewieColors.getStayOnTopButtonColors(context)
                      : ChewieColors.getNormalButtonColors(context),
                  borderRadius: ChewieDimens.borderRadius8,
                  onPressed: onStayOnTopTap,
                ),
                const SizedBox(width: 3),
                MinimizeWindowButton(
                  colors: ChewieColors.getNormalButtonColors(context),
                  borderRadius: ChewieDimens.borderRadius8,
                ),
                const SizedBox(width: 3),
                isMaximized
                    ? RestoreWindowButton(
                        colors: ChewieColors.getNormalButtonColors(context),
                        borderRadius: ChewieDimens.borderRadius8,
                        onPressed: ResponsiveUtil.maximizeOrRestore,
                      )
                    : MaximizeWindowButton(
                        colors: ChewieColors.getNormalButtonColors(context),
                        borderRadius: ChewieDimens.borderRadius8,
                        onPressed: ResponsiveUtil.maximizeOrRestore,
                      ),
                const SizedBox(width: 3),
                CloseWindowButton(
                  colors: ChewieColors.getCloseButtonColors(context),
                  borderRadius: ChewieDimens.borderRadius8,
                  onPressed: () {
                    if (forceClose) {
                      windowManager.close();
                    } else {
                      if (ChewieHiveUtil.getBool(ChewieHiveUtil.showTrayKey) &&
                          ChewieHiveUtil.getBool(
                              ChewieHiveUtil.enableCloseToTrayKey)) {
                        windowManager.hide();
                      } else {
                        windowManager.close();
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
