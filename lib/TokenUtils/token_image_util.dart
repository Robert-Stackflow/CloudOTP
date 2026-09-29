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

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:flutter/services.dart';

class TokenImageUtil {
  static const int matchThreshold = 5;
  static List<String> brandLogos = [];
  static List<String> darkBrandLogos = [];
  static final Map<String, List<String>> _matchCache = {};
  static List<String>? _indexedSource;
  static List<({String filename, String brand})> _indexedLogos = [];

  static loadBrandLogos() async {
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final brandFiles = assetManifest
        .listAssets()
        .where((String key) =>
            key.startsWith('assets/brand/') && key.endsWith('.png'))
        .toList();
    brandLogos = brandFiles.map((file) => file.split('/').last).toList();
    darkBrandLogos.clear();
    for (var logo in brandLogos) {
      if (logo.endsWith("_dark.png")) {
        darkBrandLogos.add(logo);
      }
    }
    brandLogos.removeWhere((logo) => logo.endsWith("_dark.png"));
    _rebuildIndex();
  }

  static void _rebuildIndex() {
    _indexedSource = brandLogos;
    _indexedLogos = [
      for (final logo in brandLogos)
        (filename: logo, brand: cleanBrand(logo.substring(0, logo.length - 4))),
    ];
    _matchCache.clear();
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

  static int longestCommonSubstring(String a, String b) {
    final m = a.length;
    final n = b.length;
    int maxLen = 0;

    var previous = List<int>.filled(n + 1, 0);

    for (int i = 1; i <= m; i++) {
      final current = List<int>.filled(n + 1, 0);
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          current[j] = previous[j - 1] + 1;
          maxLen = maxLen < current[j] ? current[j] : maxLen;
        }
      }
      previous = current;
    }

    return maxLen;
  }

  static String? matchBrandLogo(OtpToken token) {
    final issuer = cleanBrand(token.issuer);
    if (issuer.nullOrEmpty) return null;

    final matches = matchBrandLogos(issuer);
    if (matches.isNotEmpty) return matches.first;

    switch (token.tokenType) {
      case OtpTokenType.Steam:
        return "steam.png";
      case OtpTokenType.Yandex:
        return "yandex.png";
      default:
        return null;
    }
  }

  static List<String> matchBrandLogos(String issuer) {
    if (issuer.nullOrEmpty) return TokenImageUtil.brandLogos;

    issuer = cleanBrand(issuer);
    if (!identical(_indexedSource, brandLogos)) _rebuildIndex();

    if (_matchCache.containsKey(issuer)) {
      return _matchCache[issuer]!;
    }

    const int substringMatchThreshold = 5;
    final matches = <MapEntry<String, int>>[];

    for (final candidate in _indexedLogos) {
      final logo = candidate.filename;
      final brand = candidate.brand;
      final bool containsEither =
          issuer.contains(brand) || brand.contains(issuer);
      final bool equal = issuer == brand;
      if (equal) {
        matches.add(MapEntry(logo, 10000));
      } else if (containsEither) {
        matches.add(MapEntry(
            logo, issuer.length < brand.length ? issuer.length : brand.length));
      } else if (issuer.length >= substringMatchThreshold &&
          brand.length >= substringMatchThreshold) {
        final lcs = longestCommonSubstring(issuer, brand);
        if (lcs >= substringMatchThreshold) matches.add(MapEntry(logo, lcs));
      }
    }

    matches.sort((a, b) => b.value.compareTo(a.value));

    final seen = <String>{};
    final result = [
      for (final entry in matches)
        if (seen.add(entry.key)) entry.key
    ];

    if (_matchCache.length >= 512) _matchCache.clear();
    _matchCache[issuer] = result;

    return result;
  }
}
