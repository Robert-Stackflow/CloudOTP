import 'package:cloudotp/TokenUtils/token_image_util.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/utils.dart';
import 'package:flutter/cupertino.dart';

class AssetUtil {
  static const String searchDarkIcon = "assets/icon/search_dark.png";
  static const String searchGreyIcon = "assets/icon/search_grey.png";
  static const String searchLightIcon = "assets/icon/search_light.png";
  static const String settingDarkIcon = "assets/icon/setting_dark.png";
  static const String settingLightIcon = "assets/icon/setting_light.png";
  static const String pinDarkIcon = "assets/icon/pin_dark.png";
  static const String pinLightIcon = "assets/icon/pin_light.png";

  static const String emptyIcon = "assets/icon/empty.png";

  static load(
    String path, {
    double size = 24,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Image.asset(
      path,
      fit: fit,
      width: width ?? size,
      height: height ?? size,
    );
  }

  static loadBrand(
    String path, {
    double size = 24,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    String darkPath = path.replaceAll(".png", "_dark.png");
    bool hasDark = TokenImageUtil.darkBrandLogos.contains(darkPath);
    if (hasDark) {
      return loadDouble(
        rootContext,
        'assets/brand/$path',
        'assets/brand/$darkPath',
        size: size,
        width: width,
        height: height,
        fit: fit,
      );
    } else {
      return load(
        'assets/brand/$path',
        size: size,
        width: width,
        height: height,
        fit: fit,
      );
    }
  }

  static loadDouble(
    BuildContext context,
    String light,
    String dark, {
    double size = 24,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Image.asset(
      Utils.isDark(context) ? dark : light,
      fit: fit,
      width: width ?? size,
      height: height ?? size,
    );
  }

  static loadDecorationImage(
    String path, {
    BoxFit? fit,
  }) {
    return DecorationImage(
      image: AssetImage(path),
      fit: fit,
    );
  }
}
