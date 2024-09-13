/*
 * Copyright (c) 2024 Robert-Stackflow.
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

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import '../../Utils/responsive_util.dart';

class _MoveWindow extends StatelessWidget {
  const _MoveWindow({this.child, this.onDoubleTap});

  final Widget? child;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) {
          windowManager.startDragging();
        },
        onDoubleTap: onDoubleTap ?? () => ResponsiveUtil.maximizeOrRestore(),
        child: child ?? Container());
  }
}

class WindowMoveHandle extends StatelessWidget {
  final Widget? child;
  final VoidCallback? onDoubleTap;

  const WindowMoveHandle({super.key, this.child, this.onDoubleTap});

  @override
  Widget build(BuildContext context) {
    if (child == null) return _MoveWindow(onDoubleTap: onDoubleTap);
    return _MoveWindow(
      onDoubleTap: onDoubleTap,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: child!)]),
    );
  }
}

class WindowTitleBar extends StatelessWidget {
  final Widget? child;

  final EdgeInsets? margin;
  final double? titleBarHeightDelta;
  final bool useMoveHandle;

  const WindowTitleBar({
    super.key,
    this.child,
    this.margin,
    this.titleBarHeightDelta,
    required this.useMoveHandle,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Container();
    }
    const titlebarHeight = 30;
    return SizedBox(
      height: titlebarHeight + (titleBarHeightDelta ?? 0),
      child: Stack(
        children: [
          if (useMoveHandle) const WindowMoveHandle(),
          Container(
            margin: margin,
            child: child ?? Container(),
          ),
        ],
      ),
    );
  }
}
