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

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category.dart';
import 'package:cloudotp/Models/token_category_binding.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/base_token_importer.dart';
import 'package:cloudotp/TokenUtils/import_token_util.dart';
import '../../Utils/EnteCrypto/ente_crypto_dart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../l10n/l10n.dart';

class KdfParams {
  int memLimit;
  int opsLimit;
  String salt;

  KdfParams({
    required this.memLimit,
    required this.opsLimit,
    required this.salt,
  });

  factory KdfParams.fromJson(Map<String, dynamic> json) {
    return KdfParams(
      memLimit: json['memLimit'] ?? 0,
      opsLimit: json['opsLimit'] ?? 0,
      salt: json['salt'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memLimit': memLimit,
      'opsLimit': opsLimit,
      'salt': salt,
    };
  }

  @override
  String toString() {
    return jsonEncode({
      'memLimit': memLimit,
      'opsLimit': opsLimit,
      'salt': salt,
    });
  }
}

class EnteAuthBackup {
  int version;
  KdfParams kdfParams;
  String encryptedData;
  String encryptedNonce;

  EnteAuthBackup({
    required this.version,
    required this.kdfParams,
    required this.encryptedData,
    required this.encryptedNonce,
  });

  factory EnteAuthBackup.fromJson(Map<String, dynamic> json) {
    return EnteAuthBackup(
      version: json['version'] ?? 0,
      kdfParams: json['kdfParams'] != null && json['kdfParams'].isNotEmpty
          ? KdfParams.fromJson(json['kdfParams'])
          : KdfParams(memLimit: 0, opsLimit: 0, salt: ""),
      encryptedData: json['encryptedData'] ?? "",
      encryptedNonce: json['encryptionNonce'] ?? "",
    );
  }

  bool get isValid {
    return encryptedData.isNotEmpty &&
        encryptedNonce.isNotEmpty &&
        kdfParams.memLimit > 0 &&
        kdfParams.opsLimit > 0 &&
        kdfParams.salt.isNotEmpty;
  }
}

class EnteAuthTokenImporter implements BaseTokenImporter {
  static const int KeyLength = 32;
  static const int DerivationParallelism = 1;

  static dynamic decrypt(
      String password, KdfParams param, String data, String header) async {
    try {
      final derivedKey = await CryptoUtil.deriveKey(
        utf8.encode(password),
        CryptoUtil.base642bin(param.salt),
        param.memLimit,
        param.opsLimit,
      );
      Uint8List? decryptedContent;
      decryptedContent = await CryptoUtil.decryptData(
        CryptoUtil.base642bin(data),
        derivedKey,
        CryptoUtil.base642bin(header),
      );
      return [DecryptResult.success, utf8.decode(decryptedContent)];
    } catch (e, s) {
      debugPrint("$e\n$s");
      return [DecryptResult.invalidPasswordOrDataCorrupted, null];
    }
  }

  Future<void> import(List<OtpToken> toImportTokens) async {
    List<TokenCategory> categories = [];
    List<TokenCategoryBinding> bindings = [];
    List<String> uniqueTags =
        toImportTokens.expand((element) => element.tags).toSet().toList();
    categories.addAll(uniqueTags
        .map((e) => TokenCategory.title(title: e))
        .where((element) => !categories.contains(element)));
    for (var token in toImportTokens) {
      bindings.addAll(token.tags.map((e) => TokenCategoryBinding(
            tokenUid: token.uid,
            categoryUid:
                categories.firstWhere((element) => element.title == e).uid,
          )));
    }
    await BaseTokenImporter.importResult(
        ImporterResult(toImportTokens, categories, bindings));
  }

  @override
  Future<void> importFromPath(
    String path, {
    bool showLoading = true,
  }) async {
    late ProgressDialog dialog;
    if (showLoading) {
      dialog =
          showProgressDialog(appLocalizations.importing, showProgress: false);
    }
    try {
      File file = File(path);
      if (!file.existsSync()) {
        IToast.showTop(appLocalizations.fileNotExist);
      } else {
        String content = file.readAsStringSync();
        Map<String, dynamic> json = {};
        try {
          json = jsonDecode(content);
          EnteAuthBackup backup = EnteAuthBackup.fromJson(json);
          if (!backup.isValid) {
            IToast.showTop(appLocalizations.importFromEnteAuthInvalid);
            return;
          }
          if (showLoading) dialog.dismiss();
          InputValidateAsyncController validateAsyncController =
              InputValidateAsyncController(
            listen: false,
            validator: (text) async {
              if (text.isEmpty) {
                return appLocalizations.autoBackupPasswordCannotBeEmpty;
              }
              if (showLoading) {
                dialog.show(
                    msg: appLocalizations.importing, showProgress: false);
              }
              // var res = await compute(
              //   (receiveMessage) async {
              //     return await decrypt(
              //         receiveMessage["password"] as String,
              //         KdfParams.fromJson(
              //             receiveMessage["params"] as Map<String, dynamic>),
              //         receiveMessage["data"] as String,
              //         receiveMessage["header"] as String);
              //   },
              //   {
              //     'data': backup.encryptedData,
              //     "params": backup.kdfParams.toJson(),
              //     'header': backup.encryptedNonce,
              //     'password': text,
              //   },
              // );
              var res = await decrypt(text, backup.kdfParams,
                  backup.encryptedData, backup.encryptedNonce);
              if (res[0] == DecryptResult.success) {
                List<OtpToken> tokens =
                    await ImportTokenUtil.importText(res[1], showToast: false);
                await import(tokens);
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
        } catch (e) {
          List<OtpToken> tokens =
              await ImportTokenUtil.importText(content, showToast: false);
          await import(tokens);
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
