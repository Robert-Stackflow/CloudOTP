import 'package:flutter/widgets.dart';
import 'ios_home_spacing.dart';

/// Keep the original scanner and tabs on one surface/one hide animation.
class IOSHomeControls extends StatelessWidget {
  const IOSHomeControls(
      {super.key,
      required this.spacing,
      required this.scanner,
      this.categoryBar});
  final IOSHomeSpacing spacing;
  final Widget scanner;
  final Widget? categoryBar;
  @override
  Widget build(BuildContext context) => SizedBox(
      height: spacing.barHeight,
      child: Stack(children: [
        if (categoryBar != null) Positioned.fill(child: categoryBar!),
        Positioned(top: IOSHomeSpacing.scanTop, right: 16, child: scanner),
      ]));
}
