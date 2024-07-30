import 'package:flutter/cupertino.dart';
import 'package:cloudotp/Utils/utils.dart';
import 'package:lottie/lottie.dart';

class LottieUtil {
  static const String brightness = "assets/lottie/brightness.json";
  static const String celebrate = "assets/lottie/celebrate.json";
  static const String loadingHourglass = "assets/lottie/loading_hourglass.json";
  static const String loadingInfinity = "assets/lottie/loading_infinity.json";
  static const String moonLight = "assets/lottie/moon_light.json";
  static const String sunLight = "assets/lottie/sun_light.json";

  static Transform load(
    String path, {
    double size = 40,
    bool? autoForward,
    AnimationController? controller,
    Function()? onLoaded,
    BoxFit? fit,
    double scale = 1.0,
  }) {
    return Transform.scale(
      scale: scale,
      child: Lottie.asset(
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
      ),
    );
  }

  static String getLoadingPath(
    BuildContext context, {
    bool forceDark = false,
    bool useInfinity = true,
  }) {
    String path = useInfinity ? loadingInfinity : loadingHourglass;
    return Utils.isDark(context) || forceDark
        ? forceDark
            ? path
            : path
        : path;
  }
}
