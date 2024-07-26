part of 'lottie_cupertino_refresh.dart';

const double _kDefaultCustomIndicatorRadius = 20.0;

double kCupertinoFrictionFactor(double overscrollFraction) =>
    0.25 * math.pow(1 - overscrollFraction, 2);

double kCupertinoHorizontalFrictionFactor(double overscrollFraction) =>
    0.52 * math.pow(1 - overscrollFraction, 2);

/// Custom indicator.
/// Base widget for [LottieCupertinoHeader] and [LottieCupertinoFooter].
class _CustomIndicator extends StatefulWidget {
  /// Indicator properties and state.
  final IndicatorState state;

  /// True for up and left.
  /// False for down and right.
  final bool reverse;

  final double? radius;

  /// Indicator foreground color.
  final Color? foregroundColor;

  /// WaterDrop background color.
  final Color? backgroundColor;

  /// Empty widget.
  /// When result is [IndicatorResult.noMore].
  final Widget? emptyWidget;

  final Widget indicator;

  const _CustomIndicator({
    super.key,
    required this.state,
    required this.reverse,
    this.foregroundColor,
    this.backgroundColor,
    this.emptyWidget,
    required this.indicator,
    this.radius,
  });

  @override
  State<_CustomIndicator> createState() => _CustomIndicatorState();
}

class _CustomIndicatorState extends State<_CustomIndicator>
    with SingleTickerProviderStateMixin {
  Axis get _axis => widget.state.axis;

  IndicatorMode get _mode => widget.state.mode;

  double get _offset => widget.state.offset;

  double get _actualTriggerOffset => widget.state.actualTriggerOffset;

  double get _radius => widget.radius ?? _kDefaultCustomIndicatorRadius;

  @override
  void initState() {
    super.initState();
    widget.state.notifier.addModeChangeListener(_onModeChange);
  }

  @override
  void dispose() {
    widget.state.notifier.removeModeChangeListener(_onModeChange);
    super.dispose();
  }

  /// Mode change listener.
  void _onModeChange(IndicatorMode mode, double offset) {
    if (mode == IndicatorMode.ready) {}
  }

  Widget _buildIndicator() {
    final scale = (_offset / _actualTriggerOffset).clamp(0.01, 0.99);
    Widget indicator;
    switch (_mode) {
      case IndicatorMode.drag:
      case IndicatorMode.armed:
        const Curve opacityCurve = Interval(
          0.0,
          0.8,
          curve: Curves.easeInOut,
        );
        indicator = Opacity(
          key: const ValueKey('indicatorArmed'),
          opacity: opacityCurve.transform(scale),
          child: _CustomActivityIndicator.partiallyRevealed(
            radius: _radius,
            progress: scale,
            color: widget.foregroundColor,
            indicator: widget.indicator,
          ),
        );
        break;
      case IndicatorMode.ready:
      case IndicatorMode.processing:
      case IndicatorMode.processed:
        indicator = _CustomActivityIndicator(
          key: const ValueKey('indicatorReady'),
          radius: _radius,
          color: widget.foregroundColor,
          animating: true,
          indicator: widget.indicator,
        );
        break;
      case IndicatorMode.done:
        indicator = _CustomActivityIndicator(
          key: const ValueKey('indicatorDone'),
          radius: _radius * scale,
          color: widget.foregroundColor,
          animating: true,
          indicator: widget.indicator,
        );
        break;
      default:
        indicator = const SizedBox(
          key: ValueKey('indicatorDefault'),
        );
        break;
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 100),
      child: widget.state.result == IndicatorResult.noMore
          ? widget.emptyWidget != null
              ? SizedBox(
                  key: const ValueKey('noMoreCustom'),
                  child: widget.emptyWidget!,
                )
              : Icon(
                  CupertinoIcons.archivebox,
                  key: const ValueKey('noMoreDefault'),
                  color: widget.foregroundColor,
                )
          : indicator,
    );
  }

  @override
  Widget build(BuildContext context) {
    double offset = _offset;
    if (widget.state.indicator.infiniteOffset != null &&
        widget.state.indicator.position == IndicatorPosition.locator &&
        (_mode != IndicatorMode.inactive ||
            widget.state.result == IndicatorResult.noMore)) {
      offset = _actualTriggerOffset;
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: _axis == Axis.vertical ? offset : double.infinity,
          width: _axis == Axis.vertical ? double.infinity : offset,
        ),
        // Indicator.
        Positioned(
          top: 0,
          left: 0,
          right: _axis == Axis.vertical ? 0 : null,
          bottom: _axis == Axis.vertical ? null : 0,
          child: Container(
            alignment: Alignment.center,
            height:
                _axis == Axis.vertical ? _actualTriggerOffset : double.infinity,
            width:
                _axis == Axis.vertical ? double.infinity : _actualTriggerOffset,
            child: _buildIndicator(),
          ),
        ),
      ],
    );
  }
}
