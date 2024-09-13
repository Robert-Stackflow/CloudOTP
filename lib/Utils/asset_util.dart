/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

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

  static const String ic2Fas = "assets/auth/ic_2fas.png";
  static const String icAegis = "assets/auth/ic_aegis.png";
  static const String icAndotp = "assets/auth/ic_andotp.png";
  static const String icAuthenticatorplus =
      "assets/auth/ic_authenticatorplus.png";
  static const String icAuthenticatorpro =
      "assets/auth/ic_authenticatorpro.png";
  static const String icAuthy = "assets/auth/ic_authy.png";
  static const String icBitwarden = "assets/auth/ic_bitwarden.png";
  static const String icBlizzard = "assets/auth/ic_blizzard.png";
  static const String icEnteauth = "assets/auth/ic_enteauth.png";
  static const String icFreeotp = "assets/auth/ic_freeotp.png";
  static const String icFreeotpplus = "assets/auth/ic_freeotpplus.png";
  static const String icGoogleauthenticator =
      "assets/auth/ic_googleauthenticator.png";
  static const String icLastpass = "assets/auth/ic_lastpass.png";
  static const String icSteam = "assets/auth/ic_steam.png";
  static const String icTotpauthenticator =
      "assets/auth/ic_totpauthenticator.png";
  static const String icWinauth = "assets/auth/ic_winauth.png";

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

  static getBrandPath(
    String brand, {
    bool forceLight = true,
  }) {
    if (brand.isEmpty) return "";
    String darkPath = brand.replaceAll(".png", "_dark.png");
    bool hasDark = TokenImageUtil.darkBrandLogos.contains(darkPath);
    return 'assets/brand/$brand';
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
