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
      ILogger.error("Failed to load asset $path", e, t);
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
