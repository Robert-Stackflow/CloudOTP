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

part of './lottie_cupertino_refresh.dart';

const double _kDefaultIndicatorRadius = 10.0;

class _CustomActivityIndicator extends StatefulWidget {
  const _CustomActivityIndicator({
    super.key,
    this.color,
    this.animating = true,
    this.radius = _kDefaultIndicatorRadius,
    required this.indicator,
  })  : assert(radius > 0.0),
        progress = 1.0;

  const _CustomActivityIndicator.partiallyRevealed({
    this.color,
    this.radius = _kDefaultIndicatorRadius,
    this.progress = 1.0,
    required this.indicator,
  })  : assert(radius > 0.0),
        assert(progress >= 0.0),
        assert(progress <= 1.0),
        animating = false;

  /// Color of the activity indicator.
  ///
  /// Defaults to color extracted from native iOS.
  final Color? color;

  /// Whether the activity indicator is running its animation.
  ///
  /// Defaults to true.
  final bool animating;

  /// Radius of the spinner widget.
  ///
  /// Defaults to 10px. Must be positive and cannot be null.
  final double radius;

  /// Determines the percentage of spinner ticks that will be shown. Typical usage would
  /// display all ticks, however, this allows for more fine-grained control such as
  /// during pull-to-refresh when the drag-down action shows one tick at a time as
  /// the user continues to drag down.
  ///
  /// Defaults to 1.0. Must be between 0.0 and 1.0 inclusive, and cannot be null.
  final double progress;

  final Widget indicator;

  @override
  State<_CustomActivityIndicator> createState() =>
      _CustomActivityIndicatorState();
}

class _CustomActivityIndicatorState extends State<_CustomActivityIndicator>
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
  void didUpdateWidget(_CustomActivityIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animating != oldWidget.animating) {
      if (widget.animating) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
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
        height: widget.radius * 2,
        width: widget.radius * 2,
        child: widget.indicator);
  }
}
