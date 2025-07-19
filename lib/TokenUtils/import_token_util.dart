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
import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/TokenUtils/Backup/backup_encrypt_old.dart';
import 'package:cloudotp/TokenUtils/otp_token_parser.dart';
import 'package:cloudotp/TokenUtils/token_image_util.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

import '../Database/category_dao.dart';
import '../Database/config_dao.dart';
import '../Models/token_category.dart';
import '../Utils/constant.dart';
import '../Utils/hive_util.dart';
import '../Widgets/BottomSheet/token_option_bottom_sheet.dart';
import '../l10n/l10n.dart';
import 'Backup/backup.dart';
import 'Backup/backup_encrypt_interface.dart';
import 'Backup/backup_encrypt_v1.dart';

extension TrimPadding on String {
  String trimPadding() {
    return replaceAll(RegExp(r'=+$'), '').toUpperCase();
  }
}

class ImportAnalysis {
  int parseFailed;

  int parseSuccess;

  int importSuccess;

  int parseCategorySuccess;

  int importCategorySuccess;

  int importConfigSuccess;

  int importCloudServiceConfigSuccess;

  ImportAnalysis({
    this.parseFailed = 0,
    this.parseSuccess = 0,
    this.importSuccess = 0,
    this.parseCategorySuccess = 0,
    this.importCategorySuccess = 0,
    this.importConfigSuccess = 0,
    this.importCloudServiceConfigSuccess = 0,
  });

  showToast([String noTokenToast = ""]) {
    String tokenToast =
        appLocalizations.importResultTip(parseSuccess, importSuccess);
    String categoryToast = appLocalizations.importCategoryResultTip(
        parseCategorySuccess, importCategorySuccess);
    if (parseSuccess > 0) {
      if (parseCategorySuccess > 0) {
        IToast.showTop("$tokenToast; $categoryToast");
      } else {
        IToast.showTop(tokenToast);
      }
    } else if (parseCategorySuccess > 0) {
      IToast.showTop(categoryToast);
    } else {
      IToast.showTop(noTokenToast);
    }
  }
}

class ImportTokenUtil {
  static Future<List<dynamic>> parseRawUri(
    List<String> rawUris, {
    bool autoPopup = true,
    BuildContext? context,
  }) async {
    List<OtpToken> tokens = [];
    List<TokenCategory> categories = [];
    List<String> validTokenUris = [];
    List<String> validCategoryUris = [];
    for (String line in rawUris) {
      Uri? uri = Uri.tryParse(line);
      if (uri != null &&
          (otpauthReg.hasMatch(line) ||
              motpReg.hasMatch(line) ||
              otpauthMigrationReg.hasMatch(line) ||
              cloudotpauthMigrationReg.hasMatch(line))) {
        validTokenUris.add(line);
      }
      if (uri != null && cloudotpauthCategoryMigrationReg.hasMatch(line)) {
        validCategoryUris.add(line);
      }
    }
    if (validTokenUris.isNotEmpty) {
      tokens = await ImportTokenUtil.importText(
        validTokenUris.join("\n"),
        // noTokenToast: appLocalizations.imageDoesNotContainToken,
      );
      if (autoPopup && context != null && context.mounted) {
        Navigator.pop(context);
      }
    }
    if (validCategoryUris.isNotEmpty) {
      categories = await ImportTokenUtil.parseCategories(validCategoryUris);
      if (autoPopup && context != null && context.mounted) {
        Navigator.pop(context);
      }
    }
    if (tokens.isEmpty && categories.isEmpty) {
      IToast.showTop(appLocalizations.noQrCodeToken);
    }
    return [tokens, categories];
  }

  static Future<List<dynamic>> analyzeImageFile(
    String filepath, {
    required BuildContext context,
    bool showLoading = true,
  }) async {
    List<dynamic> res = [];
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: appLocalizations.analyzing);
    }
    try {
      File file = File(filepath);
      Uint8List? imageBytes = await compute<String, Uint8List?>((path) {
        return File(path).readAsBytesSync();
      }, filepath);
      String fileName = FileUtil.getFileNameWithExtension(file.path);
      if (ResponsiveUtil.isAndroid()) {
        await File("/storage/emulated/0/Pictures/$fileName")
            .delete(recursive: true);
        await file.delete(recursive: true);
      }
      res = await ImportTokenUtil.analyzeImage(
        imageBytes,
        context: context,
        showLoading: false,
        showSingleTokenDialog: false,
      );
    } finally {
      if (showLoading) {
        CustomLoadingDialog.dismissLoading();
      }
    }
    if (res[0].length == 1) {
      BottomSheetBuilder.showBottomSheet(
        context,
        responsive: true,
        (context) => TokenOptionBottomSheet(
          token: res[0].first,
          isNewToken: true,
        ),
      );
    }
    return res;
  }

  static Future<List<dynamic>> analyzeImage(
    Uint8List? imageBytes, {
    required BuildContext context,
    bool showLoading = true,
    bool doDismissLoading = false,
    bool showSingleTokenDialog = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: appLocalizations.analyzing);
    }
    List<OtpToken> tokens = [];
    List<TokenCategory> categories = [];
    if (imageBytes == null || imageBytes.isEmpty) {
      if (showLoading || doDismissLoading) {
        CustomLoadingDialog.dismissLoading();
      }
      IToast.showTop(appLocalizations.noQrCode);
      return [];
    }
    try {
      var result = await compute((bytes) {
        img.Image image = img.decodeImage(bytes)!;
        LuminanceSource source = RGBLuminanceSource(
            image.width,
            image.height,
            image
                .convert(numChannels: 4)
                .getBytes(order: img.ChannelOrder.abgr)
                .buffer
                .asInt32List());
        var bitmap = BinaryBitmap(GlobalHistogramBinarizer(source));
        var reader = QRCodeReader();
        return reader.decode(bitmap);
      }, imageBytes);
      if (result.text.notNullOrEmpty) {
        List<dynamic> res = await ImportTokenUtil.parseRawUri([result.text]);
        tokens = res[0];
        categories = res[1];
      } else {
        IToast.showTop(appLocalizations.noQrCode);
      }
    } catch (e, t) {
      ILogger.error("Failed to analyze image", e, t);
      if (e.runtimeType == NotFoundException) {
        IToast.showTop(appLocalizations.noQrCode);
      } else {
        IToast.showTop(appLocalizations.parseQrCodeWrong);
      }
    } finally {
      if (showLoading || doDismissLoading) {
        CustomLoadingDialog.dismissLoading();
      }
    }
    if (tokens.length == 1 && showSingleTokenDialog) {
      BottomSheetBuilder.showBottomSheet(
        context,
        responsive: true,
        (context) => TokenOptionBottomSheet(
          token: tokens.first,
          isNewToken: true,
        ),
      );
    }
    return [tokens, categories];
  }

  static importUriFile(
    String filePath, {
    bool showLoading = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: appLocalizations.importing);
    }
    try {
      File file = File(filePath);
      if (!file.existsSync()) {
        IToast.showTop(appLocalizations.fileNotExist);
        return;
      } else {
        String content = file.readAsStringSync(encoding: utf8);
        await importText(
          content,
          showLoading: showLoading,
          emptyTip: appLocalizations.fileEmpty,
          noTokenToast: appLocalizations.fileDoesNotContainToken,
        );
      }
    } catch (e, t) {
      ILogger.error("Failed to import uri file from $filePath", e, t);
      IToast.showTop(appLocalizations.importFailed);
    } finally {
      if (showLoading) {
        CustomLoadingDialog.dismissLoading();
      }
    }
  }

  static Future<bool> importOldEncryptFile(
    String filePath,
    String password, {
    bool showLoading = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: appLocalizations.importing);
    }
    try {
      File file = File(filePath);
      if (!file.existsSync()) {
        IToast.showTop(appLocalizations.fileNotExist);
        return true;
      } else {
        List<OtpToken>? tokens = await compute((_) async {
          Uint8List content = file.readAsBytesSync();
          List<OtpToken>? tokens =
              await BackupEncryptionOld().decrypt(content, password);
          return tokens;
        }, null);
        if (tokens == null) {
          IToast.showTop(appLocalizations.importFailed);
          return true;
        }
        ImportAnalysis analysis = ImportAnalysis();
        analysis.parseSuccess = tokens.length;
        analysis.importSuccess = await mergeTokens(tokens);
        if (showLoading) {
          CustomLoadingDialog.dismissLoading();
        }
        analysis.showToast(appLocalizations.fileDoesNotContainToken);
        return true;
      }
    } catch (e, t) {
      ILogger.error("Failed to import old encrypt file from $filePath", e, t);
      IToast.showTop(appLocalizations.importFailed);
      return false;
    } finally {
      if (showLoading) {
        CustomLoadingDialog.dismissLoading();
      }
    }
  }

  static _showImportPasswordDialog(BuildContext context, String path) {
    InputValidateAsyncController validateAsyncController =
        InputValidateAsyncController(
      controller: TextEditingController(),
      listen: false,
      validator: (text) async {
        if (text.isEmpty) {
          return appLocalizations.autoBackupPasswordCannotBeEmpty;
        }
        bool success = await ImportTokenUtil.importEncryptFile(path, text);
        if (success) {
          return null;
        } else {
          return appLocalizations.invalidPasswordOrDataCorrupted;
        }
      },
    );
    BottomSheetBuilder.showBottomSheet(
      context,
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
  }

  static importEncryptFileWrapper(
    BuildContext context,
    String filePath, {
    bool showLoading = true,
  }) async {
    operation() {
      _showImportPasswordDialog(context, filePath);
    }

    if (await CloudOTPHiveUtil.canImportOrExportUseBackupPassword()) {
      bool success = await ImportTokenUtil.importEncryptFile(
          filePath, await ConfigDao.getBackupPassword());
      if (!success) operation();
    } else {
      operation();
    }
  }

  static Future<bool> importEncryptFile(
    String filePath,
    String password, {
    bool showLoading = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: appLocalizations.importing);
    }
    try {
      File file = File(filePath);
      if (!file.existsSync()) {
        IToast.showTop(appLocalizations.fileNotExist);
        return true;
      } else {
        Uint8List content = await compute((_) async {
          return file.readAsBytesSync();
        }, null);
        await importUint8List(content, password: password);
        return true;
      }
    } catch (e, t) {
      ILogger.error("Failed to import encrypt file from $filePath", e, t);
      if (e is BackupBaseException) {
        IToast.showTop(e.intlMessage);
        if (e is InvalidPasswordOrDataCorruptedException) {
          return false;
        }
        return true;
      } else {
        IToast.showTop(appLocalizations.importFailed);
        return true;
      }
    } finally {
      if (showLoading) {
        CustomLoadingDialog.dismissLoading();
      }
    }
  }

  static Future<bool> importBackupFile(
    Uint8List content, {
    String? password,
    bool showLoading = true,
    String? loadingText,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(
          title: loadingText ?? appLocalizations.importing);
    }
    try {
      await importUint8List(content, password: password);
      return true;
    } catch (e, t) {
      ILogger.error("Failed to import backup file", e, t);
      if (e is BackupBaseException) {
        IToast.showTop(e.intlMessage);
        if (e is InvalidPasswordOrDataCorruptedException) {
          return false;
        }
        return true;
      } else {
        IToast.showTop(appLocalizations.importFailed);
        return true;
      }
    } finally {
      if (showLoading) {
        CustomLoadingDialog.dismissLoading();
      }
    }
  }

  static Future<bool> importUint8List(
    Uint8List content, {
    String? password,
  }) async {
    String tmpPassword = password ?? await ConfigDao.getBackupPassword();
    Backup backup = await compute((_) async {
      return await BackupEncryptionV1().decrypt(content, tmpPassword);
    }, null);
    ImportAnalysis analysis = ImportAnalysis();
    analysis.parseSuccess = backup.tokens.length;
    analysis.parseCategorySuccess = backup.categories.length;
    ImportAnalysis tmpAnalysis = await mergeTokensAndCategories(
      backup.tokens,
      backup.categories,
    );
    analysis.importSuccess = tmpAnalysis.importSuccess;
    analysis.importCategorySuccess = tmpAnalysis.importCategorySuccess;
    analysis.showToast(appLocalizations.fileDoesNotContainToken);
    return true;
  }

  static Future<List<OtpToken>> importText(
    String content, {
    String emptyTip = "",
    String noTokenToast = "",
    bool showLoading = true,
    bool showToast = true,
  }) async {
    if (content.isEmpty && emptyTip.notNullOrEmpty) {
      if (showToast) IToast.showTop(emptyTip);
      return [];
    }
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: appLocalizations.importing);
    }
    ImportAnalysis analysis = ImportAnalysis();
    List<String> lines = content.split("\n");
    List<OtpToken> tokens = [];
    for (String line in lines) {
      line = line.trim();
      List<OtpToken> parsedTokens = OtpTokenParser.parseUri(line);
      if (parsedTokens.isNotEmpty) {
        tokens.addAll(parsedTokens);
        analysis.parseSuccess += parsedTokens.length;
      } else {
        analysis.parseFailed++;
      }
    }
    analysis.importSuccess = await mergeTokens(tokens);
    if (showLoading) {
      CustomLoadingDialog.dismissLoading();
    }
    if (showToast) analysis.showToast(noTokenToast);
    return tokens;
  }

  static Future<List<TokenCategory>> parseCategories(List<String> lines) async {
    List<TokenCategory> categories = [];
    ImportAnalysis analysis = ImportAnalysis();
    for (var line in lines) {
      List<TokenCategory> tmp =
          await OtpTokenParser.parseCloudOtpauthCategoryMigration(line);
      categories.addAll(tmp);
    }
    analysis.parseCategorySuccess = categories.length;
    analysis.importCategorySuccess = await mergeCategories(categories);
    analysis.showToast();
    return categories;
  }

  static importFromCloud(
    BuildContext context,
    Uint8List? res,
    ProgressDialog dialog,
  ) async {
    dialog.updateMessage(
      msg: appLocalizations.importing,
      showProgress: false,
    );
    if (res == null) {
      dialog.dismiss();
      IToast.showTop(appLocalizations.cloudPullFailed);
      return;
    }
    bool success = await ImportTokenUtil.importBackupFile(
      res,
      showLoading: false,
    );
    dialog.dismiss();
    if (!success) {
      InputValidateAsyncController validateAsyncController =
          InputValidateAsyncController(
        listen: false,
        validator: (text) async {
          if (text.isEmpty) {
            return appLocalizations.autoBackupPasswordCannotBeEmpty;
          }
          dialog.show(
            msg: appLocalizations.importing,
            showProgress: false,
          );
          bool success = await ImportTokenUtil.importBackupFile(
            password: text,
            res,
            showLoading: false,
          );
          dialog.dismiss();
          if (success) {
            return null;
          } else {
            return appLocalizations.invalidPasswordOrDataCorrupted;
          }
        },
        controller: TextEditingController(),
      );
      BottomSheetBuilder.showBottomSheet(
        context,
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
    }
  }

  static Future<Map<String, String>> getAlreadyExistUid(
      List<OtpToken> tokenList) async {
    List<OtpToken> already = await TokenDao.listTokens();
    Map<String, String> uidMap = {};
    for (OtpToken token in tokenList) {
      OtpToken? alreadyToken = checkTokenExist(token, already);
      if (alreadyToken != null) {
        uidMap[token.uid] = alreadyToken.uid;
        token.uid = alreadyToken.uid;
      }
    }
    return uidMap;
  }

  static OtpToken? checkTokenExist(
      OtpToken toCheckToken, List<OtpToken> checkList) {
    for (OtpToken otpToken in checkList) {
      if (otpToken.issuer.trim() == toCheckToken.issuer.trim() &&
          otpToken.account.trim() == toCheckToken.account.trim() &&
          (otpToken.secret.trim() == toCheckToken.secret.trim() ||
              otpToken.secret.trimPadding() ==
                  toCheckToken.secret.trimPadding())) {
        return otpToken;
      }
    }
    return null;
  }

  static bool checkCategoryExist(
    TokenCategory category,
    List<TokenCategory> categoryList,
  ) {
    for (TokenCategory tokenCategory in categoryList) {
      if (tokenCategory.uid == category.uid &&
          tokenCategory.title != category.title) {
        category.uid = StringUtil.generateUid();
      }
      if (tokenCategory.title == category.title) {
        return true;
      }
    }
    return false;
  }

  static Future<ImportAnalysis> mergeTokensAndCategories(
    List<OtpToken> tokenList,
    List<TokenCategory> categoryList, {
    bool performInsert = true,
  }) async {
    ImportAnalysis analysis = ImportAnalysis();
    analysis.importSuccess = await mergeTokens(tokenList);
    Map<String, String> uidMap = await getAlreadyExistUid(tokenList);
    for (TokenCategory category in categoryList) {
      category.bindings = category.bindings.map((e) => uidMap[e] ?? e).toList();
    }
    analysis.importCategorySuccess = await mergeCategories(categoryList);
    return analysis;
  }

  static Future<int> mergeTokens(
    List<OtpToken> toMergeTokenList, {
    bool performInsert = true,
  }) async {
    List<OtpToken> already = await TokenDao.listTokens();
    List<OtpToken> finalMergeTokenList = [];
    for (OtpToken toMergeToken in toMergeTokenList) {
      if (toMergeToken.issuer.isEmpty) {
        toMergeToken.issuer = toMergeToken.account;
      }
      toMergeToken.imagePath =
          TokenImageUtil.matchBrandLogo(toMergeToken) ?? "";
      OtpToken? alreadyToken = checkTokenExist(toMergeToken, already);
      if (alreadyToken == null &&
          checkTokenExist(toMergeToken, finalMergeTokenList) == null) {
        finalMergeTokenList.add(toMergeToken);
      } else {}
    }
    for (var token in finalMergeTokenList) {
      if (token.uid.isEmpty) token.uid = StringUtil.generateUid();
    }
    if (performInsert) {
      await TokenDao.insertTokens(finalMergeTokenList);
      homeScreenState?.refresh();
    }
    return finalMergeTokenList.length;
  }

  static Future<int> mergeCategories(
    List<TokenCategory> categoryList, {
    bool performInsert = true,
  }) async {
    Map<String, int> categoryCount = {};
    for (TokenCategory category in categoryList) {
      if (categoryCount.containsKey(category.title)) {
        categoryCount[category.title] = categoryCount[category.title]! + 1;
        category.title =
            "${category.title}(${categoryCount[category.title]! - 1})";
      } else {
        categoryCount[category.title] = 1;
      }
    }
    List<TokenCategory> already = await CategoryDao.listCategories();
    List<TokenCategory> newCategoryList = [];
    for (TokenCategory category in categoryList) {
      if (!checkCategoryExist(category, already) &&
          !checkCategoryExist(category, newCategoryList)) {
        newCategoryList.add(category);
      }
    }
    if (performInsert) {
      await CategoryDao.insertCategories(newCategoryList);
      homeScreenState?.refresh();
    }
    return newCategoryList.length;
  }
}
