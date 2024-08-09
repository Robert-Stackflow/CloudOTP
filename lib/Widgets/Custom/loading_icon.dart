import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const double _kDefaultIndicatorRadius = 10.0;
const List<int> _kAlphaValues = <int>[
  47,
  47,
  47,
  47,
  72,
  97,
  122,
  147,
];

const double _kTwoPI = pi * 2.0;
const int _partiallyRevealedAlpha = 147;
const Color _kActiveTickColor = CupertinoDynamicColor.withBrightness(
  color: Color(0xFF3C3C44),
  darkColor: Color(0xFFEBEBF5),
);

enum LoadingStatus { none, loading, success, failedAndLoading, failed }

class LoadingIcon extends StatefulWidget {
  const LoadingIcon({
    super.key,
    this.radius = _kDefaultIndicatorRadius,
    this.color,
    this.animating = true,
    this.progress = 1.0,
    this.status = LoadingStatus.loading,
    this.normalIcon,
  })  : assert(radius > 0.0),
        assert(progress >= 0.0),
        assert(progress <= 1.0);

  final double radius;
  final Color? color;
  final double progress;
  final bool animating;
  final LoadingStatus status;
  final Widget? normalIcon;

  @override
  LoadingIconState createState() => LoadingIconState();
}

class LoadingIconState extends State<LoadingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    if (widget.animating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 40,
      child: Center(
        child: Builder(
          builder: (BuildContext context) {
            switch (widget.status) {
              case LoadingStatus.none:
              case LoadingStatus.success:
                return widget.normalIcon ?? const SizedBox.shrink();
              case LoadingStatus.loading:
                return CustomPaint(
                  painter: LoadingIconPainter(
                    position: _controller,
                    activeColor: widget.color ??
                        CupertinoDynamicColor.resolve(
                            CupertinoDynamicColor.withBrightness(
                              color: Theme.of(context).primaryColor,
                              darkColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                            ),
                            context),
                    radius: widget.radius,
                    progress: widget.progress,
                  ),
                );
              case LoadingStatus.success:
                return const Icon(
                  Icons.done_rounded,
                  color: Colors.green,
                );
              case LoadingStatus.failedAndLoading:
                return const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                );
              case LoadingStatus.failed:
                return const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                );
            }
          },
        ),
      ),
    );
  }
}

class LoadingIconPainter extends CustomPainter {
  LoadingIconPainter({
    required this.position,
    required this.activeColor,
    required this.radius,
    required this.progress,
  })  : tickFundamentalRRect = RRect.fromLTRBXY(
          -radius / _kDefaultIndicatorRadius,
          -radius / 3.0,
          radius / _kDefaultIndicatorRadius,
          -radius,
          radius / _kDefaultIndicatorRadius,
          radius / _kDefaultIndicatorRadius,
        ),
        super(repaint: position);

  final Animation<double> position;
  final Color activeColor;
  final double radius;
  final double progress;

  final RRect tickFundamentalRRect;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    final int tickCount = _kAlphaValues.length;

    canvas.save();
    canvas.translate(size.width / 2.0, size.height / 2.0);

    final int activeTick = (tickCount * position.value).floor();

    for (int i = 0; i < tickCount * progress; ++i) {
      final int t = (i - activeTick) % tickCount;
      paint.color = activeColor
          .withAlpha(progress < 1 ? _partiallyRevealedAlpha : _kAlphaValues[t]);
      canvas.drawRRect(tickFundamentalRRect, paint);
      canvas.rotate(_kTwoPI / tickCount);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(LoadingIconPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.progress != progress;
  }
}
