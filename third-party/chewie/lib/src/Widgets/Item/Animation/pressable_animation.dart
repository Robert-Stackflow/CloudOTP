import 'package:flutter/material.dart';
import 'dart:math' as math;

class PressableAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final double tiltAngle; // 倾斜角度控制
  final Duration duration;

  const PressableAnimation({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.02,
    this.tiltAngle = 0.1, // 弧度，0.07约为4度
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<PressableAnimation> createState() => _PressableAnimationState();
}

class _PressableAnimationState extends State<PressableAnimation> {
  bool _isPressed = false;
  Offset _pressOffset = Offset.zero; // 记录按下位置的偏移百分比 (-1~1)

  void _handleTapDown(TapDownDetails details, BoxConstraints constraints) {
    final localPos = details.localPosition;
    final dx = (localPos.dx / constraints.maxWidth) * 2 - 1;
    final dy = (localPos.dy / constraints.maxHeight) * 2 - 1;
    setState(() {
      _isPressed = true;
      _pressOffset = Offset(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
    });
  }

  void _handleTapUp(_) => setState(() => _isPressed = false);
  void _handleCancel() => setState(() => _isPressed = false);

  @override
  Widget build(BuildContext context) {
    final double scale = _isPressed ? (1.0 - widget.scaleFactor) : 1.0;
    final double angleX = _isPressed ? widget.tiltAngle * _pressOffset.dy : 0.0;
    final double angleY =
        _isPressed ? -widget.tiltAngle * _pressOffset.dx : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onTap,
          onTapDown: (d) => _handleTapDown(d, constraints),
          onTapUp: _handleTapUp,
          onTapCancel: _handleCancel,
          child: TweenAnimationBuilder(
            duration: widget.duration,
            curve: Curves.easeOut,
            tween: Tween<double>(begin: 0, end: _isPressed ? 1 : 0),
            builder: (context, t, child) {
              final animatedScale = 1.0 - widget.scaleFactor * t;
              final animatedAngleX = angleX * t;
              final animatedAngleY = angleY * t;

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateX(animatedAngleX)
                  ..rotateY(animatedAngleY)
                  ..scale(animatedScale),
                child: child,
              );
            },
            child: widget.child,
          ),
        );
      },
    );
  }
}
