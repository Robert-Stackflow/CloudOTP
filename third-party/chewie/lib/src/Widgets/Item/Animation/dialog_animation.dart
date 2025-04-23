import 'package:flutter/material.dart';

class DialogAnimation extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const DialogAnimation({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
    );

    return ScaleTransition(
      scale: curvedAnimation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}
