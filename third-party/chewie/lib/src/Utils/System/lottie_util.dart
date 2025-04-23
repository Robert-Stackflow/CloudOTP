import 'package:awesome_chewie/src/Utils/General/color_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:lottie/lottie.dart';

class LottieUtil {
  static LottieBuilder load(
    String path, {
    double size = 40,
    bool? autoForward,
    AnimationController? controller,
    Function()? onLoaded,
    BoxFit? fit,
  }) {
    return Lottie.asset(
      path,
      width: size,
      height: size,
      fit: fit,
      controller: controller,
      alignment: Alignment.bottomCenter,
      addRepaintBoundary: true,
      onLoaded: (composition) {
        if (controller != null) {
          controller.duration = composition.duration;
          if (autoForward == true) controller.value = 1;
        }
        onLoaded?.call();
      },
    );
  }
}
