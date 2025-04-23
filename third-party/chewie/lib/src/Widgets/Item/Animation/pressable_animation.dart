import 'package:flutter/material.dart';

class PressableAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final double yOffset;
  final Duration duration;

  const PressableAnimation({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.02,
    this.yOffset = 0.0,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<PressableAnimation> createState() => _PressableAnimationState();
}

class _PressableAnimationState extends State<PressableAnimation> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double targetScale = _isPressed ? (1.0 - widget.scaleFactor) : 1.0;
    final double targetYOffset = _isPressed ? widget.yOffset : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: TweenAnimationBuilder<double>(
        duration: widget.duration,
        curve: Curves.easeOut,
        tween: Tween(begin: 0.0, end: targetYOffset),
        builder: (context, y, child) {
          final scale = targetScale;
          return Transform.translate(
            offset: Offset(0, y),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
