import 'dart:io';

import 'package:cloudotp/Database/category_dao.dart';
import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/TokenUtils/Backup/backup.dart';
import 'package:cloudotp/TokenUtils/Backup/backup_encrypt_v1.dart';
import 'package:cloudotp/TokenUtils/Cloud/webdav_cloud_service.dart';
import 'package:cloudotp/TokenUtils/otp_token_parser.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/Utils/iprint.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

import '../Database/cloud_service_config_dao.dart';
import '../Database/config_dao.dart';
import '../Models/category.dart';
import '../Utils/constant.dart';
import '../Utils/itoast.dart';
import '../Utils/utils.dart';
import '../Widgets/Dialog/custom_dialog.dart';
import '../Widgets/Dialog/progress_dialog.dart';
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

  static Future<Uint8List?> getUint8List({
    String? password,
  }) async {
    if (!await HiveUtil.canBackup()) return null;
    try {
      String tmpPassword = password ?? await ConfigDao.getBackupPassword();
      List<OtpToken> tokens = await TokenDao.listTokens();
      List<TokenCategory> categories = await CategoryDao.listCategories();
      return await compute((_) async {
        Backup backup = Backup(tokens: tokens, categories: categories);
        BackupEncryptionV1 backupEncryption = BackupEncryptionV1();
        Uint8List encryptedData =
            await backupEncryption.encrypt(backup, tmpPassword);
        return encryptedData;
      }, null);
    } catch (e) {
      IPrint.debug(e);
      if (e is BackupBaseException) {
        IToast.showTop(e.intlMessage);
      }
      return null;
    }
  }

  static exportEncryptFile(
    String filePath,
    String password, {
    bool showLoading = true,
    Uint8List? encryptedData,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: S.current.exporting);
    }
    try {
      encryptedData ??= await getUint8List(password: password);
      if (encryptedData == null) {
        IToast.showTop(S.current.exportFailed);
        return;
      } else {
        await compute((_) async {
          File file = File(filePath);
          file.writeAsBytesSync(encryptedData!);
        }, null);
        IToast.showTop(S.current.exportSuccess);
      }
    } catch (e) {
      if (e is BackupBaseException) {
        IToast.showTop(e.intlMessage);
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

  static backupEncryptToFile({
    bool showLoading = false,
    bool showToast = false,
    Uint8List? encryptedData,
  }) async {
    if (!await HiveUtil.canBackup()) return;
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: S.current.backuping);
    }
    try {
      encryptedData ??= await getUint8List();
      if (encryptedData == null) {
        if (showToast) IToast.showTop(S.current.backupFailed);
        return;
      } else {
        String backupPath = HiveUtil.getString(HiveUtil.backupPathKey) ?? "";
        Directory directory = Directory(backupPath);
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }
        await compute((_) async {
          File file = File("${directory.path}/${getExportFileName("bin")}");
          file.writeAsBytesSync(encryptedData!);
        }, null);
        ExportTokenUtil.deleteOldBackup();
        if (showToast) IToast.showTop(S.current.backupSuccess);
      }
    } catch (e) {
      if (e is BackupBaseException) {
        if (showToast) IToast.showTop(e.intlMessage);
      } else {
        if (showToast) IToast.showTop(S.current.backupFailed);
      }
    } finally {
      if (showLoading) {
        CustomLoadingDialog.dismissLoading();
      }
    }
  }

  static Future<int> getBackupsCount() async {
    return (await getBackups()).length;
  }

  static Future<List<FileSystemEntity>> getBackups() async {
    String backupPath = HiveUtil.getString(HiveUtil.backupPathKey) ?? "";
    Directory directory = Directory(backupPath);
    if (!directory.existsSync()) {
      return [];
    }
    List<FileSystemEntity> files = directory.listSync();
    List<FileSystemEntity> backups = files.where((element) {
      if (element is File) {
        String fileName = basename(element.path);
        String fileExtension = extension(element.path);
        return fileName.startsWith("CloudOTP-Backup-") &&
            fileExtension == ".bin";
      }
      return false;
    }).toList();
    return backups;
  }

  static Future<void> deleteOldBackup() async {
    int maxBackupCount = HiveUtil.getMaxBackupsCount();
    if (maxBackupCount == 0) return;
    List<FileSystemEntity> backups = await getBackups();
    backups.sort((a, b) {
      return a.statSync().modified.compareTo(b.statSync().modified);
    });
    while (backups.length > maxBackupCount) {
      FileSystemEntity file = backups.removeAt(0);
      file.deleteSync();
    }
  }

  static backupEncryptToWebDav({
    Uint8List? encryptedData,
    required CloudServiceConfig config,
    required WebDavCloudService webDavCloudService,
  }) async {
    var dialog = showProgressDialog(
      rootContext,
      msg: S.current.backuping,
      showProgress: false,
    );
    encryptedData ??= await ExportTokenUtil.getUint8List();
    if (encryptedData == null) {
      IToast.showTop(S.current.backupFailed);
      dialog.dismiss();
      return;
    } else {
      dialog.updateMessage(msg: S.current.webDavPushing, showProgress: true);
      await webDavCloudService.uploadFile(
        ExportTokenUtil.getExportFileName("bin"),
        encryptedData,
        onProgress: (c, t) {
          dialog.updateProgress(progress: c / t);
        },
      );
      dialog.dismiss();
      CloudServiceConfigDao.updateLastBackupTime(config);
      IToast.showTop(S.current.backupSuccess);
    }
  }
}
