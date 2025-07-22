sealed class ResizableSize {
  const ResizableSize._({this.min, this.max})
      : assert(
          min == null || min >= 0,
          'min must be greater than or equal to 0',
        ),
        assert(
          min == null || min < double.infinity,
          'min cannot be equal to infinity',
        ),
        assert(
          max == null || max >= 0,
          'max must be greater than or equal to 0',
        ),
        assert(
          max == null || max < double.infinity,
          'max cannot be equal to infinity',
        ),
        assert(
          min == null || max == null || min <= max,
          'min must be less than or equal to max',
        );

  final double? min;
  final double? max;

  /// Creates a [ResizableSize] with a fixed size in pixels.
  ///
  /// 0 <= [pixels] < infinity
  /// 0 <= [min] < [max] < infinity
  const factory ResizableSize.pixels(
    double pixels, {
    double? min,
    double? max,
  }) = ResizableSizePixels._;

  /// Creates a [ResizableSize] with a size equal to a ratio of the available space.
  ///
  /// 0 <= [ratio] <= 1
  /// 0 <= [min] < [max] < infinity
  const factory ResizableSize.ratio(
    double ratio, {
    double? min,
    double? max,
  }) = ResizableSizeRatio._;

  /// Creates a [ResizableSize] that expands to fill the available space not taken
  /// by other resizable children.
  ///
  /// 1 <= [flex] < infinity
  /// 0 <= [min] < [max] < infinity
  const factory ResizableSize.expand({
    int flex,
    double? min,
    double? max,
  }) = ResizableSizeExpand._;

  /// Creates a [ResizableSize] that shrinks to fit the size of its child [Widget].
  ///
  /// 0 <= [min] < [max] < infinity
  const factory ResizableSize.shrink({
    double? min,
    double? max,
  }) = ResizableSizeShrink._;
}

final class ResizableSizePixels extends ResizableSize {
  const ResizableSizePixels._(this.pixels, {super.min, super.max})
      : assert(pixels >= 0, 'pixels must be greater than or equal to 0'),
        super._();

  final double pixels;

  @override
  String toString() => 'ResizableSizePixels($pixels)';

  @override
  operator ==(Object other) =>
      other is ResizableSizePixels && other.pixels == pixels;

  @override
  int get hashCode => pixels.hashCode;
}

final class ResizableSizeRatio extends ResizableSize {
  const ResizableSizeRatio._(this.ratio, {super.min, super.max})
      : assert(ratio >= 0, 'ratio must be greater than or equal to 0'),
        assert(ratio <= 1, 'ratio must be less than or equal to 1'),
        super._();

  final double ratio;

  @override
  String toString() => 'ResizableSizeRatio($ratio)';

  @override
  operator ==(Object other) =>
      other is ResizableSizeRatio && other.ratio == ratio;

  @override
  int get hashCode => ratio.hashCode;
}

final class ResizableSizeExpand extends ResizableSize {
  const ResizableSizeExpand._({this.flex = 1, super.min, super.max})
      : assert(flex > 0, 'flex must be greater than 0'),
        super._();

  final int flex;

  @override
  String toString() => 'ResizableSizeExpand(flex: $flex)';

  @override
  operator ==(Object other) =>
      other is ResizableSizeExpand && other.flex == flex;

  @override
  int get hashCode => flex.hashCode;
}

final class ResizableSizeShrink extends ResizableSize {
  const ResizableSizeShrink._({super.min, super.max}) : super._();

  @override
  String toString() => 'ResizableSizeShrink()';
}
