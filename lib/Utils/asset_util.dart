import 'package:cloudotp/TokenUtils/token_image_util.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/utils.dart';
import 'package:flutter/cupertino.dart';

class AssetUtil {
  static const String collectionDarkIcon = "assets/icon/collection_dark.png";
  static const String collectionLightIcon = "assets/icon/collection_light.png";
  static const String collectionPrimaryIcon =
      "assets/icon/collection_primary.png";
  static const String collectionWhiteIcon = "assets/icon/collection_white.png";
  static const String confirmIcon = "assets/icon/confirm.png";
  static const String downloadWhiteIcon = "assets/icon/download_white.png";
  static const String dressDarkIcon = "assets/icon/dress_dark.png";
  static const String dressLightIcon = "assets/icon/dress_light.png";
  static const String dynamicDarkIcon = "assets/icon/dynamic_dark.png";
  static const String dynamicDarkSelectedIcon =
      "assets/icon/dynamic_dark_selected.png";
  static const String dynamicLightIcon = "assets/icon/dynamic_light.png";
  static const String dynamicLightSelectedIcon =
      "assets/icon/dynamic_light_selected.png";
  static const String favoriteDarkIcon = "assets/icon/favorite_dark.png";
  static const String favoriteLightIcon = "assets/icon/favorite_light.png";
  static const String grainWhiteIcon = "assets/icon/grain_white.png";
  static const String homeDarkIcon = "assets/icon/home_dark.png";
  static const String homeDarkSelectedIcon =
      "assets/icon/home_dark_selected.png";
  static const String homeLightIcon = "assets/icon/home_light.png";
  static const String homeLightSelectedIcon =
      "assets/icon/home_light_selected.png";
  static const String hotIcon = "assets/icon/hot.png";
  static const String hotlessIcon = "assets/icon/hotless.png";
  static const String hottestIcon = "assets/icon/hottest.png";
  static const String hotWhiteIcon = "assets/icon/hot_white.png";
  static const String infoIcon = "assets/icon/info.png";
  static const String likeDarkIcon = "assets/icon/like_dark.png";
  static const String likeFilledIcon = "assets/icon/like_filled.png";
  static const String likeLightIcon = "assets/icon/like_light.png";
  static const String linkDarkIcon = "assets/icon/link_dark.png";
  static const String linkGreyIcon = "assets/icon/link_grey.png";
  static const String linkLightIcon = "assets/icon/link_light.png";
  static const String linkPrimaryIcon = "assets/icon/link_primary.png";
  static const String linkWhiteIcon = "assets/icon/link_white.png";
  static const String mineDarkIcon = "assets/icon/mine_dark.png";
  static const String mineDarkSelectedIcon =
      "assets/icon/mine_dark_selected.png";
  static const String mineLightIcon = "assets/icon/mine_light.png";
  static const String mineLightSelectedIcon =
      "assets/icon/mine_light_selected.png";
  static const String orderDownDarkIcon = "assets/icon/order_down_dark.png";
  static const String orderDownLightIcon = "assets/icon/order_down_light.png";
  static const String orderUpDarkIcon = "assets/icon/order_up_dark.png";
  static const String orderUpLightIcon = "assets/icon/order_up_light.png";
  static const String searchDarkIcon = "assets/icon/search_dark.png";
  static const String searchGreyIcon = "assets/icon/search_grey.png";
  static const String searchLightIcon = "assets/icon/search_light.png";
  static const String settingDarkIcon = "assets/icon/setting_dark.png";
  static const String settingLightIcon = "assets/icon/setting_light.png";
  static const String tagDarkIcon = "assets/icon/tag_dark.png";
  static const String tagGreyIcon = "assets/icon/tag_grey.png";
  static const String tagLightIcon = "assets/icon/tag_light.png";
  static const String tagWhiteIcon = "assets/icon/tag_white.png";

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
