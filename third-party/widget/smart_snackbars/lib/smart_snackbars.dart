library smart_snackbars;

import 'package:flutter/material.dart';
import 'package:smart_snackbars/enums/animate_from.dart';
import 'package:smart_snackbars/widgets/snackbars/base_snackbar.dart';

/// This class is intended to provide Smart SnackBars methods.
class SmartSnackBars {
  static void _removeOverlayEntry(OverlayEntry overlayEntry) {
    overlayEntry.remove();
  }

  static OverlayEntry showCustomSnackBar({
    required BuildContext context,
    Widget? child,
    Duration? duration,
    Curve? animationCurve,
    AnimateFrom? animateFrom,
    EdgeInsetsGeometry? outerPadding,
    double? elevation,
    Color? shadowColor,
    bool? persist,
    double? distanceToTravel,
    CustomSnackBarController? controller,
    double? maxWidth,
    Alignment? alignment,
    Function()? onDismiss,
  }) {
    duration ??= const Duration(milliseconds: 1000);

    // Get the OverlayState
    final overlayState = Overlay.of(context);
    // Create an OverlayEntry with your custom widget
    OverlayEntry? snackBar;
    snackBar = OverlayEntry(
      builder: (_) => CustomSnackBar(
        controller: controller,
        maxWidth: maxWidth,
        alignment: alignment ?? Alignment.centerRight,
        duration: duration ??= const Duration(milliseconds: 1000),
        animationCurve: animationCurve ??= Curves.ease,
        animateFrom: animateFrom ??= AnimateFrom.fromBottom,
        outerPadding: outerPadding ??=
            const EdgeInsets.symmetric(horizontal: 10),
        persist: persist ??= false,
        distanceToTravelFromStartToEnd: distanceToTravel ??= 20,
        onDismissed: persist!
            ? () {
                onDismiss?.call();
                if (snackBar != null) {
                  _removeOverlayEntry(snackBar);
                }
              }
            : () {
                onDismiss?.call();
              },
        child: child ??= Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(10),
          color: Colors.blue,
          child: const Text(
            "Create Your Custom SnackBar",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
    // then insert it to the overlay
    // this will show the toast widget on the screen
    overlayState.insert(snackBar);
    // 3 secs later remove the toast from the stack
    // and this one will remove the toast from the screen

    if (persist == null || !persist!) {
      Future.delayed(duration! * 2, snackBar.remove);
    }
    return snackBar;
  }
}
