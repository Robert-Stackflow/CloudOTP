import 'dart:convert';
import 'dart:io';

import 'package:cloudotp/Database/auto_backup_log_dao.dart';
import 'package:cloudotp/Database/category_dao.dart';
import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/auto_backup_log.dart';
import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/Models/config.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/TokenUtils/Backup/backup.dart';
import 'package:cloudotp/TokenUtils/Backup/backup_encrypt_v1.dart';
import 'package:cloudotp/TokenUtils/Cloud/webdav_cloud_service.dart';
import 'package:cloudotp/TokenUtils/otp_token_parser.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/Utils/iprint.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

import '../Database/cloud_service_config_dao.dart';
import '../Database/config_dao.dart';
import '../Models/category.dart';
import '../Utils/itoast.dart';
import '../Utils/utils.dart';
import '../Widgets/Dialog/custom_dialog.dart';
import '../Widgets/Dialog/progress_dialog.dart';
import '../generated/l10n.dart';
import 'Backup/backup_encrypt_interface.dart';
import 'Cloud/cloud_service.dart';

class ExportTokenUtil {
  static bool isBackup(String filePath) {
    String fileName = basename(filePath);
    String fileExtension = extension(filePath);
    return fileName.startsWith("CloudOTP-Backup-") && fileExtension == ".bin";
  }

  static String getExportFileName(String extension) {
    return "CloudOTP-Backup-${Utils.getFormattedDate(DateTime.now())}.$extension";
  }

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

  static exportUriToMobileDirectory({
    bool showLoading = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: S.current.exporting);
    }
    List<OtpToken> tokens = await TokenDao.listTokens();
    Uint8List res = await compute((_) async {
      List<String> uris =
          tokens.map((e) => OtpTokenParser.toUri(e).toString()).toList();
      String content = uris.join("\n");
      return utf8.encode(content);
    }, null);
    String? filePath = await FilePicker.platform.saveFile(
      dialogTitle: S.current.exportUriFileTitle,
      fileName: ExportTokenUtil.getExportFileName("txt"),
      type: FileType.custom,
      allowedExtensions: ['txt'],
      bytes: res,
    );
    if (showLoading) {
      CustomLoadingDialog.dismissLoading();
    }
    if (filePath != null) {
      IToast.showTop(S.current.exportSuccess);
    }
  }

  static Future<Uint8List?> getUint8List({
    String? password,
  }) async {
    if (!await HiveUtil.canBackup()) return null;
    try {
      String tmpPassword = password ?? await ConfigDao.getBackupPassword();
      List<OtpToken> tokens = await TokenDao.listTokens();
      List<TokenCategory> categories = await CategoryDao.listCategories();
      Config config = await ConfigDao.getConfig();
      List<CloudServiceConfig> cloudServiceConfigs =
          await CloudServiceConfigDao.getConfigs();
      return await compute((_) async {
        Backup backup = Backup(
          tokens: tokens,
          categories: categories,
          config: config,
          cloudServiceConfigs: cloudServiceConfigs,
        );
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

  static exportEncryptToMobileDirectory({
    Uint8List? encryptedData,
    String? password,
  }) async {
    var dialog = showProgressDialog(
      msg: S.current.exporting,
      showProgress: false,
    );
    encryptedData ??= await ExportTokenUtil.getUint8List(password: password);
    if (encryptedData == null) {
      IToast.showTop(S.current.exportFailed);
      dialog.dismiss();
      return;
    } else {
      String? filePath = await FilePicker.platform.saveFile(
        dialogTitle: S.current.exportEncryptFileTitle,
        fileName: ExportTokenUtil.getExportFileName("bin"),
        type: FileType.custom,
        bytes: encryptedData,
        allowedExtensions: ['bin'],
      );
      dialog.dismiss();
      if (filePath != null) {
        IToast.showTop(S.current.exportSuccess);
      }
    }
  }

  static autoBackup({
    bool showLoading = false,
    bool showToast = false,
    bool force = false,
    AutoBackupTriggerType triggerType = AutoBackupTriggerType.manual,
  }) async {
    if (!force && !await HiveUtil.canAutoBackup()) return;
    CloudServiceConfig? config = await CloudServiceConfigDao.getWebdavConfig();
    bool enableLocalBackup = HiveUtil.getBool(HiveUtil.enableLocalBackupKey);
    bool enableCloudBackup = HiveUtil.getBool(HiveUtil.enableCloudBackupKey) &&
        config?.isValid == true;
    late AutoBackupType type;
    if (enableLocalBackup && enableCloudBackup) {
      type = AutoBackupType.localAndCloud;
    } else if (enableLocalBackup) {
      type = AutoBackupType.local;
    } else if (enableCloudBackup) {
      type = AutoBackupType.cloud;
    } else {
      return;
    }
    AutoBackupLog log =
        AutoBackupLog.init(type: type, triggerType: triggerType);
    appProvider.pushAutoBackupLog(log);
    autoBackupQueue.add(
      () => ExportTokenUtil.backupEncryptToLocalAndCloud(
        showLoading: showLoading,
        showToast: showToast,
        config: config,
        log: log,
        cloudService: config != null && config.isValid
            ? WebDavCloudService(config)
            : null,
      ),
    );
  }

  static backupEncryptToLocalAndCloud({
    Uint8List? encryptedData,
    bool showLoading = true,
    bool showToast = true,
    CloudServiceConfig? config,
    CloudService? cloudService,
    required AutoBackupLog log,
  }) async {
    bool canLocalBackup = log.type == AutoBackupType.local ||
        log.type == AutoBackupType.localAndCloud;
    bool canCloudBackup = log.type == AutoBackupType.cloud ||
        log.type == AutoBackupType.localAndCloud;
    ProgressDialog? dialog;
    if (showLoading) {
      dialog = showProgressDialog(
        msg: S.current.backuping,
        showProgress: false,
      );
    }
    try {
      log.addStatus(AutoBackupStatus.encrypting);
      encryptedData ??= await getUint8List();
      if (encryptedData == null) {
        log.addStatus(AutoBackupStatus.encryptFailed);
        if (showToast) IToast.showTop(S.current.backupFailed);
        return;
      } else {
        log.addStatus(AutoBackupStatus.encrpytSuccess);
        if (canLocalBackup) {
          try {
            log.addStatus(AutoBackupStatus.saving);
            String backupPath =
                HiveUtil.getString(HiveUtil.backupPathKey) ?? "";
            Directory directory = Directory(backupPath);
            if (!directory.existsSync()) {
              directory.createSync(recursive: true);
            }
            File file = File("${directory.path}/${getExportFileName("bin")}");
            log.backupPath = file.path;
            await file.writeAsBytes(encryptedData);
            await ExportTokenUtil.deleteOldBackup();
            log.addStatus(AutoBackupStatus.saveSuccess);
          } catch (e) {
            log.addStatus(AutoBackupStatus.saveFailed);
          }
        }
        if (canCloudBackup) {
          try {
            if (cloudService != null) {
              log.cloudServiceType = config!.type;
              log.addStatus(AutoBackupStatus.uploading);
              if (showLoading && dialog != null) {
                dialog.updateMessage(
                    msg: S.current.webDavPushing, showProgress: true);
              }
              await cloudService.uploadFile(
                ExportTokenUtil.getExportFileName("bin"),
                encryptedData,
                onProgress: (c, t) {
                  if (showLoading && dialog != null) {
                    dialog.updateProgress(progress: c / t);
                  }
                },
              );
            }
            if (config != null) {
              CloudServiceConfigDao.updateLastBackupTime(config);
            }
            log.addStatus(AutoBackupStatus.uploadSuccess);
          } catch (e) {
            log.addStatus(AutoBackupStatus.uploadFailed);
          }
        }
        if (!log.haveFailed) {
          log.addStatus(AutoBackupStatus.complete);
          if (showToast) IToast.showTop(S.current.backupSuccess);
        }
      }
    } catch (e) {
      if (e is BackupBaseException) {
        log.addStatus(AutoBackupStatus.encryptFailed);
        if (showToast) IToast.showTop(e.intlMessage);
      } else {
        log.addStatus(AutoBackupStatus.failed);
        if (showToast) IToast.showTop(S.current.backupFailed);
      }
    } finally {
      AutoBackupLogDao.insertLog(log);
      if (showLoading && dialog != null) dialog.dismiss();
    }
  }

  static backupEncryptToLocal({
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

  static backupEncryptToCloud({
    Uint8List? encryptedData,
    bool showLoading = true,
    bool showToast = true,
    required CloudServiceConfig config,
    required CloudService cloudService,
  }) async {
    if (!await HiveUtil.canBackup()) return;
    ProgressDialog? dialog;
    if (showLoading) {
      dialog = showProgressDialog(
        msg: S.current.backuping,
        showProgress: false,
      );
    }
    try {
      encryptedData ??= await getUint8List();
      if (encryptedData == null) {
        if (showToast) IToast.showTop(S.current.backupFailed);
        return;
      } else {
        if (showLoading && dialog != null) {
          dialog.updateMessage(
              msg: S.current.webDavPushing, showProgress: true);
        }
        await cloudService.uploadFile(
          ExportTokenUtil.getExportFileName("bin"),
          encryptedData,
          onProgress: (c, t) {
            if (showLoading && dialog != null) {
              dialog.updateProgress(progress: c / t);
            }
          },
        );
        CloudServiceConfigDao.updateLastBackupTime(config);
        if (showToast) IToast.showTop(S.current.backupSuccess);
      }
    } catch (e) {
      if (e is BackupBaseException) {
        if (showToast) IToast.showTop(e.intlMessage);
      } else {
        if (showToast) IToast.showTop(S.current.backupFailed);
      }
    } finally {
      if (showLoading && dialog != null) dialog.dismiss();
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
        return isBackup(element.path);
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
}
