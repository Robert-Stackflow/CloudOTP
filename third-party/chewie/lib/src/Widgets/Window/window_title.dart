/*
 * Copyright (c) 2025 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

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
