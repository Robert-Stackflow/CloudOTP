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

/// Material footer.
class MaterialFooter extends Footer {
  final Key? key;

  /// See [ProgressIndicator.backgroundColor].
  final Color? backgroundColor;

  /// See [ProgressIndicator.color].
  final Color? color;

  /// See [ProgressIndicator.valueColor].
  final Animation<Color?>? valueColor;

  /// See [ProgressIndicator.semanticsLabel].
  final String? semanticsLabel;

  /// See [ProgressIndicator.semanticsLabel].
  final String? semanticsValue;

  /// Icon when [IndicatorResult.noMore].
  final Widget? noMoreIcon;

  /// Show bezier background.
  final bool showBezierBackground;

  /// Bezier background color.
  /// See [BezierBackground.color].
  final Color? bezierBackgroundColor;

  /// Bezier background animation.
  /// See [BezierBackground.useAnimation].
  final bool bezierBackgroundAnimation;

  /// Bezier background bounce.
  /// See [BezierBackground.bounce].
  final bool bezierBackgroundBounce;

  const MaterialFooter({
    this.key,
    super.triggerOffset = 100,
    super.clamping = true,
    super.position,
    super.processedDuration = const Duration(milliseconds: 200),
    super.spring,
    SpringBuilder? readySpringBuilder,
    super.springRebound = false,
    FrictionFactor? frictionFactor,
    super.safeArea,
    super.infiniteOffset = null,
    super.hitOver,
    super.infiniteHitOver,
    super.hapticFeedback,
    super.triggerWhenRelease,
    super.maxOverOffset,
    this.backgroundColor,
    this.color,
    this.valueColor,
    this.semanticsLabel,
    this.semanticsValue,
    this.noMoreIcon,
    this.showBezierBackground = false,
    this.bezierBackgroundColor,
    this.bezierBackgroundAnimation = false,
    this.bezierBackgroundBounce = false,
  }) : super(
          readySpringBuilder: readySpringBuilder ??
              (bezierBackgroundAnimation
                  ? kBezierSpringBuilder
                  : kMaterialSpringBuilder),
          frictionFactor: frictionFactor ??
              (showBezierBackground
                  ? kBezierFrictionFactor
                  : kMaterialFrictionFactor),
          horizontalFrictionFactor: frictionFactor ??
              (showBezierBackground
                  ? kBezierHorizontalFrictionFactor
                  : kMaterialHorizontalFrictionFactor),
        );

  @override
  Widget build(BuildContext context, IndicatorState state) {
    return _MaterialIndicator(
      key: key,
      state: state,
      disappearDuration: processedDuration,
      reverse: !state.reverse,
      backgroundColor: backgroundColor,
      color: color,
      valueColor: valueColor,
      semanticsLabel: semanticsLabel,
      semanticsValue: semanticsValue,
      noMoreIcon: noMoreIcon,
      showBezierBackground: showBezierBackground,
      bezierBackgroundColor: bezierBackgroundColor,
      bezierBackgroundAnimation: bezierBackgroundAnimation,
      bezierBackgroundBounce: bezierBackgroundBounce,
    );
  }
}
