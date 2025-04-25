part of 'lottie_cupertino_refresh.dart';

/// Cupertino footer.
/// https://github.com/THEONE10211024/WaterDropListView
class LottieCupertinoFooter extends Footer {
  final Key? key;

  /// Indicator foreground color.
  final Color? foregroundColor;

  /// WaterDrop background color.
  final Color? backgroundColor;

  final double? radius;

  /// Empty widget.
  /// When result is [IndicatorResult.noMore].
  final Widget? emptyWidget;

  final Widget indicator;

  const LottieCupertinoFooter({
    this.key,
    super.triggerOffset = 60,
    super.clamping = false,
    super.position = IndicatorPosition.behind,
    super.processedDuration = Duration.zero,
    super.spring,
    super.readySpringBuilder,
    super.springRebound,
    FrictionFactor? frictionFactor,
    super.safeArea,
    super.infiniteOffset = 60,
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
              (infiniteOffset == null ? kCustomCupertinoFrictionFactor : null),
          horizontalFrictionFactor: kCustomCupertinoHorizontalFrictionFactor,
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
      indicator: indicator,
      radius: radius,
    );
  }
}
