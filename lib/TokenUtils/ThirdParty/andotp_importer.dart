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
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/digests/sha1.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';

import 'package:awesome_chewie/awesome_chewie.dart';
import '../../generated/l10n.dart';

class AndOTPToken {
  String account;
  String issuer;
  int digits;
  int counter;
  int period;
  String algorithm;
  String tokenType;
  String secret;
  List<String> tags;
  String uid;

  AndOTPToken({
    required this.account,
    required this.issuer,
    required this.digits,
    required this.algorithm,
    required this.tokenType,
    required this.period,
    required this.counter,
    required this.secret,
    required this.tags,
  }) : uid = StringUtil.generateUid();

  factory AndOTPToken.fromJson(Map<String, dynamic> json) {
    return AndOTPToken(
      account: json['label'] ?? "",
      issuer: json['issuer'].notNullOrEmpty ? json['issuer'] : json['label'],
      digits: json['digits'] ?? 0,
      counter: json['counter'] ?? 0,
      algorithm: json['algorithm'],
      tokenType: json['type'],
      period: json['period'] ?? 0,
      secret: json['secret'],
      tags: json['tags'] != null
          ? (json['tags'] as List).map((e) => e.toString()).toList()
          : [],
    );
  }

  OtpToken toOtpToken() {
    OtpToken token = OtpToken.init();
    token.uid = uid;
    token.issuer = issuer;
    token.account = account;
    token.secret = secret;
    token.counterString = counter > 0 ? counter.toString() : "0";
    token.digits = digits > 0
        ? OtpDigits.fromString(digits.toString())
        : token.tokenType.defaultDigits;
    token.algorithm = OtpAlgorithm.fromString(algorithm);
    token.tokenType = OtpTokenType.fromString(tokenType);
    token.periodString = period <= 0
        ? token.tokenType.defaultPeriod.toString()
        : period.toString();
    return token;
  }

  List<TokenCategoryBinding> getBindings() {
    return tags.map((e) {
      return TokenCategoryBinding(
        tokenUid: uid,
        categoryUid: e,
      );
    }).toList();
  }
}

class AndOTPTokenImporter implements BaseTokenImporter {
  static const String BaseAlgorithm = "AES";
  static const String Mode = "GCM";
  static const String Padding = "NoPadding";
  static const String AlgorithmDescription = "$BaseAlgorithm/$Mode/$Padding";

  static const int IterationsLength = 4;
  static const int SaltLength = 12;
  static const int IvLength = 12;
  static const int KeyLength = 32;

  static KeyParameter deriveKey(
      String password, Uint8List salt, int iterations) {
    var passwordBytes = utf8.encode(password);
    var generator = PBKDF2KeyDerivator(HMac(SHA1Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, KeyLength));
    return KeyParameter(generator.process(Uint8List.fromList(passwordBytes)));
  }

  static List<Map<String, dynamic>>? decrypt(Uint8List data, String password) {
    try {
      final iterations = ByteData.sublistView(data, 0, IterationsLength)
          .getUint32(0, Endian.big);
      final salt =
          data.sublist(IterationsLength, IterationsLength + SaltLength);
      final iv = data.sublist(IterationsLength + SaltLength,
          IterationsLength + SaltLength + IvLength);
      final payload = data.sublist(IterationsLength + SaltLength + IvLength);

      final key = deriveKey(password, salt, iterations);
      final keyParameter = ParametersWithIV(key, iv);
      final cipher = GCMBlockCipher(AESEngine())..init(false, keyParameter);

      final decrypted = cipher.process(payload);
      final res = utf8.decode(decrypted);
      return (jsonDecode(res) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (e, t) {
      return null;
    }
  }

  Future<void> import(List<Map<String, dynamic>> items) async {
    List<OtpToken> tokens = [];
    List<TokenCategory> categories = [];
    List<TokenCategoryBinding> bindings = [];
    List<AndOTPToken> andOTPTokens = [];
    for (var service in items) {
      try {
        andOTPTokens.add(AndOTPToken.fromJson(service));
      } finally {}
    }
    Set<String> uniqueTags = andOTPTokens.expand((e) => e.tags).toSet();
    categories = uniqueTags.map((e) {
      return TokenCategory.title(
        tUid: StringUtil.generateUid(),
        title: e,
      );
    }).toList();
    for (var token in andOTPTokens) {
      token.tags = token.tags.map((e) {
        return categories.firstWhere((element) => element.title == e).uid;
      }).toList();
    }
    tokens = andOTPTokens.map((e) => e.toOtpToken()).toList();
    bindings = andOTPTokens.expand((e) => e.getBindings()).toList();
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
        String content = "";
        List<Map<String, dynamic>> json = [];
        try {
          content = file.readAsStringSync();
          json = (jsonDecode(content) as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          await import(json);
        } catch (e, t) {
          Uint8List data = file.readAsBytesSync();
          if (showLoading) dialog.dismiss();
          InputValidateAsyncController validateAsyncController =
              InputValidateAsyncController(
            listen: false,
            validator: (text) async {
              if (text.isEmpty) {
                return S.current.autoBackupPasswordCannotBeEmpty;
              }
              if (showLoading) {
                dialog.show(msg: S.current.importing, showProgress: false);
              }
              List<Map<String, dynamic>>? res = await compute(
                (receiveMessage) {
                  List<int> data = (receiveMessage["data"] as List)
                      .map((e) => e as int)
                      .toList();
                  return decrypt(Uint8List.fromList(data),
                      receiveMessage["password"] as String);
                },
                {
                  'data': data.toList(),
                  'password': text,
                },
              );
              if (res != null) {
                await import(res);
                if (showLoading) {
                  dialog.dismiss();
                }
                return null;
              } else {
                if (showLoading) {
                  dialog.dismiss();
                }
                return S.current.invalidPasswordOrDataCorrupted;
              }
            },
            controller: TextEditingController(),
          );
          BottomSheetBuilder.showBottomSheet(
            chewieProvider.rootContext,
            responsive: true,
            useWideLandscape: true,
            (context) => InputBottomSheet(
              validator: (value) {
                if (value.isEmpty) {
                  return S.current.autoBackupPasswordCannotBeEmpty;
                }
                return null;
              },
              checkSyncValidator: false,
              validateAsyncController: validateAsyncController,
              title: S.current.inputImportPasswordTitle,
              message: S.current.inputImportPasswordTip,
              hint: S.current.inputImportPasswordHint,
              inputFormatters: [
                RegexInputFormatter.onlyNumberAndLetterAndSymbol,
              ],
              tailingConfig: InputItemLeadingTailingConfig(
                type: InputItemLeadingTailingType.password,
              ),
              onValidConfirm: (password) async {},
            ),
          );
        }
      }
    } catch (e, t) {
      ILogger.error("Failed to import from 2FAS", e, t);
      IToast.showTop(S.current.importFailed);
    } finally {
      if (showLoading) {
        dialog.dismiss();
      }
    }
  }
}
