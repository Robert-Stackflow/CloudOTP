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
        onSecondaryTapDown: (details){
          windowManager.popUpWindowMenu();
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
