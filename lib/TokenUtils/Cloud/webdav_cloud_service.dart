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

import 'dart:typed_data';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:awesome_cloud/awesome_cloud.dart';

import '../../Models/cloud_service_config.dart';
import 'cloud_service.dart';

class WebDavCloudService extends CloudService {
  @override
  CloudServiceType get type => CloudServiceType.Webdav;
  static const String _webdavPath = '/CloudOTP';
  final CloudServiceConfig _config;

  WebDavCloudService(this._config) {
    init();
  }

  Client? _client;

  bool get isInitialized => _client != null;

  Client get client {
    if (_client == null) init();
    return _client!;
  }

  @override
  Future<void> init() async {
    _client = newClient(
      _config.endpoint!,
      user: _config.account!,
      password: _config.secret!,
      debug: false,
    );
    client.setHeaders({'accept-charset': 'utf-8'});
    client.setConnectTimeout(8000);
    client.setSendTimeout(8000);
    client.setReceiveTimeout(8000);
  }

  Future<void> _ensureDir() async {
    try {
      await client.mkdirAll(_webdavPath);
    } catch (_) {}
  }

  @override
  Future<bool> isConnected() async {
    CloudServiceStatus status = await authenticate();
    return status.isSuccess;
  }

  @override
  Future<CloudServiceStatus> authenticate() async {
    try {
      await client.ping();
      await _ensureDir();
      return CloudServiceStatus.success;
    } catch (e, t) {
      ILogger.error("Failed to authenticate webdav", e, t);
      if (e is DioException) {
        final msg = e.message ?? e.error?.toString();
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.receiveTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.badCertificate:
          case DioExceptionType.connectionError:
            return CloudServiceStatus(CloudServiceStatusType.connectionError,
                message: msg);
          case DioExceptionType.badResponse:
            if (e.response!.statusCode == 401) {
              return CloudServiceStatus(CloudServiceStatusType.unauthorized,
                  message: msg);
            } else {
              return CloudServiceStatus(CloudServiceStatusType.connectionError,
                  message:
                      "HTTP ${e.response?.statusCode} ${e.response?.statusMessage ?? msg}");
            }
          default:
            break;
        }
      }
      return CloudServiceStatus(CloudServiceStatusType.unknownError,
          message: e.toString());
    }
  }

  @override
  Future<List<WebDavFileInfo>?> listFiles() async {
    var list = await client.readDir(_webdavPath);
    return list;
  }

  @override
  Future<List<WebDavFileInfo>?> listBackups() async {
    var list = await listFiles();
    if (list == null) return null;
    list = list
        .where((element) => ExportTokenUtil.isBackup(element.path ?? ""))
        .toList();
    return list;
  }

  @override
  Future<int> getBackupsCount() async {
    return (await listBackups())?.length ?? 0;
  }

  @override
  Future<bool> uploadFile(
    String fileName,
    Uint8List fileData, {
    Function(int, int)? onProgress,
  }) async {
    CancelToken c = CancelToken();
    double progress = 0;
    await client.write(
      join(_webdavPath, fileName),
      fileData,
      onProgress: (c, t) {
        onProgress?.call(c, t);
        progress = c / t;
      },
      cancelToken: c,
    );
    return await completeUpload(progress >= 1);
  }

  @override
  Future<Uint8List?> downloadFile(
    String path, {
    Function(int, int)? onProgress,
  }) async {
    if (!path.startsWith(_webdavPath)) {
      path = join(_webdavPath, path);
    }
    try {
      return Uint8List.fromList(
        await client.read(
          path,
          onProgress: (c, t) {
            onProgress?.call(c, t);
          },
        ),
      );
    } catch (e, t) {
      ILogger.error("Failed to download file from webdav", e, t);
      return null;
    }
  }

  @override
  Future<bool> deleteFile(String path) async {
    if (!path.startsWith(_webdavPath)) {
      path = join(_webdavPath, path);
    }
    await client.remove(path);
    return true;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> deleteOldBackup([int? maxCount]) async {
    maxCount ??= CloudOTPHiveUtil.getMaxBackupsCount();
    List<WebDavFileInfo>? list = await listBackups();
    if (list == null) return false;
    list.sort((a, b) {
      if (a.mTime == null || b.mTime == null) return 0;
      return a.mTime!.compareTo(b.mTime!);
    });
    final deleteCount = CloudService.getOldBackupDeleteCount(
      backupCount: list.length,
      maxCount: maxCount,
    );
    for (int i = 0; i < deleteCount; i++) {
      var file = list.removeAt(0);
      await deleteFile(file.path!);
    }
    return true;
  }

  @override
  Future<bool> hasConfigured() async {
    return _config.isValid();
  }
}
