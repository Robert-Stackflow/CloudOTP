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
import 'dart:io';

import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category.dart';
import 'package:cloudotp/Models/token_category_binding.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/base_token_importer.dart';
import 'package:cloudotp/Utils/Base32/base32.dart';
import 'package:flutter/foundation.dart';

import 'package:awesome_chewie/awesome_chewie.dart';
import '../../Utils/utils.dart';
import '../../generated/l10n.dart';

class TokenInfo {
  String label;
  String issuer;
  int digits;
  int counter;
  int period;
  String algorithm;
  String tokenType;
  List<int> secret;

  TokenInfo({
    required this.label,
    required this.issuer,
    required this.counter,
    required this.digits,
    required this.period,
    required this.algorithm,
    required this.tokenType,
    required this.secret,
  });

  factory TokenInfo.fromJson(Map<String, dynamic> json) {
    return TokenInfo(
      label: json['label'],
      issuer: json['issuerExt'],
      digits: json['digits'],
      counter: json['counter'],
      period: json['period'],
      algorithm: json['algo'],
      tokenType: json['type'],
      secret: json['secret'],
    );
  }
}

class FreeOTPPlusToken {
  String label;
  String issuer;
  int digits;
  int counter;
  int period;
  String algorithm;
  String tokenType;
  List<int> secret;

  FreeOTPPlusToken({
    required this.label,
    required this.issuer,
    required this.counter,
    required this.digits,
    required this.period,
    required this.algorithm,
    required this.tokenType,
    required this.secret,
  });

  factory FreeOTPPlusToken.fromJson(Map<String, dynamic> json) {
    List<dynamic> tmp = json['secret'];
    List<int> secret = tmp.map((e) => e as int).toList();
    return FreeOTPPlusToken(
      label: json['label'],
      issuer: json['issuerExt'],
      digits: json['digits'],
      counter: json['counter'],
      period: json['period'],
      algorithm: json['algo'],
      tokenType: json['type'],
      secret: secret,
    );
  }

  List<TokenCategoryBinding> getBindings() {
    return [];
  }

  OtpToken toOtpToken() {
    OtpToken token = OtpToken.init();
    token.uid = StringUtil.generateUid();
    token.account = label;
    token.secret = base32.encode(Uint8List.fromList(secret));
    token.issuer = issuer;
    token.algorithm = OtpAlgorithm.fromString(algorithm);
    token.counterString = counter > 0 ? counter.toString() : "0";
    token.digits = digits > 0
        ? OtpDigits.fromString(digits.toString())
        : token.tokenType.defaultDigits;
    token.tokenType = OtpTokenType.fromString(tokenType);
    token.periodString = period <= 0
        ? token.tokenType.defaultPeriod.toString()
        : period.toString();
    return token;
  }
}

class FreeOTPPlusTokenImporter implements BaseTokenImporter {
  static const int MasterKeyBytes = 32;

  Future<void> import(Map<String, dynamic> json) async {
    List<OtpToken> tokens = [];
    List<TokenCategory> categories = [];
    List<TokenCategoryBinding> bindings = [];
    List<FreeOTPPlusToken> freeOTPPlusTokens = [];
    if (json.containsKey("tokens")) {
      List<dynamic> tokenList = json["tokens"];
      for (var token in tokenList) {
        try {
          FreeOTPPlusToken freeOTPPlusToken = FreeOTPPlusToken.fromJson(token);
          freeOTPPlusTokens.add(freeOTPPlusToken);
        } catch (e, t) {
          ILogger.error("Failed to parse token: $token", e, t);
        }
      }
    }
    tokens = freeOTPPlusTokens.map((e) => e.toOtpToken()).toList();
    bindings = freeOTPPlusTokens.expand((e) => e.getBindings()).toList();
    await BaseTokenImporter.importResult(
        ImporterResult(tokens, categories, bindings));
  }

  @override
  Future<void> importFromPath(
    String path, {
    bool showLoading = true,
  }) async {
    late ProgressDialog dialog;
    if (showLoading) {
      dialog = showProgressDialog(S.current.importing, showProgress: false);
    }
    try {
      File file = File(path);
      if (!file.existsSync()) {
        IToast.showTop(S.current.fileNotExist);
      } else {
        Map<String, dynamic> json = jsonDecode(file.readAsStringSync());
        await import(json);
      }
    } catch (e, t) {
      ILogger.error("Failed to import from FreeOTPPlus", e, t);
      IToast.showTop(S.current.importFailed);
    } finally {
      if (showLoading) {
        dialog.dismiss();
      }
    }
  }
}
