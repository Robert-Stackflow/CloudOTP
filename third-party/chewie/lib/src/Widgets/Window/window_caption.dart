import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

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
  final double titlebarHeight;
  final bool hasMoveHandle;

  const WindowTitleBar({
    super.key,
    this.child,
    this.margin,
    this.titlebarHeight = 56,
    required this.hasMoveHandle,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Container();
    }
    return SizedBox(
      height: titlebarHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hasMoveHandle) const WindowMoveHandle(),
          Container(
            margin: margin,
            child: child ?? Container(),
          ),
        ],
      ),
    );
  }
}
