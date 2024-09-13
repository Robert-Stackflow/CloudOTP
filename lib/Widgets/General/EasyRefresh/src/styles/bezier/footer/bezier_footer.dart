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

part of '../../../../easy_refresh.dart';

/// Bezier footer.
class BezierFooter extends Footer {
  final Key? key;

  /// Show the ball during the pull.
  final bool showBalls;

  /// Spin widget.
  final Widget? spinWidget;

  /// No more widget.
  final Widget? noMoreWidget;

  /// Spin widget builder.
  final BezierSpinBuilder? spinBuilder;

  /// Foreground color.
  final Color? foregroundColor;

  /// Background color.
  final Color? backgroundColor;

  /// Whether the spin widget is in the center.
  final bool spinInCenter;

  /// Only display the spin.
  /// When true, the balls are no longer displayed.
  final bool onlySpin;

  const BezierFooter({
    this.key,
    super.triggerOffset = 100,
    super.clamping = false,
    super.position,
    super.processedDuration = kBezierBackgroundDisappearDuration,
    super.spring,
    SpringBuilder super.readySpringBuilder = kBezierSpringBuilder,
    super.springRebound = false,
    FrictionFactor super.frictionFactor = kBezierFrictionFactor,
    super.safeArea,
    super.infiniteOffset = null,
    super.hitOver,
    super.infiniteHitOver,
    super.hapticFeedback,
    this.showBalls = true,
    this.spinInCenter = true,
    this.onlySpin = false,
    this.spinWidget,
    this.noMoreWidget,
    this.spinBuilder,
    this.foregroundColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, IndicatorState state) {
    return _BezierIndicator(
      key: key,
      state: state,
      reverse: !state.reverse,
      processedDuration: processedDuration,
      showBalls: showBalls,
      spinInCenter: spinInCenter,
      onlySpin: onlySpin,
      spinWidget: spinWidget,
      noMoreWidget: noMoreWidget,
      spinBuilder: spinBuilder,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
    );
  }
}
