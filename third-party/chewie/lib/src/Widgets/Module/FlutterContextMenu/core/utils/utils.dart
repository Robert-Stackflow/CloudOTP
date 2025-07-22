import 'dart:math';

import 'package:flutter/widgets.dart';

import '../models/context_menu.dart';
import '../utils/extensions.dart';

/// Calculates the position of the context menu based on the position of the
/// menu and the position of the parent menu. To prevent the menu from
/// extending beyond the screen boundaries.
({Offset pos, AlignmentGeometry alignment}) calculateContextMenuBoundaries(
  BuildContext context,
  FlutterContextMenu menu,
  Rect? parentRect,
  AlignmentGeometry spawnAlignment,
  bool isSubmenu,
) {
  final screenSize = MediaQuery.of(context).size;
  final safeScreenRect = (Offset.zero & screenSize).deflate(8.0);
  final menuRect = context.getWidgetBounds()!;
  AlignmentGeometry nextSpawnAlignment = spawnAlignment;

  // final parentRect = menu.parentItemRect;

  double x = menuRect.left;
  double y = menuRect.top;

  bool isWidthExceed() => x + menuRect.width > screenSize.width || x < 0;

  bool isHeightExceed() => y + menuRect.height > screenSize.height || y < 0;

  Rect currentRect() => Offset(x, y) & menuRect.size;

  if (isWidthExceed()) {
    if (isSubmenu && parentRect != null) {
      final toRightSide = parentRect.right + menu.padding.left;
      final toLeftSide = parentRect.left - menuRect.width - menu.padding.right;
      final maxRight = safeScreenRect.right - menuRect.width;
      final maxLeft = safeScreenRect.left;

      if (spawnAlignment == AlignmentDirectional.topEnd) {
        if (currentRect().right > safeScreenRect.right) {
          x = min(toRightSide, safeScreenRect.right);
          nextSpawnAlignment = AlignmentDirectional.topStart;
          if (isWidthExceed()) {
            x = toLeftSide;
            nextSpawnAlignment = AlignmentDirectional.topEnd;
            if (isWidthExceed()) {
              x = min(toRightSide, maxRight);
              nextSpawnAlignment = AlignmentDirectional.topStart;
            }
          }
        } else {
          x = min(toRightSide, safeScreenRect.right);
          nextSpawnAlignment = AlignmentDirectional.topEnd;
          if (isWidthExceed()) {
            x = toLeftSide;
            nextSpawnAlignment = AlignmentDirectional.topStart;
            if (isWidthExceed()) {
              x = min(toRightSide, maxRight);
              nextSpawnAlignment = AlignmentDirectional.topEnd;
            }
          }
        }
      } else {
        if (currentRect().left < safeScreenRect.left) {
          x = toRightSide;
          nextSpawnAlignment = AlignmentDirectional.topEnd;
          if (isWidthExceed()) {
            x = toLeftSide;
            nextSpawnAlignment = AlignmentDirectional.topStart;
            if (isWidthExceed()) {
              x = min(toRightSide, maxRight);
              nextSpawnAlignment = AlignmentDirectional.topEnd;
            }
          }
        } else {
          x = toLeftSide;
          nextSpawnAlignment = AlignmentDirectional.topEnd;
          if (isWidthExceed()) {
            x = toRightSide;
            nextSpawnAlignment = AlignmentDirectional.topStart;
            if (isWidthExceed()) {
              x = max(toLeftSide, maxLeft);
              nextSpawnAlignment = AlignmentDirectional.topEnd;
            }
          }
        }
      }
    } else if (!isSubmenu) {
      x = max(safeScreenRect.left, menuRect.left - menuRect.width);
    }
  }

  if (isHeightExceed()) {
    if (isSubmenu && parentRect != null) {
      y = max(safeScreenRect.top,
          safeScreenRect.bottom - menuRect.height - menu.padding.top);
    } else if (!isSubmenu) {
      y = max(safeScreenRect.top, menuRect.top - menuRect.height);
    }
  }

  return (pos: Offset(x, y), alignment: nextSpawnAlignment);
}

bool hasSameFocusNodeId(String line1, String line2) {
  RegExp focusNodeRegex = RegExp(r"FocusNode#(\d+)");

  RegExpMatch? match1 = focusNodeRegex.firstMatch(line1);
  RegExpMatch? match2 = focusNodeRegex.firstMatch(line2);

  if (match1 != null && match2 != null) {
    String? focusNodeId1 = match1.group(1);
    String? focusNodeId2 = match2.group(1);

    return focusNodeId1 == focusNodeId2;
  } else {
    return false;
  }
}

Rect getScreenRect(BuildContext context) {
  final size = MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first)
      .size;
  return Offset.zero & size;
}
