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
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';

import 'package:awesome_chewie/awesome_chewie.dart';
import '../../l10n/l10n.dart';

class TwoFASTokenOtp {
  String label;
  String account;
  String issuer;
  int digits;
  int period;
  String algorithm;
  String tokenType;

  TwoFASTokenOtp({
    required this.label,
    required this.account,
    required this.issuer,
    required this.digits,
    required this.algorithm,
    required this.tokenType,
    required this.period,
  });

  factory TwoFASTokenOtp.fromJson(Map<String, dynamic> json) {
    return TwoFASTokenOtp(
      label: json['label'] ?? "",
      account: json['account'] ?? "",
      issuer: json['issuer'] ?? json['account'] ?? "",
      digits: json['digits'] ?? 0,
      algorithm: json['algorithm'] ?? "SHA1",
      tokenType: json['tokenType'] ?? "TOTP",
      period: json['period'] ?? 0,
    );
  }
}

class TwoFASToken {
  String name;
  String secret;
  TwoFASTokenOtp otp;
  String groupId;
  String serviceTypeID;

  TwoFASToken({
    required this.name,
    required this.secret,
    required this.otp,
    required this.groupId,
    required this.serviceTypeID,
  });

  factory TwoFASToken.fromJson(Map<String, dynamic> json) {
    return TwoFASToken(
      name: json['name'],
      secret: json['secret'],
      otp: TwoFASTokenOtp.fromJson(json['otp']),
      groupId: json['groupId'] ?? "",
      serviceTypeID: json['serviceTypeID'] ?? "",
    );
  }

  OtpToken toOtpToken() {
    OtpToken token = OtpToken.init();
    token.uid = serviceTypeID;
    token.issuer = otp.issuer;
    token.account = otp.account;
    token.secret = secret;
    // token.counterString = otp.digits > 0
    //     ? otp.digits.toString()
    //     : token.tokenType.defaultDigits.toString();
    token.digits = otp.digits > 0
        ? OtpDigits.fromString(otp.digits.toString())
        : token.tokenType.defaultDigits;
    token.algorithm = OtpAlgorithm.fromString(otp.algorithm);
    token.tokenType = OtpTokenType.fromString(otp.tokenType);
    token.periodString = otp.period <= 0
        ? token.tokenType.defaultPeriod.toString()
        : otp.period.toString();
    return token;
  }

  List<TokenCategoryBinding> getBindings() {
    return [
      TokenCategoryBinding(
        tokenUid: serviceTypeID,
        categoryUid: groupId,
      ),
    ];
  }
}

class TwoFASGroup {
  String id;
  String name;

  TwoFASGroup({
    required this.id,
    required this.name,
  });

  TokenCategory toTokenCategory() {
    return TokenCategory.title(
      tUid: id,
      title: name,
    );
  }

  factory TwoFASGroup.fromJson(Map<String, dynamic> json) {
    return TwoFASGroup(
      id: json['id'],
      name: json['name'],
    );
  }
}

class TwoFASTokenImporter implements BaseTokenImporter {
  static const String baseAlgorithm = 'AES';
  static const String mode = 'GCM';
  static const String padding = 'NoPadding';
  static const String algorithmDescription = '$baseAlgorithm/$mode/$padding';

  static const int iterations = 10000;
  static const int keyLength = 32;

  static dynamic decryptServices(String payload, String password) {
    var parts = payload.split(":");

    if (parts.length < 3) {
      return [
        DecryptResult.invalidPasswordOrDataCorrupted,
        null,
      ];
    }

    var encryptedData = base64Decode(parts[0]);
    var salt = base64Decode(parts[1]);
    var iv = base64Decode(parts[2]);

    var key = deriveKey(password, salt);
    var cipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(key, 128, iv, Uint8List(0)));

    Uint8List decryptedBytes;

    try {
      decryptedBytes = cipher.process(encryptedData);
    } catch (e) {
      return [
        DecryptResult.invalidPasswordOrDataCorrupted,
        null,
      ];
    }

    var decryptedJson = utf8.decode(decryptedBytes);
    return [DecryptResult.success, jsonDecode(decryptedJson)];
  }

  static KeyParameter deriveKey(String password, Uint8List salt) {
    var passwordBytes = utf8.encode(password);
    PBKDF2KeyDerivator generator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, keyLength));
    return KeyParameter(generator.process(Uint8List.fromList(passwordBytes)));
  }

  Future<void> import(Map<String, dynamic> json) async {
    List<OtpToken> tokens = [];
    List<TokenCategory> categories = [];
    List<TokenCategoryBinding> bindings = [];
    List<TwoFASGroup> twoFASGroups = [];
    List<TwoFASToken> twoFASTokens = [];
    if (json.containsKey('services')) {
      for (var service in json['services']) {
        try {
          twoFASTokens.add(TwoFASToken.fromJson(service));
        } catch (e, t) {
          ILogger.error("Failed to import 2FAS token", e, t);
        }
      }
    }
    if (json.containsKey('groups')) {
      for (var service in json['groups']) {
        try {
          twoFASGroups.add(TwoFASGroup.fromJson(service));
        } catch (e, t) {
          ILogger.error("Failed to import 2FAS token groups", e, t);
        }
      }
    }
    categories = twoFASGroups.map((e) => e.toTokenCategory()).toList();
    tokens = twoFASTokens.map((e) => e.toOtpToken()).toList();
    bindings = twoFASTokens.expand((e) => e.getBindings()).toList();
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
      dialog = showProgressDialog(appLocalizations.importing, showProgress: false);
    }
    try {
      File file = File(path);
      if (!file.existsSync()) {
        IToast.showTop(appLocalizations.fileNotExist);
      } else {
        String content = file.readAsStringSync();
        Map<String, dynamic> json = jsonDecode(content);
        if (json.containsKey('servicesEncrypted')) {
          if (showLoading) dialog.dismiss();
          InputValidateAsyncController validateAsyncController =
              InputValidateAsyncController(
            listen: false,
            validator: (text) async {
              if (text.isEmpty) {
                return appLocalizations.autoBackupPasswordCannotBeEmpty;
              }
              if (showLoading) {
                dialog.show(msg: appLocalizations.importing, showProgress: false);
              }
              var res = await compute(
                (receiveMessage) {
                  return decryptServices(receiveMessage["servicesEncrypted"],
                      receiveMessage["password"]);
                },
                {
                  'servicesEncrypted': json['servicesEncrypted'],
                  'password': text,
                },
              );
              DecryptResult decryptResult = res[0];
              if (decryptResult == DecryptResult.success) {
                json['services'] = res[1];
                await import(json);
                if (showLoading) {
                  dialog.dismiss();
                }
                return null;
              } else {
                if (showLoading) {
                  dialog.dismiss();
                }
                return appLocalizations.invalidPasswordOrDataCorrupted;
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
                  return appLocalizations.autoBackupPasswordCannotBeEmpty;
                }
                return null;
              },
              checkSyncValidator: false,
              validateAsyncController: validateAsyncController,
              title: appLocalizations.inputImportPasswordTitle,
              message: appLocalizations.inputImportPasswordTip,
              hint: appLocalizations.inputImportPasswordHint,
              inputFormatters: [
                RegexInputFormatter.onlyNumberAndLetterAndSymbol,
              ],
              tailingConfig: InputItemLeadingTailingConfig(
                type: InputItemLeadingTailingType.password,
              ),
              onValidConfirm: (password) async {},
            ),
          );
        } else {
          await import(json);
        }
      }
    } catch (e, t) {
      ILogger.error("Failed to import from 2FAS", e, t);
      IToast.showTop(appLocalizations.importFailed);
    } finally {
      if (showLoading) {
        dialog.dismiss();
      }
    }
  }
}
