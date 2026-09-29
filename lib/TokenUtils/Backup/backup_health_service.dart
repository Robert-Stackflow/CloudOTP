import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
// awesome_cloud also exports an S3 Object model. Metadata uses dart:core.Object.
import 'package:awesome_cloud/awesome_cloud.dart' hide Object;
import 'package:flutter/foundation.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../Database/config_dao.dart';
import '../../Models/cloud_service_config.dart';
import '../../Models/s3_cloud_file_info.dart';
import '../../Utils/hive_util.dart';
import '../Cloud/cloud_service.dart';
import '../export_token_util.dart';
import 'backup.dart';
import 'backup_encrypt_interface.dart';
import 'backup_encrypt_v1.dart';

enum BackupHealthStatus {
  healthy,
  noBackup,
  noPassword,
  needsSetup,
  unavailable,
  listFailed,
  downloadFailed,
  fileTooLarge,
  invalidPasswordOrCorrupted,
  unsupportedVersion,
  invalidFormat,
  failed,
}

class BackupHealthResult {
  const BackupHealthResult({
    required this.sourceName,
    required this.status,
    this.isLocal = false,
    this.fileName,
    this.backupTime,
    this.tokenCount,
    this.categoryCount,
    this.bindingCount,
  });

  final String sourceName;
  final BackupHealthStatus status;
  final bool isLocal;
  final String? fileName;
  final DateTime? backupTime;
  final int? tokenCount;
  final int? categoryCount;
  final int? bindingCount;

  bool get isHealthy => status == BackupHealthStatus.healthy;
}

class _CloudBackupFile {
  const _CloudBackupFile({
    required this.name,
    required this.downloadId,
    required this.modifiedAt,
    required this.size,
  });

  final String name;
  final String downloadId;
  final int modifiedAt;
  final int size;
}

/// Reads backup files and checks that the existing import format can be
/// decrypted and parsed. It never writes to the current database.
class BackupHealthService {
  const BackupHealthService._();

  static const int maxBackupFileBytes = 16 * 1024 * 1024;

  static Stream<BackupHealthResult> checkAll() async* {
    final password = await ConfigDao.getBackupPassword();
    try {
      final localFiles = (await ExportTokenUtil.getLocalBackups())
          .expand((files) => files)
          .whereType<File>()
          .toList();
      if (localFiles.isNotEmpty ||
          ChewieHiveUtil.getBool(CloudOTPHiveUtil.enableLocalBackupKey)) {
        yield await checkLatestLocal(localFiles, password);
      }
    } catch (error, stackTrace) {
      ILogger.error('Failed to list local backups', error, stackTrace);
      yield const BackupHealthResult(
        sourceName: '',
        status: BackupHealthStatus.unavailable,
        isLocal: true,
      );
    }

    final configs = await CloudServiceConfigDao.getConfigs();
    for (final config in configs.where((config) => config.enabled)) {
      yield await checkLatestCloud(config, password);
    }
  }

  static Future<BackupHealthResult> checkLatestLocal(
    List<File> files,
    String password,
  ) async {
    const sourceName = '';
    if (files.isEmpty) {
      return const BackupHealthResult(
        sourceName: sourceName,
        status: BackupHealthStatus.noBackup,
        isLocal: true,
      );
    }
    try {
      final candidates = <({File file, FileStat stat})>[];
      for (final file in files) {
        if (!ExportTokenUtil.isBackup(file.path)) continue;
        candidates.add((file: file, stat: await file.stat()));
      }
      if (candidates.isEmpty) {
        return const BackupHealthResult(
          sourceName: sourceName,
          status: BackupHealthStatus.noBackup,
          isLocal: true,
        );
      }
      candidates.sort((a, b) {
        final byTime = b.stat.modified.compareTo(a.stat.modified);
        return byTime != 0 ? byTime : b.file.path.compareTo(a.file.path);
      });
      final newest = candidates.first;
      final name = newest.file.uri.pathSegments.last;
      final time = newest.stat.modified;
      if (newest.stat.size > maxBackupFileBytes) {
        return BackupHealthResult(
          sourceName: sourceName,
          status: BackupHealthStatus.fileTooLarge,
          isLocal: true,
          fileName: name,
          backupTime: time,
        );
      }
      if (password.isEmpty) {
        return BackupHealthResult(
          sourceName: sourceName,
          status: BackupHealthStatus.noPassword,
          isLocal: true,
          fileName: name,
          backupTime: time,
        );
      }
      return verifyBytes(
        await newest.file.readAsBytes(),
        password,
        sourceName: sourceName,
        isLocal: true,
        fileName: name,
        backupTime: time,
      );
    } catch (error, stackTrace) {
      ILogger.error('Failed to check local backup health', error, stackTrace);
      return const BackupHealthResult(
        sourceName: sourceName,
        status: BackupHealthStatus.unavailable,
        isLocal: true,
      );
    }
  }

  static Future<BackupHealthResult> checkLatestCloud(
    CloudServiceConfig config,
    String password, {
    CloudService? cloudService,
  }) async {
    final sourceName = config.displayName;
    if ((config.type == CloudServiceType.Webdav ||
            config.type == CloudServiceType.S3Cloud) &&
        !config.hasConfiguration) {
      return BackupHealthResult(
        sourceName: sourceName,
        status: BackupHealthStatus.needsSetup,
      );
    }
    if (config.usesInsecureWebDavHttp && !config.allowsInsecureWebDavHttp) {
      return BackupHealthResult(
        sourceName: sourceName,
        status: BackupHealthStatus.needsSetup,
      );
    }
    late final CloudService service;
    try {
      service = cloudService ?? config.toCloudService();
    } catch (error, stackTrace) {
      ILogger.error(
          'Failed to initialize cloud backup health check', error, stackTrace);
      return BackupHealthResult(
        sourceName: sourceName,
        status: BackupHealthStatus.unavailable,
      );
    }

    List<dynamic>? rawFiles;
    try {
      final listed = await service.listBackups();
      if (listed is List) rawFiles = listed;
    } catch (error, stackTrace) {
      ILogger.error('Failed to list cloud backups during health check', error,
          stackTrace);
    }
    if (rawFiles == null) {
      return BackupHealthResult(
        sourceName: sourceName,
        status: config.hasConfiguration
            ? BackupHealthStatus.listFailed
            : BackupHealthStatus.needsSetup,
      );
    }

    late final List<_CloudBackupFile> files;
    try {
      files = rawFiles
          .map((file) => _cloudFile(config.type, file))
          .whereType<_CloudBackupFile>()
          .toList();
    } catch (error, stackTrace) {
      ILogger.error('Failed to read cloud backup metadata', error, stackTrace);
      return BackupHealthResult(
        sourceName: sourceName,
        status: BackupHealthStatus.listFailed,
      );
    }
    if (files.isEmpty) {
      return BackupHealthResult(
        sourceName: sourceName,
        status: BackupHealthStatus.noBackup,
      );
    }
    files.sort((a, b) {
      final byTime = b.modifiedAt.compareTo(a.modifiedAt);
      return byTime != 0 ? byTime : b.name.compareTo(a.name);
    });
    final newest = files.first;
    final time = newest.modifiedAt > 0
        ? DateTime.fromMillisecondsSinceEpoch(newest.modifiedAt)
        : null;
    if (newest.size > maxBackupFileBytes) {
      return BackupHealthResult(
        sourceName: sourceName,
        status: BackupHealthStatus.fileTooLarge,
        fileName: newest.name,
        backupTime: time,
      );
    }
    if (password.isEmpty) {
      return BackupHealthResult(
        sourceName: sourceName,
        status: BackupHealthStatus.noPassword,
        fileName: newest.name,
        backupTime: time,
      );
    }
    Uint8List? data;
    try {
      data = await service.downloadFile(newest.downloadId);
    } catch (error, stackTrace) {
      ILogger.error('Failed to download cloud backup during health check',
          error, stackTrace);
    }
    if (data == null) {
      return BackupHealthResult(
        sourceName: sourceName,
        status: BackupHealthStatus.downloadFailed,
        fileName: newest.name,
        backupTime: time,
      );
    }
    return verifyBytes(
      data,
      password,
      sourceName: sourceName,
      fileName: newest.name,
      backupTime: time,
    );
  }

  static Future<BackupHealthResult> verifyBytes(
    Uint8List data,
    String password, {
    required String sourceName,
    bool isLocal = false,
    String? fileName,
    DateTime? backupTime,
  }) async {
    BackupHealthResult result(BackupHealthStatus status, [Backup? backup]) =>
        BackupHealthResult(
          sourceName: sourceName,
          status: status,
          isLocal: isLocal,
          fileName: fileName,
          backupTime: backupTime,
          tokenCount: backup?.tokens.length,
          categoryCount: backup?.categories.length,
          bindingCount: backup?.categories.fold<int>(
            0,
            (count, category) => count + category.bindings.length,
          ),
        );

    if (data.length > maxBackupFileBytes) {
      return result(BackupHealthStatus.fileTooLarge);
    }
    if (password.isEmpty) return result(BackupHealthStatus.noPassword);
    try {
      final backup = await compute(_decryptBackup, (data, password));
      return result(BackupHealthStatus.healthy, backup);
    } on InvalidPasswordOrDataCorruptedException {
      return result(BackupHealthStatus.invalidPasswordOrCorrupted);
    } on BackupVersionUnsupportException {
      return result(BackupHealthStatus.unsupportedVersion);
    } on FileNotBackupException {
      return result(BackupHealthStatus.invalidFormat);
    } on BackupLimitExceededException {
      return result(BackupHealthStatus.fileTooLarge);
    } catch (error, stackTrace) {
      ILogger.error(
          'Failed to decode backup during health check', error, stackTrace);
      return result(BackupHealthStatus.failed);
    }
  }

  static Future<Backup> _decryptBackup((Uint8List, String) input) =>
      BackupEncryptionV1().decrypt(input.$1, input.$2);

  static _CloudBackupFile? _cloudFile(CloudServiceType type, Object file) {
    switch (type) {
      case CloudServiceType.Webdav:
        final info = file as WebDavFileInfo;
        final name = info.name;
        if (name == null || name.isEmpty) return null;
        return _CloudBackupFile(
          name: name,
          downloadId: name,
          modifiedAt: (info.mTime ?? info.cTime)?.millisecondsSinceEpoch ?? 0,
          size: info.size ?? 0,
        );
      case CloudServiceType.S3Cloud:
        final info = file as S3CloudFileInfo;
        return _CloudBackupFile(
          name: info.name,
          downloadId: info.path,
          modifiedAt: info.modifyTimestamp,
          size: info.size,
        );
      case CloudServiceType.OneDrive:
        final info = file as OneDriveFileInfo;
        return _CloudBackupFile(
          name: info.name,
          downloadId: info.id,
          modifiedAt: info.lastModifiedDateTime,
          size: info.size,
        );
      case CloudServiceType.GoogleDrive:
        final info = file as GoogleDriveFileInfo;
        return _CloudBackupFile(
          name: info.name,
          downloadId: info.id,
          modifiedAt: info.lastModifiedDateTime,
          size: info.size,
        );
      case CloudServiceType.Dropbox:
        final info = file as DropboxFileInfo;
        return _CloudBackupFile(
          name: info.name,
          downloadId: info.id,
          modifiedAt: info.lastModifiedDateTime,
          size: info.size,
        );
      case CloudServiceType.Box:
        final info = file as BoxFileInfo;
        return _CloudBackupFile(
          name: info.name,
          downloadId: info.id,
          modifiedAt: info.lastModifiedDateTime,
          size: info.size,
        );
      case CloudServiceType.HuaweiCloud:
        final info = file as HuaweiCloudFileInfo;
        return _CloudBackupFile(
          name: info.name,
          downloadId: info.id,
          modifiedAt: info.lastModifiedDateTime,
          size: info.size,
        );
      case CloudServiceType.AliyunDrive:
        final info = file as AliyunDriveFileInfo;
        return _CloudBackupFile(
          name: info.name,
          downloadId: info.id,
          modifiedAt: info.lastModifiedDateTime,
          size: info.size,
        );
    }
  }
}
