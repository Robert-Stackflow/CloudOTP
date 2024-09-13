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

/// Bezier circle footer.
/// https://dribbble.com/shots/1797373-Pull-Down-To-Refresh
class BezierCircleHeader extends Header {
  final Key? key;

  /// Foreground color.
  final Color? foregroundColor;

  /// Background color.
  final Color? backgroundColor;

  const BezierCircleHeader({
    this.key,
    super.triggerOffset = 100,
    super.clamping = false,
    super.position,
    super.spring,
    SpringBuilder super.readySpringBuilder = kBezierSpringBuilder,
    super.springRebound = false,
    FrictionFactor super.frictionFactor = kBezierFrictionFactor,
    super.safeArea,
    super.infiniteOffset,
    super.hitOver,
    super.infiniteHitOver,
    super.hapticFeedback,
    this.foregroundColor,
    this.backgroundColor,
  }) : super(
          processedDuration: kBezierCircleDisappearDuration,
        );

  @override
  Widget build(BuildContext context, IndicatorState state) {
    assert(state.axis == Axis.vertical,
        'BezierCircleHeader does not support horizontal scrolling.');
    assert(!state.reverse, 'BezierCircleHeader does not support reverse.');
    return _BezierCircleIndicator(
      key: key,
      state: state,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
    );
  }
}
