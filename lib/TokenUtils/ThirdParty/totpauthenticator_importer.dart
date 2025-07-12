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
import 'package:cloudotp/TokenUtils/ThirdParty/base_token_importer.dart';
import 'package:cloudotp/Utils/Base32/base32.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:convert/convert.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/paddings/pkcs7.dart';

import 'package:awesome_chewie/awesome_chewie.dart';
import '../../generated/l10n.dart';

class TotpAuthenticatorAccount {
  final String issuer;
  final String name;
  final String key;
  final String digits;
  final String period;
  final int base;

  TotpAuthenticatorAccount({
    required this.issuer,
    required this.name,
    required this.key,
    required this.digits,
    required this.period,
    required this.base,
  });

  factory TotpAuthenticatorAccount.fromJson(Map<String, dynamic> json) {
    return TotpAuthenticatorAccount(
      issuer: json['issuer'] as String,
      name: json['name'] as String,
      key: json['key'] as String,
      digits: json['digits'] as String,
      period: json['period'] as String,
      base: json['base'] as int,
    );
  }

  OtpToken toOtpToken() {
    var secretBytes = hex.decode(key);
    var secret = base32.encode(Uint8List.fromList(secretBytes));
    OtpToken token = OtpToken.init();
    token.issuer = issuer;
    token.account = name;
    token.secret = secret;
    token.digits = OtpDigits.fromString(digits);
    token.periodString = period;
    token.algorithm = OtpAlgorithm.SHA1;
    token.tokenType = OtpTokenType.TOTP;
    return token;
  }

  Map<String, dynamic> toJson() {
    return {
      'issuer': issuer,
      'name': name,
      'key': key,
      'digits': digits,
      'period': period,
      'base': base,
    };
  }
}

class TotpAuthenticatorTokenImporter implements BaseTokenImporter {
  static const String Algorithm = "AES/CBC/PKCS7";

  static List<TotpAuthenticatorAccount>? decrypt(String data, String password) {
    if (password.isEmpty) {
      return null;
    }

    final passwordBytes = utf8.encode(password);
    final digest = Digest('SHA-256');
    final key = digest.process(Uint8List.fromList(passwordBytes));

    final actualBytes = base64.decode(data);

    var keyParameter = ParametersWithIV(KeyParameter(key), Uint8List(16));
    var cipher = CBCBlockCipher(AESEngine())..init(false, keyParameter);

    try {
      Uint8List decryptedBytes;
      final decrypted = Uint8List(actualBytes.length);
      var offset = 0;
      while (offset < actualBytes.length) {
        offset += cipher.processBlock(actualBytes, offset, decrypted, offset);
      }
      final padding = PKCS7Padding();
      final padCount = padding.padCount(decrypted);
      decryptedBytes = decrypted.sublist(0, decrypted.length - padCount);

      var json = utf8.decode(decryptedBytes);
      json = json.substring(2);
      json = json.substring(0, json.lastIndexOf(']') + 1);
      json = json.replaceAll(r'\"', '"');

      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded
          .map((e) =>
              TotpAuthenticatorAccount.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, t) {
      debugPrint("Failed to decrypt 2FAS data: $e\n$t");
      return null;
    }
  }

  Future<void> import(List<TotpAuthenticatorAccount> accounts) async {
    List<OtpToken> tokens = [];
    tokens = accounts.map((e) => e.toOtpToken()).toList();
    await BaseTokenImporter.importResult(ImporterResult(tokens, [], []));
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
        var content = file.readAsStringSync();
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
            var res = await compute(
              (receiveMessage) {
                return decrypt(receiveMessage["data"] as String,
                    receiveMessage["password"] as String);
              },
              {
                'data': content,
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
