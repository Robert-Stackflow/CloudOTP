part of 'lottie_cupertino_refresh.dart';

/// Cupertino header.
/// https://github.com/THEONE10211024/WaterDropListView
class LottieCupertinoHeader extends Header {
  final Key? key;

  /// Indicator foreground color.
  final Color? foregroundColor;

  final double? radius;

  /// WaterDrop background color.
  final Color? backgroundColor;

  /// Empty widget.
  /// When result is [IndicatorResult.noMore].
  final Widget? emptyWidget;

  final Widget indicator;

  const LottieCupertinoHeader({
    this.key,
    super.triggerOffset = 60,
    super.clamping = false,
    super.position = IndicatorPosition.behind,
    super.processedDuration = Duration.zero,
    super.spring,
    super.readySpringBuilder,
    super.springRebound = false,
    FrictionFactor? frictionFactor,
    super.safeArea,
    super.infiniteOffset,
    super.hitOver,
    super.infiniteHitOver,
    super.hapticFeedback,
    super.triggerWhenRelease,
    super.maxOverOffset,
    this.foregroundColor,
    this.backgroundColor,
    this.emptyWidget,
    required this.indicator,
    this.radius,
  }) : super(
          frictionFactor: frictionFactor ??
              (infiniteOffset == null ? kCupertinoFrictionFactor : null),
          horizontalFrictionFactor: kCupertinoHorizontalFrictionFactor,
        );

  @override
  Widget build(BuildContext context, IndicatorState state) {
    return _CustomIndicator(
      key: key,
      state: state,
      reverse: state.reverse,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      emptyWidget: emptyWidget,
      radius: radius,
      indicator: indicator,
    );
  }
}
