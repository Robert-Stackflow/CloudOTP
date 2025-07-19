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
import 'package:cloudotp/Models/s3_cloud_file_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:s3_storage/models.dart';
import 'package:s3_storage/s3_storage.dart';

import '../../Models/cloud_service_config.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/utils.dart';
import '../export_token_util.dart';
import 'cloud_service.dart';

class S3CloudService extends CloudService {
  @override
  CloudServiceType get type => CloudServiceType.S3Cloud;
  static const String _s3CloudPath = 'CloudOTP';
  final CloudServiceConfig _config;
  late S3Storage s3Storage;
  late BuildContext context;
  Function(CloudServiceConfig)? onConfigChanged;

  String get bucket => _config.account!;

  String get accessKey => _config.token!;

  String get secretKey => _config.secret!;

  String? get region => _config.email;

  String get endpoint =>
      _config.endpoint!.replaceAll("https://", "").replaceAll("http://", "");

  S3CloudService(
    this._config, {
    this.onConfigChanged,
  }) {
    init();
  }

  @override
  Future<void> init() async {
    final parsed = Utils.parseEndpoint(endpoint);
    final host = parsed['host'];
    final port = parsed['port'];
    s3Storage = S3Storage(
      endPoint: host,
      accessKey: accessKey,
      secretKey: secretKey,
      port: port,
      region: region,
    );
  }

  @override
  Future<CloudServiceStatus> authenticate() async {
    try {
      bool isAuthorized = await s3Storage.bucketExists(bucket);
      if (!isAuthorized) {
        return CloudServiceStatus.connectionError;
      } else {
        return CloudServiceStatus.success;
      }
    } catch (e, t) {
      ILogger.error("Failed to authenticate s3", e, t);
      return CloudServiceStatus.unknownError;
    }
  }

  @override
  Future<bool> isConnected() async {
    try {
      bool connected = await s3Storage.bucketExists(bucket);
      return connected;
    } catch (e, t) {
      ILogger.error("Failed to connect to s3 cloud", e, t);
      return false;
    }
  }

  @override
  Future<bool> deleteFile(String path) async {
    try {
      await s3Storage.removeObject(
        bucket,
        path,
      );
      return true;
    } catch (e, t) {
      ILogger.error("Failed to delete backup file $path from s3 cloud", e, t);
      return false;
    }
  }

  @override
  Future<bool> deleteOldBackup([int? maxCount]) async {
    try {
      maxCount ??= CloudOTPHiveUtil.getMaxBackupsCount();
      List<S3CloudFileInfo>? list = await listBackups();
      if (list == null) return false;
      list.sort((a, b) {
        return a.modifyTimestamp.compareTo(b.modifyTimestamp);
      });
      while (list.length > maxCount) {
        var file = list.removeAt(0);
        await deleteFile(file.path);
      }
      return true;
    } catch (e, t) {
      ILogger.error("Failed to delete old backups from s3 cloud", e, t);
      return false;
    }
  }

  @override
  Future<Uint8List?> downloadFile(
    String path, {
    Function(int p1, int p2)? onProgress,
  }) async {
    try {
      StorageByteStream response = await s3Storage.getObject(
        bucket,
        path,
      );
      return await response.toBytes();
    } catch (e, t) {
      ILogger.error("Failed to download from s3 cloud", e, t);
      return null;
    }
  }

  @override
  Future<int> getBackupsCount() async {
    return (await listBackups())?.length ?? 0;
  }

  @override
  Future<List<S3CloudFileInfo>?> listBackups() async {
    var list = await listFiles();
    if (list == null) return null;
    list = list
        .where((element) => ExportTokenUtil.isBackup(element.name))
        .toList();
    return list;
  }

  @override
  Future<List<S3CloudFileInfo>?> listFiles() async {
    try {
      ListObjectsResult res = await s3Storage.listAllObjects(
        bucket,
        prefix: _s3CloudPath,
        recursive: true,
      );
      List<S3CloudFileInfo> files = res.objects
          .map((e) => S3CloudFileInfo(
                id: e.eTag,
                path: e.key ?? "",
                name: (e.key ?? "").replaceAll("$_s3CloudPath/", ""),
                modifyTimestamp: e.lastModified?.millisecondsSinceEpoch ?? 0,
                size: e.size ?? 0,
                createTimestamp: e.lastModified?.millisecondsSinceEpoch ?? 0,
              ))
          .toList();
      return files;
    } catch (e, t) {
      ILogger.error("Failed to list file from s3 cloud", e, t);
      return null;
    }
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> uploadFile(
    String fileName,
    Uint8List fileData, {
    Function(int p1, int p2)? onProgress,
  }) async {
    try {
      String response = await s3Storage
          .putObject(bucket, "$_s3CloudPath/$fileName", Stream.value(fileData),
              onProgress: (bytes) {
        onProgress?.call(bytes, fileData.length);
      });
      deleteOldBackup();
      return response.isNotEmpty;
    } catch (e, t) {
      ILogger.error("Failed to upload file to s3 cloud", e, t);
      return false;
    }
  }

  @override
  Future<bool> hasConfigured() async {
    return _config.isValid();
  }
}
