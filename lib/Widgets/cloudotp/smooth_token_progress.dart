import 'package:flutter/material.dart';

class SmoothTokenProgress extends StatelessWidget {
  const SmoothTokenProgress({
    super.key,
    required this.value,
    required this.period,
    required this.builder,
  });

  final double value;
  final int period;
  final Widget Function(BuildContext context, double value) builder;

  static Color color(double progress, Color primary) {
    final blend = ((progress - 0.15) / 0.20).clamp(0.0, 1.0);
    return Color.lerp(Colors.red, primary, blend)!;
  }

  @override
  Widget build(BuildContext context) {
    final cycle = period <= 0
        ? 0
        : DateTime.now().millisecondsSinceEpoch ~/ (period * 1000);
    return TweenAnimationBuilder<double>(
      key: ValueKey(cycle),
      tween: Tween<double>(begin: value, end: value),
      duration: Theme.of(context).platform == TargetPlatform.android
          ? const Duration(milliseconds: 205)
          : const Duration(milliseconds: 105),
      curve: Curves.linear,
      builder: (context, animatedValue, child) =>
          builder(context, animatedValue),
    );
  }
}
