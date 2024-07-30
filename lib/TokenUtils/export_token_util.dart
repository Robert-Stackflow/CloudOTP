import 'dart:convert';
import 'dart:io';

import 'package:cloudotp/Database/category_dao.dart';
import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/TokenUtils/Backup/backup.dart';
import 'package:cloudotp/TokenUtils/Backup/backup_encrypt_v1.dart';
import 'package:cloudotp/TokenUtils/otp_token_parser.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../Database/config_dao.dart';
import '../Models/category.dart';
import '../Utils/itoast.dart';
import '../Utils/utils.dart';
import '../Widgets/Dialog/custom_dialog.dart';
import '../generated/l10n.dart';
import 'Backup/backup_encrypt_interface.dart';

class ExportTokenUtil {
  static exportUriFile(
    String filePath, {
    bool showLoading = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: S.current.exporting);
    }
    List<OtpToken> tokens = await TokenDao.listTokens();
    await compute((_) async {
      List<String> uris =
          tokens.map((e) => OtpTokenParser.toUri(e).toString()).toList();
      String content = uris.join("\n");
      File file = File(filePath);
      file.writeAsStringSync(content);
    }, null);
    if (showLoading) {
      CustomLoadingDialog.dismissLoading();
    }
    IToast.showTop(S.current.exportSuccess);
  }

  Future<File> createCachedFileFromEncryptString(
      String text, String fileName) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    return file.writeAsString(text);
  }

  String getEncryptedData(String password, List<Map<String, dynamic>> tokens) {
    final json = jsonEncode(tokens);
    final key = encrypt.Key.fromUtf8(password.padRight(32, ' '));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(json, iv: iv);
    return encrypted.base64;
  }

  static exportEncryptFile(
    String filePath,
    String password, {
    bool showLoading = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: S.current.exporting);
    }
    try {
      List<OtpToken> tokens = await TokenDao.listTokens();
      List<TokenCategory> categories = await CategoryDao.listCategories();
      await compute((_) async {
        Backup backup = Backup(tokens: tokens, categories: categories);
        BackupEncryptionV1 backupEncryption = BackupEncryptionV1();
        Uint8List encryptedData =
            await backupEncryption.encrypt(backup, password);
        File file = File(filePath);
        file.writeAsBytesSync(encryptedData);
      }, null);
      IToast.showTop(S.current.exportSuccess);
    } catch (e) {
      if (e is BackupBaseException) {
        IToast.showTop(e.message);
      } else {
        IToast.showTop(S.current.exportFailed);
      }
    } finally {
      if (showLoading) {
        CustomLoadingDialog.dismissLoading();
      }
    }
  }

  static String getExportFileName(String extension) {
    return "CloudOTP-Backup-${Utils.getFormattedDate(DateTime.now())}.$extension";
  }

  static backupEncryptFile({
    bool showLoading = false,
  }) async {
    if (!await HiveUtil.canBackup()) return;
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: S.current.backuping);
    }
    try {
      String password = await ConfigDao.getBackupPassword();
      String backupPath = HiveUtil.getString(HiveUtil.backupPathKey) ?? "";
      Directory directory = Directory(backupPath);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      List<OtpToken> tokens = await TokenDao.listTokens();
      List<TokenCategory> categories = await CategoryDao.listCategories();
      await compute((_) async {
        Backup backup = Backup(tokens: tokens, categories: categories);
        BackupEncryptionV1 backupEncryption = BackupEncryptionV1();
        Uint8List encryptedData =
            await backupEncryption.encrypt(backup, password);
        File file = File("${directory.path}/${getExportFileName("bin")}");
        file.writeAsBytesSync(encryptedData);
      }, null);
      IToast.showTop(S.current.backupSuccess);
    } catch (e) {
      if (e is BackupBaseException) {
        IToast.showTop(e.message);
      } else {
        IToast.showTop(S.current.exportFailed);
      }
    } finally {
      if (showLoading) {
        CustomLoadingDialog.dismissLoading();
      }
    }
  }
}
