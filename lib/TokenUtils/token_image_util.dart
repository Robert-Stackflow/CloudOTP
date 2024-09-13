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

import 'dart:convert';

import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Utils/utils.dart';
import 'package:flutter/services.dart';

import '../../Utils/ilogger.dart';

class TokenImageUtil {
  static List<String> brandLogos = [];
  static List<String> darkBrandLogos = [];

  static loadBrandLogos() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final brandFiles = manifestMap.keys
        .where((String key) =>
            key.startsWith('assets/brand/') && key.endsWith('.png'))
        .toList();
    brandLogos = brandFiles.map((file) => file.split('/').last).toList();
    for (var logo in brandLogos) {
      if (logo.endsWith("_dark.png")) {
        darkBrandLogos.add(logo);
      }
    }
    brandLogos.removeWhere((logo) => logo.endsWith("_dark.png"));
  }

  Future<bool> isAssetExist(String path) async {
    try {
      await rootBundle.loadString(path);
      return true;
    } catch (e, t) {
      ILogger.error("CloudOTP","Failed to load asset $path", e, t);
      return false;
    }
  }

  static String cleanBrand(String brand) {
    return brand.replaceAll(RegExp(r'[_\s-]'), '').toLowerCase();
  }

  static String? matchBrandLogo(OtpToken token) {
    final issuer = cleanBrand(token.issuer);
    if (Utils.isEmpty(issuer)) return null;
    String brandLogo = brandLogos.firstWhere(
      (logo) => cleanBrand(logo).split(".")[0] == issuer,
      orElse: () => "",
    );
    if (brandLogo.isEmpty) {
      brandLogo = brandLogos.firstWhere(
        (logo) => cleanBrand(logo).split(".")[0].contains(issuer),
        orElse: () => "",
      );
    }
    if (brandLogo.isEmpty) {
      switch (token.tokenType) {
        case OtpTokenType.Steam:
          brandLogo = "steam.png";
          break;
        case OtpTokenType.Yandex:
          brandLogo = "yandex.png";
          break;
        default:
          break;
      }
    }
    return brandLogo.isEmpty ? null : brandLogo;
  }

  static List<String> matchBrandLogos(String issuer) {
    if (Utils.isEmpty(issuer)) return TokenImageUtil.brandLogos;
    issuer = cleanBrand(issuer);
    List<String> res = [];
    String brandLogo = brandLogos.firstWhere(
      (logo) => cleanBrand(logo).split(".")[0] == issuer,
      orElse: () => "",
    );
    if (brandLogo.isNotEmpty) res.add(brandLogo);
    for (var e in brandLogos) {
      if (e != brandLogo && cleanBrand(e).split(".")[0].contains(issuer)) {
        res.add(e);
      }
    }
    return res;
  }
}
