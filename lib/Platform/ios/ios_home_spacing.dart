import 'package:flutter/widgets.dart';

/// Consume system safe area once. Scaffold's extendBody padding includes its
/// entire bottom bar and must not be mistaken for the device safe area.
class IOSHomeSpacing {
  const IOSHomeSpacing(this.media);
  final MediaQueryData media;
  static const double tabHeight = 48;
  static const double scanTop = 8;
  static const double scannerHeight = 56;
  static const double bottomGap = 4;
  static const double contentHeight = scanTop + scannerHeight + bottomGap;
  double get safeBottom => (media.viewPadding.bottom - media.viewInsets.bottom)
      .clamp(0.0, double.infinity);
  double get barHeight => contentHeight + safeBottom;
  EdgeInsets get barPadding => EdgeInsets.only(
      top: scanTop + (scannerHeight - tabHeight) / 2,
      bottom: safeBottom + bottomGap + (scannerHeight - tabHeight) / 2,
      right: 86);
}
