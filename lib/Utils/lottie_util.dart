import 'package:flutter/cupertino.dart';
import 'package:cloudotp/Utils/utils.dart';
import 'package:lottie/lottie.dart';

class LottieUtil {
  static const String brightness = "assets/lottie/brightness.json";
  static const String celebrate = "assets/lottie/celebrate.json";
  static const String collectionBigNormalDark =
      "assets/lottie/collection_big_normal_dark.json";
  static const String collectionBigNormalLight =
      "assets/lottie/collection_big_normal_light.json";
  static const String collectionMediumNormalDark =
      "assets/lottie/collection_medium_normal_dark.json";
  static const String collectionMediumNormalLight =
      "assets/lottie/collection_medium_normal_light.json";
  static const String followDark = "assets/lottie/follow_dark.json";
  static const String followLight = "assets/lottie/follow_light.json";
  static const String followVideo = "assets/lottie/follow_video.json";
  static const String giftDark = "assets/lottie/gift_dark.json";
  static const String letter = "assets/lottie/letter.json";
  static const String likeBigNormalDark =
      "assets/lottie/like_big_normal_dark.json";
  static const String likeBigNormalLight =
      "assets/lottie/like_big_normal_light.json";
  static const String likeDoubleClickDark =
      "assets/lottie/like_double_click_dark.json";
  static const String likeDoubleClickLight =
      "assets/lottie/like_double_click_light.json";
  static const String likeDoubleTap = "assets/lottie/like_double_tap.json";
  static const String likeMediumDark = "assets/lottie/like_medium_dark.json";
  static const String likeMediumLight = "assets/lottie/like_medium_light.json";
  static const String likeVibrateLight =
      "assets/lottie/like_vibrate_light.json";
  static const String likeVideoNormal = "assets/lottie/like_video_normal.json";
  static const String likeVideoVibrate =
      "assets/lottie/like_video_vibrate.json";
  static const String loading01 = "assets/lottie/loading_01.json";
  static const String loading02 = "assets/lottie/loading_02.json";
  static const String loadingDark = "assets/lottie/loading_dark.json";
  static const String loadingDarkTransparent =
      "assets/lottie/loading_dark_transparent.json";
  static const String loadingGradient = "assets/lottie/loading_gradient.json";
  static const String loadingLight = "assets/lottie/loading_light.json";
  static const String moonLight = "assets/lottie/moon_light.json";
  static const String recommendBigNormalDark =
      "assets/lottie/recommend_big_normal_dark.json";
  static const String recommendBigNormalLight =
      "assets/lottie/recommend_big_normal_light.json";
  static const String recommendBigVibrateDark =
      "assets/lottie/recommend_big_vibrate_dark.json";
  static const String recommendBigVibrateLight =
      "assets/lottie/recommend_big_vibrate_light.json";
  static const String recommendMediumFocusDark =
      "assets/lottie/recommend_medium_focus_dark.json";
  static const String recommendMediumFocusLight =
      "assets/lottie/recommend_medium_focus_light.json";
  static const String recommendVideoNormal =
      "assets/lottie/recommend_video_normal.json";
  static const String shareVideoVibrate =
      "assets/lottie/share_video_vibrate.json";
  static const String shine = "assets/lottie/shine.json";
  static const String sunLight = "assets/lottie/sun_light.json";
  static const String videoPlayingDark =
      "assets/lottie/video_playing_dark.json";
  static const String videoPlayingLight =
      "assets/lottie/video_playing_light.json";

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

  static String getLoadingPath(
    BuildContext context, {
    bool forceDark = false,
  }) {
    return Utils.isDark(context) || forceDark
        ? forceDark
            ? LottieUtil.loadingDarkTransparent
            : LottieUtil.loadingDark
        : LottieUtil.loadingLight;
  }
}
