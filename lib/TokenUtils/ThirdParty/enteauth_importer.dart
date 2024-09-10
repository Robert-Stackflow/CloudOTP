import 'dart:convert';
import 'dart:io';

import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category.dart';
import 'package:cloudotp/Models/token_category_binding.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/base_token_importer.dart';
import 'package:cloudotp/TokenUtils/import_token_util.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Widgets/Dialog/progress_dialog.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/input_bottom_sheet.dart';
import '../../Widgets/Item/input_item.dart';
import '../../generated/l10n.dart';

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
          showProgressDialog(msg: S.current.importing, showProgress: false);
    }
    try {
      File file = File(path);
      if (!file.existsSync()) {
        IToast.showTop(S.current.fileNotExist);
      } else {
        String content = file.readAsStringSync();
        Map<String, dynamic> json = {};
        try {
          json = jsonDecode(content);
          EnteAuthBackup backup = EnteAuthBackup.fromJson(json);
          if (!backup.isValid) {
            IToast.showTop(S.current.importFromEnteAuthInvalid);
            return;
          }
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
              var res = await decrypt(text, backup.kdfParams, backup.encryptedData,
                  backup.encryptedNonce);
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
                return S.current.invalidPasswordOrDataCorrupted;
              }
            },
            controller: TextEditingController(),
          );
          BottomSheetBuilder.showBottomSheet(
            rootContext,
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
              tailingType: InputItemTailingType.password,
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
      ILogger.error("CloudOTP","Failed to import from 2FAS", e, t);
      IToast.showTop(S.current.importFailed);
    } finally {
      if (showLoading) {
        dialog.dismiss();
      }
    }
  }
}
