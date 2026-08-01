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
import 'package:cloudotp/Database/database_manager.dart';
import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/TokenUtils/Backup/backup_encrypt_old.dart';
import 'package:cloudotp/TokenUtils/otp_token_parser.dart';
import 'package:cloudotp/TokenUtils/token_image_util.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:sqflite/sqflite.dart';
import 'package:zxing2/qrcode.dart';

import '../Database/category_dao.dart';
import '../Database/config_dao.dart';
import '../Database/token_category_binding_dao.dart';
import '../Models/auto_backup_log.dart';
import '../Models/token_category.dart';
import '../Screens/Token/import_preview_screen.dart';
import '../Utils/constant.dart';
import '../Utils/hive_util.dart';
import '../Utils/utils.dart';
import '../Widgets/BottomSheet/token_option_bottom_sheet.dart';
import '../l10n/l10n.dart';
import 'Backup/backup.dart';
import 'Backup/backup_encrypt_interface.dart';
import 'Backup/backup_encrypt_v1.dart';
import 'ThirdParty/base_token_importer.dart';
import 'export_token_util.dart';

extension TrimPadding on String {
  String trimPadding() {
    return replaceAll(RegExp(r'=+$'), '').toUpperCase();
  }
}

class ImportAnalysis {
  int parseTokenSuccess;
  int parseTokenFailed;
  int importTokenSuccess;
  int parseCategorySuccess;
  int importCategorySuccess;

  ImportAnalysis({
    this.parseTokenSuccess = 0,
    this.parseTokenFailed = 0,
    this.importTokenSuccess = 0,
    this.parseCategorySuccess = 0,
    this.importCategorySuccess = 0,
  });

  showToast([String noTokenToast = ""]) {
    ILogger.info(toString());
    List<String> parts = [];
    if (parseTokenSuccess > 0 || parseTokenFailed > 0) {
      if (parseTokenFailed > 0) {
        parts.add(appLocalizations.importTokenResultWithError(
            parseTokenSuccess, parseTokenFailed, importTokenSuccess));
      } else {
        parts.add(appLocalizations.importTokenResult(
            parseTokenSuccess, importTokenSuccess));
      }
    }
    if (parseCategorySuccess > 0) {
      parts.add(appLocalizations.importCategoryResult(
          parseCategorySuccess, importCategorySuccess));
    }
    if (parts.isNotEmpty) {
      IToast.showTop(parts.join("; "));
    } else {
      IToast.showTop(noTokenToast);
    }
  }

  @override
  String toString() {
    return "ImportAnalysis(parseTokenSuccess: $parseTokenSuccess, parseTokenFailed: $parseTokenFailed, importTokenSuccess: $importTokenSuccess, parseCategorySuccess: $parseCategorySuccess, importCategorySuccess: $importCategorySuccess)";
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
        showLoading: false,
        showPreview: false,
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
    if (res.length >= 2 && context.mounted) {
      _showAnalyzedTokens(
        context,
        List<OtpToken>.from(res[0] as List),
        List<TokenCategory>.from(res[1] as List),
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
    if (!context.mounted) return [tokens, categories];
    if (showSingleTokenDialog) {
      _showAnalyzedTokens(context, tokens, categories);
    } else if (tokens.length > 1) {
      ImportPreviewScreen.show(tokens: tokens, categories: categories);
    }
    return [tokens, categories];
  }

  static void _showAnalyzedTokens(
    BuildContext context,
    List<OtpToken> tokens,
    List<TokenCategory> categories,
  ) {
    if (tokens.length == 1 && categories.isEmpty) {
      BottomSheetBuilder.showBottomSheet(
        context,
        responsive: true,
        (context) => TokenOptionBottomSheet(
          token: tokens.first,
          isNewToken: true,
        ),
      );
    } else if (tokens.isNotEmpty || categories.isNotEmpty) {
      ImportPreviewScreen.show(tokens: tokens, categories: categories);
    }
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
        if (showLoading) {
          CustomLoadingDialog.dismissLoading();
        }
        ImportPreviewScreen.show(
          tokens: tokens,
          categories: [],
        );
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
    ImportPreviewScreen.show(
      tokens: backup.tokens,
      categories: backup.categories,
    );
    return true;
  }

  static Future<List<OtpToken>> importText(
    String content, {
    String emptyTip = "",
    String noTokenToast = "",
    bool showLoading = true,
    bool showToast = true,
    bool showPreview = true,
  }) async {
    if (content.isEmpty && emptyTip.notNullOrEmpty) {
      if (showToast) IToast.showTop(emptyTip);
      return [];
    }
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: appLocalizations.importing);
    }
    List<String> lines = content.split("\n");
    List<OtpToken> tokens = [];
    for (String line in lines) {
      line = line.trim();
      List<OtpToken> parsedTokens = OtpTokenParser.parseUri(line);
      if (parsedTokens.isNotEmpty) {
        tokens.addAll(parsedTokens);
      }
    }
    if (showLoading) {
      CustomLoadingDialog.dismissLoading();
    }
    if (tokens.isEmpty) {
      if (showToast && noTokenToast.isNotEmpty) IToast.showTop(noTokenToast);
      return [];
    }
    if (showPreview) {
      ImportPreviewScreen.show(
        tokens: tokens,
        categories: [],
      );
    }
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

  static Future<void> importFromCloud(
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

  static Future<Map<String, List<String>>> _getResolvedUidMap(
    List<OtpToken> tokenList, {
    List<String>? originalUids,
    DatabaseExecutor? overrideDb,
  }) async {
    List<OtpToken> already = await TokenDao.listTokens(overrideDb: overrideDb);
    Map<String, List<String>> uidMap = {};
    for (int i = 0; i < tokenList.length; i++) {
      OtpToken token = tokenList[i];
      OtpToken? alreadyToken = checkTokenExist(token, already);
      if (alreadyToken != null) {
        final originalUid = originalUids?[i] ?? token.uid;
        final resolvedUids = uidMap.putIfAbsent(originalUid, () => []);
        if (!resolvedUids.contains(alreadyToken.uid)) {
          resolvedUids.add(alreadyToken.uid);
        }
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

  static void applyBackupTokenFields(OtpToken existing, OtpToken backup) {
    final localId = existing.id;
    final localUid = existing.uid;
    final localSeq = existing.seq;
    existing.copyFrom(backup);
    existing.id = localId;
    existing.uid = localUid;
    existing.seq = localSeq;
  }

  static void applyBackupCategoryFields(
    TokenCategory existing,
    TokenCategory backup,
  ) {
    final localId = existing.id;
    final localUid = existing.uid;
    final localSeq = existing.seq;
    existing.copyFrom(backup);
    existing.id = localId;
    existing.uid = localUid;
    existing.seq = localSeq;
  }

  static TokenCategory? findExistingCategory(
    TokenCategory category,
    List<TokenCategory> categoryList,
  ) {
    for (TokenCategory tokenCategory in categoryList) {
      if (tokenCategory.uid == category.uid &&
          tokenCategory.title != category.title) {
        category.uid = StringUtil.generateUid();
      }
      if (tokenCategory.title == category.title) {
        return tokenCategory;
      }
    }
    return null;
  }

  static Future<ImportAnalysis> mergeTokensAndCategories(
    List<OtpToken> tokenList,
    List<TokenCategory> categoryList, {
    bool performInsert = true,
    DatabaseExecutor? overrideDb,
    bool notifyChanges = true,
  }) async {
    ImportAnalysis analysis = ImportAnalysis();
    analysis.parseTokenSuccess = tokenList.length;
    analysis.parseCategorySuccess = categoryList.length;
    final originalUids = tokenList.map((token) => token.uid).toList();
    analysis.importTokenSuccess = await mergeTokens(
      tokenList,
      performInsert: performInsert,
      overrideDb: overrideDb,
      notifyChanges: notifyChanges,
    );
    Map<String, List<String>> uidMap = await _getResolvedUidMap(
      tokenList,
      originalUids: originalUids,
      overrideDb: overrideDb,
    );
    for (TokenCategory category in categoryList) {
      category.bindings = category.bindings
          .expand((uid) => uidMap[uid] ?? [uid])
          .toSet()
          .toList();
    }
    analysis.importCategorySuccess = await mergeCategories(
      categoryList,
      performInsert: performInsert,
      overrideDb: overrideDb,
      notifyChanges: notifyChanges,
    );
    return analysis;
  }

  static Future<int> mergeTokens(
    List<OtpToken> toMergeTokenList, {
    bool performInsert = true,
    DatabaseExecutor? overrideDb,
    bool notifyChanges = true,
  }) async {
    List<OtpToken> already = await TokenDao.listTokens(overrideDb: overrideDb);
    List<OtpToken> finalMergeTokenList = [];
    Set<String> occupiedUids = already.map((token) => token.uid).toSet();
    for (OtpToken toMergeToken in toMergeTokenList) {
      if (toMergeToken.issuer.isEmpty) {
        toMergeToken.issuer = toMergeToken.account;
      }
      if (toMergeToken.imagePath.isEmpty) {
        toMergeToken.imagePath =
            TokenImageUtil.matchBrandLogo(toMergeToken) ?? "";
      }
      OtpToken? alreadyToken = checkTokenExist(toMergeToken, already);
      if (alreadyToken == null &&
          checkTokenExist(toMergeToken, finalMergeTokenList) == null) {
        while (toMergeToken.uid.isEmpty ||
            occupiedUids.contains(toMergeToken.uid)) {
          toMergeToken.uid = StringUtil.generateUid();
        }
        occupiedUids.add(toMergeToken.uid);
        finalMergeTokenList.add(toMergeToken);
      } else {}
    }
    if (performInsert) {
      await TokenDao.insertTokens(
        finalMergeTokenList,
        overrideDb: overrideDb,
        notifyChanges: notifyChanges,
      );
      if (notifyChanges) homeScreenState?.refresh();
    }
    return finalMergeTokenList.length;
  }

  static Future<int> mergeCategories(
    List<TokenCategory> categoryList, {
    bool performInsert = true,
    DatabaseExecutor? overrideDb,
    bool notifyChanges = true,
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
    List<TokenCategory> already =
        await CategoryDao.listCategories(overrideDb: overrideDb);
    List<TokenCategory> newCategoryList = [];
    List<TokenCategory> updatedCategoryList = [];
    for (TokenCategory category in categoryList) {
      TokenCategory? existingInDb = findExistingCategory(category, already);
      TokenCategory? existingInNew =
          findExistingCategory(category, newCategoryList);
      if (existingInDb != null) {
        bool needUpdate = false;
        if (category.pinned && !existingInDb.pinned) {
          existingInDb.pinned = true;
          needUpdate = true;
        }
        if (category.bindings.isNotEmpty) {
          for (String binding in category.bindings) {
            if (!existingInDb.bindings.contains(binding)) {
              existingInDb.bindings.add(binding);
              needUpdate = true;
            }
          }
        }
        if (needUpdate) {
          updatedCategoryList.add(existingInDb);
        }
      } else if (existingInNew == null) {
        newCategoryList.add(category);
      }
    }
    if (performInsert) {
      await CategoryDao.insertCategories(
        newCategoryList,
        overrideDb: overrideDb,
        notifyChanges: notifyChanges,
      );
      if (updatedCategoryList.isNotEmpty) {
        await CategoryDao.updateCategories(
          updatedCategoryList,
          overrideDb: overrideDb,
          notifyChanges: notifyChanges,
        );
        for (TokenCategory cat in updatedCategoryList) {
          if (cat.bindings.isNotEmpty) {
            await BindingDao.bingdingsForCategory(
              cat.uid,
              cat.bindings,
              overrideDb: overrideDb,
              notifyChanges: notifyChanges,
            );
          }
        }
      }
      if (notifyChanges) homeScreenState?.refresh();
    }
    return newCategoryList.length;
  }

  static Future<List<ImportTokenItem>> previewImport(
    List<OtpToken> tokens, {
    List<ImportTokenError> errors = const [],
  }) async {
    List<OtpToken> already = await TokenDao.listTokens();
    List<ImportTokenItem> items = [];
    for (OtpToken token in tokens) {
      if (token.issuer.isEmpty) {
        token.issuer = token.account;
      }
      if (token.imagePath.isEmpty) {
        token.imagePath = TokenImageUtil.matchBrandLogo(token) ?? "";
      }
      OtpToken? existing = checkTokenExist(token, already);
      if (existing != null) {
        items.add(ImportTokenItem(
          token: token,
          existingToken: existing,
          status: ImportTokenStatus.duplicate,
          selected: false,
        ));
      } else {
        items.add(ImportTokenItem(
          token: token,
          status: ImportTokenStatus.ready,
          selected: true,
        ));
      }
    }
    for (ImportTokenError error in errors) {
      OtpToken placeholder = OtpToken.init();
      placeholder.issuer = error.issuer;
      placeholder.account = error.account;
      items.add(ImportTokenItem(
        token: placeholder,
        status: ImportTokenStatus.error,
        errorReason: error.reason,
        selected: false,
      ));
    }
    return items;
  }

  static Future<List<ImportCategoryItem>> previewCategories(
    List<TokenCategory> categories,
  ) async {
    List<TokenCategory> already = await CategoryDao.listCategories();
    List<ImportCategoryItem> items = [];
    for (TokenCategory category in categories) {
      TokenCategory? existingCat =
          already.where((e) => e.title == category.title).firstOrNull;
      items.add(ImportCategoryItem(
        category: category,
        existingCategory: existingCat,
        isNew: existingCat == null,
        selected: existingCat == null,
      ));
    }
    return items;
  }

  static Future<ImportAnalysis> confirmImport(
    List<OtpToken> selectedTokens,
    List<TokenCategory> categories, {
    bool overwriteExisting = false,
    List<ImportTokenItem> tokenItems = const [],
    List<ImportCategoryItem> categoryItems = const [],
    Database? overrideDb,
    bool notifyChanges = true,
  }) async {
    final db = overrideDb ?? await DatabaseManager.getDataBase();
    final analysis = await db.transaction((transaction) {
      return _confirmImport(
        selectedTokens,
        categories,
        overwriteExisting: overwriteExisting,
        tokenItems: tokenItems,
        categoryItems: categoryItems,
        overrideDb: transaction,
      );
    });
    if (notifyChanges &&
        (analysis.importTokenSuccess > 0 ||
            analysis.importCategorySuccess > 0)) {
      try {
        ExportTokenUtil.autoBackup(triggerType: AutoBackupTriggerType.other);
        await Utils.initTray();
        homeScreenState?.refresh();
      } catch (e, t) {
        ILogger.error('Failed to refresh after committed import', e, t);
      }
    }
    return analysis;
  }

  static Future<ImportAnalysis> _confirmImport(
    List<OtpToken> selectedTokens,
    List<TokenCategory> categories, {
    required DatabaseExecutor overrideDb,
    bool overwriteExisting = false,
    List<ImportTokenItem> tokenItems = const [],
    List<ImportCategoryItem> categoryItems = const [],
  }) async {
    ImportAnalysis analysis = ImportAnalysis();
    analysis.parseTokenSuccess =
        tokenItems.where((e) => e.status != ImportTokenStatus.error).length;
    analysis.parseTokenFailed =
        tokenItems.where((e) => e.status == ImportTokenStatus.error).length;
    analysis.parseCategorySuccess = categoryItems.length;
    final previewOriginalUids = tokenItems.map((e) => e.token.uid).toList();
    if (!overwriteExisting) {
      if (tokenItems.isEmpty) {
        var result = await mergeTokensAndCategories(
          selectedTokens,
          categories,
          overrideDb: overrideDb,
          notifyChanges: false,
        );
        analysis.importTokenSuccess = result.importTokenSuccess;
        analysis.importCategorySuccess = result.importCategorySuccess;
        return analysis;
      }
      analysis.importTokenSuccess = await mergeTokens(
        selectedTokens,
        overrideDb: overrideDb,
        notifyChanges: false,
      );
      resolvePreviewCategoryBindings(
        categories,
        tokenItems,
        originalTokenUids: previewOriginalUids,
      );
      analysis.importCategorySuccess = await mergeCategories(
        categories,
        overrideDb: overrideDb,
        notifyChanges: false,
      );
      return analysis;
    }
    final originalUids = selectedTokens.map((token) => token.uid).toList();
    Set<String> selectedUids = originalUids.toSet();
    List<OtpToken> newTokens = [];
    List<OtpToken> overwriteTokens = [];
    for (var item in tokenItems) {
      if (!selectedUids.contains(item.token.uid)) continue;
      if (item.status == ImportTokenStatus.duplicate &&
          item.existingToken != null) {
        OtpToken existing = item.existingToken!;
        applyBackupTokenFields(existing, item.token);
        overwriteTokens.add(existing);
      } else if (item.status == ImportTokenStatus.ready) {
        newTokens.add(item.token);
      }
    }
    analysis.importTokenSuccess = await mergeTokens(
      newTokens,
      overrideDb: overrideDb,
      notifyChanges: false,
    );
    if (overwriteTokens.isNotEmpty) {
      await TokenDao.updateTokens(
        overwriteTokens,
        autoBackup: false,
        overrideDb: overrideDb,
        notifyChanges: false,
      );
      analysis.importTokenSuccess += overwriteTokens.length;
    }
    Map<String, List<String>> uidMap = {};
    if (tokenItems.isNotEmpty) {
      resolvePreviewCategoryBindings(
        categories,
        tokenItems,
        originalTokenUids: previewOriginalUids,
      );
    } else {
      uidMap = await _getResolvedUidMap(
        selectedTokens,
        originalUids: originalUids,
        overrideDb: overrideDb,
      );
    }
    List<TokenCategory> newCategories = [];
    for (var catItem in categoryItems) {
      if (!catItem.selected) continue;
      var cat = catItem.category;
      if (tokenItems.isEmpty) {
        cat.bindings =
            cat.bindings.expand((uid) => uidMap[uid] ?? [uid]).toSet().toList();
      }
      if (!catItem.isNew && catItem.existingCategory != null) {
        TokenCategory existing = catItem.existingCategory!;
        applyBackupCategoryFields(existing, cat);
        await CategoryDao.updateCategories(
          [existing],
          overrideDb: overrideDb,
          notifyChanges: false,
        );
        await BindingDao.replaceBindingsForCategory(
          existing.uid,
          existing.bindings,
          overrideDb: overrideDb,
          notifyChanges: false,
        );
        analysis.importCategorySuccess++;
      } else if (catItem.isNew) {
        newCategories.add(cat);
      }
    }
    if (newCategories.isNotEmpty) {
      analysis.importCategorySuccess += await mergeCategories(
        newCategories,
        overrideDb: overrideDb,
        notifyChanges: false,
      );
    }
    return analysis;
  }

  static void resolvePreviewCategoryBindings(
    List<TokenCategory> categories,
    List<ImportTokenItem> tokenItems, {
    List<String>? originalTokenUids,
  }) {
    if (tokenItems.isEmpty) return;
    final resolvedUids = <String, Set<String>>{};
    for (int index = 0; index < tokenItems.length; index++) {
      final item = tokenItems[index];
      final originalUid =
          originalTokenUids != null && index < originalTokenUids.length
              ? originalTokenUids[index]
              : item.token.uid;
      String? resolvedUid;
      if (item.status == ImportTokenStatus.duplicate &&
          item.existingToken != null) {
        resolvedUid = item.existingToken!.uid;
      } else if (item.status == ImportTokenStatus.ready && item.selected) {
        resolvedUid = item.token.uid;
      }
      if (resolvedUid != null && resolvedUid.isNotEmpty) {
        resolvedUids.putIfAbsent(originalUid, () => {}).add(resolvedUid);
      }
    }
    for (final category in categories) {
      category.bindings = category.bindings
          .expand((uid) => resolvedUids[uid] ?? const <String>{})
          .toSet()
          .toList();
    }
  }
}

enum ImportTokenStatus {
  ready,
  duplicate,
  error,
}

class ImportTokenItem {
  final OtpToken token;
  final OtpToken? existingToken;
  final ImportTokenStatus status;
  final String? errorReason;
  bool selected;

  ImportTokenItem({
    required this.token,
    this.existingToken,
    required this.status,
    this.errorReason,
    required this.selected,
  });
}

class ImportCategoryItem {
  final TokenCategory category;
  final TokenCategory? existingCategory;
  final bool isNew;
  bool selected;

  ImportCategoryItem({
    required this.category,
    this.existingCategory,
    required this.isNew,
    required this.selected,
  });
}
