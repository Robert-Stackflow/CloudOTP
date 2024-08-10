import 'dart:io';

import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/TokenUtils/Backup/backup_encrypt_old.dart';
import 'package:cloudotp/TokenUtils/otp_token_parser.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Widgets/Dialog/custom_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

import '../Database/category_dao.dart';
import '../Database/config_dao.dart';
import '../Models/category.dart';
import '../Utils/utils.dart';
import '../generated/l10n.dart';
import 'Backup/backup.dart';
import 'Backup/backup_encrypt_interface.dart';
import 'Backup/backup_encrypt_v1.dart';

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
    String tokenToast = S.current.importResultTip(parseSuccess, importSuccess);
    String categoryToast = S.current
        .importCategoryResultTip(parseCategorySuccess, importCategorySuccess);
    if (parseSuccess > 0) {
      if (parseCategorySuccess > 0) {
        IToast.showTop("$tokenToast; $categoryToast");
      } else {
        IToast.showTop(tokenToast);
      }
    } else {
      if (Utils.isNotEmpty(noTokenToast)) {
        IToast.showTop(noTokenToast);
      }
    }
  }
}

RegExp otpauthMigrationReg =
    RegExp(r"^otpauth-migration://offline\?data=(.*)$");
RegExp otpauthReg = RegExp(r"^otpauth://([a-z]+)/([^?]*)(.*)$");
RegExp motpReg = RegExp(r"^motp://([^?]+)\?secret=([a-fA-F\d]+)(.*)$");

class ImportTokenUtil {
  static parseRawUri(
    List<String> rawUris, {
    bool autoPopup = true,
    BuildContext? context,
  }) async {
    List<String> validUris = [];
    for (String line in rawUris) {
      Uri? uri = Uri.tryParse(line);
      if (uri != null &&
          (otpauthReg.hasMatch(line) ||
              motpReg.hasMatch(line) ||
              otpauthMigrationReg.hasMatch(line))) {
        validUris.add(line);
      }
    }
    if (validUris.isNotEmpty) {
      await ImportTokenUtil.importText(
        validUris.join("\n"),
        noTokenToast: S.current.imageDoesNotContainToken,
      );
      if (autoPopup && context != null && context.mounted) {
        Navigator.pop(context);
      }
    } else {
      IToast.showTop(S.current.noQrCodeToken);
    }
  }

  static analyzeImage(Uint8List? imageBytes) async {
    if (imageBytes == null || imageBytes.isEmpty) {
      IToast.showTop(S.current.noQrCode);
      return;
    }
    try {
      img.Image image = img.decodeImage(imageBytes)!;
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
      var result = reader.decode(bitmap);
      if (Utils.isNotEmpty(result.text)) {
        await ImportTokenUtil.parseRawUri([result.text]);
      } else {
        IToast.showTop(S.current.noQrCode);
      }
    } catch (e) {
      if (e.runtimeType == NotFoundException) {
        IToast.showTop(S.current.noQrCode);
      } else {
        IToast.showTop(S.current.parseQrCodeWrong);
      }
    }
  }

  static importUriFile(
    String filePath, {
    bool showLoading = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: S.current.importing);
    }
    try {
      File file = File(filePath);
      if (!file.existsSync()) {
        IToast.showTop(S.current.fileNotExist);
        return;
      } else {
        String content = file.readAsStringSync();
        await importText(
          content,
          showLoading: showLoading,
          emptyTip: S.current.fileEmpty,
          noTokenToast: S.current.fileDoesNotContainToken,
        );
      }
    } catch (e) {
      IToast.showTop(S.current.importFailed);
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
      CustomLoadingDialog.showLoading(title: S.current.importing);
    }
    try {
      File file = File(filePath);
      if (!file.existsSync()) {
        IToast.showTop(S.current.fileNotExist);
        return true;
      } else {
        List<OtpToken>? tokens = await compute((_) async {
          Uint8List content = file.readAsBytesSync();
          List<OtpToken>? tokens =
              await BackupEncryptionOld().decrypt(content, password);
          return tokens;
        }, null);
        if (tokens == null) {
          IToast.showTop(S.current.importFailed);
          return true;
        }
        ImportAnalysis analysis = ImportAnalysis();
        analysis.parseSuccess = tokens.length;
        analysis.importSuccess = await mergeTokens(tokens);
        if (showLoading) {
          CustomLoadingDialog.dismissLoading();
        }
        analysis.showToast(S.current.fileDoesNotContainToken);
        return true;
      }
    } catch (e) {
      IToast.showTop(S.current.importFailed);
      return false;
    } finally {
      if (showLoading) {
        CustomLoadingDialog.dismissLoading();
      }
    }
  }

  static Future<bool> importEncryptFile(
    String filePath,
    String password, {
    bool showLoading = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: S.current.importing);
    }
    try {
      File file = File(filePath);
      if (!file.existsSync()) {
        IToast.showTop(S.current.fileNotExist);
        return true;
      } else {
        Uint8List content = await compute((_) async {
          return file.readAsBytesSync();
        }, null);
        await importUint8List(content, password: password);
        return true;
      }
    } catch (e) {
      if (e is BackupBaseException) {
        IToast.showTop(e.intlMessage);
        if (e is InvalidPasswordOrDataCorruptedException) {
          return false;
        }
        return true;
      } else {
        IToast.showTop(S.current.importFailed);
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
          title: loadingText ?? S.current.importing);
    }
    try {
      await importUint8List(content, password: password);
      return true;
    } catch (e) {
      if (e is BackupBaseException) {
        IToast.showTop(e.intlMessage);
        if (e is InvalidPasswordOrDataCorruptedException) {
          return false;
        }
        return true;
      } else {
        IToast.showTop(S.current.importFailed);
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
    analysis.importSuccess = await mergeTokens(backup.tokens);
    analysis.importCategorySuccess = await mergeCategories(backup.categories);
    analysis.showToast(S.current.fileDoesNotContainToken);
    return true;
  }

  static importText(
    String content, {
    String emptyTip = "",
    String noTokenToast = "",
    bool showLoading = true,
  }) async {
    if (Utils.isEmpty(content) && Utils.isNotEmpty(emptyTip)) {
      IToast.showTop(emptyTip);
      return;
    }
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: S.current.importing);
    }
    ImportAnalysis analysis = ImportAnalysis();
    List<String> lines = content.split("\n");
    List<OtpToken> tokens = [];
    for (String line in lines) {
      List<OtpToken> parsedTokens = OtpTokenParser.parseUri(line);
      if (parsedTokens.isNotEmpty) {
        tokens.addAll(parsedTokens);
        analysis.parseSuccess++;
      } else {
        analysis.parseFailed++;
      }
    }
    analysis.importSuccess = await mergeTokens(tokens);
    if (showLoading) {
      CustomLoadingDialog.dismissLoading();
    }
    analysis.showToast(noTokenToast);
  }

  static bool contain(OtpToken token, List<OtpToken> tokenList) {
    for (OtpToken otpToken in tokenList) {
      if (otpToken.issuer == token.issuer &&
          otpToken.account == token.account) {
        return true;
      }
    }
    return false;
  }

  static bool containCategory(
    TokenCategory category,
    List<TokenCategory> categoryList,
  ) {
    for (TokenCategory tokenCategory in categoryList) {
      if (tokenCategory.title == category.title) {
        return true;
      }
    }
    return false;
  }

  static Future<int> mergeTokens(
    List<OtpToken> tokenList, {
    bool performInsert = true,
  }) async {
    List<OtpToken> already = await TokenDao.listTokens();
    List<OtpToken> newTokenList = [];
    for (OtpToken otpToken in tokenList) {
      if (!contain(otpToken, already) && !contain(otpToken, newTokenList)) {
        newTokenList.add(otpToken);
      }
    }
    if (performInsert) {
      await TokenDao.insertTokens(newTokenList);
      homeScreenState?.refresh();
    }
    return newTokenList.length;
  }

  static Future<int> mergeCategories(
    List<TokenCategory> categoryList, {
    bool performInsert = true,
  }) async {
    List<TokenCategory> already = await CategoryDao.listCategories();
    List<TokenCategory> newCategoryList = [];
    for (TokenCategory category in categoryList) {
      if (!containCategory(category, already) &&
          !containCategory(category, newCategoryList)) {
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
