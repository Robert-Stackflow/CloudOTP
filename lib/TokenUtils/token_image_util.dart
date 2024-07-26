import 'dart:convert';

import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Utils/utils.dart';
import 'package:flutter/services.dart';

class TokenImageUtil {
  static List<String> brandLogos = [];

  static loadBrandLogos() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final brandFiles = manifestMap.keys
        .where((String key) => key.startsWith('assets/brand/'))
        .toList();
    brandLogos = brandFiles.map((file) => file.split('/').last).toList();
  }

  Future<bool> isAssetExist(String path) async {
    try {
      await rootBundle.loadString(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String cleanBrand(String brand) {
    return brand.replaceAll(RegExp(r'[_\s-]'), '').toLowerCase();
  }

  static String? matchBrandLogo(OtpToken token) {
    final brand = cleanBrand(token.issuer);
    if (Utils.isEmpty(brand)) return null;
    String brandLogo = brandLogos.firstWhere(
      (logo) => cleanBrand(logo).split(".")[0] == brand,
      orElse: () => "",
    );
    if (brandLogo.isEmpty) {
      brandLogo = brandLogos.firstWhere(
        (logo) => cleanBrand(logo).split(".")[0].contains(brand),
        orElse: () => "",
      );
    }
    return brandLogo.isEmpty ? null : "assets/brand/$brandLogo";
  }
}
