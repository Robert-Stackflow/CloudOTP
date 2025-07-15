/*
 * Copyright (c) 2025 Robert-Stackflow.
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

import 'package:awesome_cloud/awesome_cloud.dart';

import '../../Models/cloud_service_config.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/hive_util.dart';
import '../export_token_util.dart';
import 'cloud_service.dart';

class AliyunDriveCloudService extends CloudService {
  @override
  CloudServiceType get type => CloudServiceType.AliyunDrive;

  static const String _customAuthEndpoint =
      '${CloudService.serverEndpoint}/oauth/cloudotp/aliyundrive/login';
  static const String _customTokenEndpoint =
      '${CloudService.serverEndpoint}/oauth/cloudotp/aliyundrive/token';
  static const String _callbackUrl = 'cloudotp://auth/aliyundrive/callback';
  static const String _clientId = '90f68e6d90d147109e35c72fdd039960';
  static const String _aliyunDrivePath = 'CloudOTP';

  final CloudServiceConfig _config;
  late AliyunDriveCloud aliyunDrive;
  Function(CloudServiceConfig)? onConfigChanged;

  AliyunDriveCloudService(
    this._config, {
    this.onConfigChanged,
  }) {
    init();
  }

  @override
  Future<void> init() async {
    aliyunDrive = AliyunDriveCloud.server(
      customAuthEndpoint: _customAuthEndpoint,
      customTokenEndpoint: _customTokenEndpoint,
      customRevokeEndpoint: '',
      callbackUrl: _callbackUrl,
      clientId: _clientId,
    );
  }

  @override
  Future<CloudServiceStatus> authenticate() async {
    bool isAuthorized = await aliyunDrive.isConnected();
    if (!isAuthorized) {
      appProvider.preventLock = true;
      isAuthorized = await aliyunDrive.connect();
      appProvider.preventLock = false;
    }
    if (isAuthorized) {
      await fetchInfo();
      return CloudServiceStatus.success;
    } else {
      return CloudServiceStatus.unauthorized;
    }
  }

  Future<AliyunDriveUserInfo?> fetchInfo() async {
    final userInfo = (await aliyunDrive.getInfo()).userInfo;
    if (userInfo != null) {
      _config.email = userInfo.phone ?? "";
      _config.account = userInfo.name ?? "";
      _config.totalSize = userInfo.spaceAmount ?? 0;
      _config.usedSize = userInfo.spaceUsed ?? 0;
      _config.remark = userInfo.toJson();
      onConfigChanged?.call(_config);
    }
    return userInfo;
  }

  @override
  Future<bool> isConnected() async {
    final connected = await aliyunDrive.isConnected();
    if (connected) {
      final info = await fetchInfo();
      return info != null;
    }
    return connected;
  }

  @override
  Future<bool> deleteFile(String path) async {
    final response = await aliyunDrive.deleteById(
      path,
      driveId: driveId,
      remotePath: _aliyunDrivePath,
    );
    return response.isSuccess;
  }

  @override
  Future<bool> deleteOldBackup([int? maxCount]) async {
    maxCount ??= CloudOTPHiveUtil.getMaxBackupsCount();
    final list = await listBackups();
    if (list == null) return false;

    list.sort(
        (a, b) => a.lastModifiedDateTime.compareTo(b.lastModifiedDateTime));
    while (list.length > maxCount) {
      final file = list.removeAt(0);
      await deleteFile(file.id);
    }
    return true;
  }

  @override
  Future<Uint8List?> downloadFile(
    String path, {
    Function(int p1, int p2)? onProgress,
  }) async {
    final response = await aliyunDrive.pullById(
      path,
      driveId: driveId,
      remotePath: _aliyunDrivePath,
    );
    return response.isSuccess ? response.bodyBytes : null;
  }

  String get driveId => _config.remark["drive"]["default_drive_id"];

  @override
  Future<int> getBackupsCount() async {
    return (await listBackups())?.length ?? 0;
  }

  @override
  Future<List<AliyunDriveFileInfo>?> listBackups() async {
    var list = await listFiles();
    if (list == null) return null;
    list = list
        .where((element) => ExportTokenUtil.isBackup(element.name))
        .toList();
    return list;
  }

  @override
  Future<List<AliyunDriveFileInfo>?> listFiles() async {
    final response = await aliyunDrive.list(
      _aliyunDrivePath,
      driveId: driveId,
    );
    return response.isSuccess ? response.files : null;
  }

  @override
  Future<void> signOut() async {
    await aliyunDrive.disconnect();
  }

  @override
  Future<bool> uploadFile(
    String fileName,
    Uint8List fileData, {
    Function(int p1, int p2)? onProgress,
  }) async {
    final response = await aliyunDrive.push(
      fileData,
      _aliyunDrivePath,
      fileName,
      driveId: driveId,
    );
    deleteOldBackup();
    return response.isSuccess;
  }

  @override
  Future<bool> hasConfigured() async {
    return await aliyunDrive.hasAuthorized();
  }
}
