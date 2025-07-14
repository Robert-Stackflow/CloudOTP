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

import 'package:awesome_cloud/awesome_cloud.dart';

import '../../Models/cloud_service_config.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/hive_util.dart';
import '../export_token_util.dart';
import 'cloud_service.dart';

class GoogleDriveCloudService extends CloudService {
  @override
  CloudServiceType get type => CloudServiceType.GoogleDrive;
  static const String _callbackUrl = 'cloudotp://auth/googledrive/callback';
  static const String _clientId =
      '547353482361-fi716v2qnfvh3aj515ok1r4cdqqhdqbh.apps.googleusercontent.com';
  static const String _googledrivePath = '/CloudOTP';
  static const String _googledrivePathName = 'CloudOTP';
  final CloudServiceConfig _config;
  late GoogleDrive googledrive;
  Function(CloudServiceConfig)? onConfigChanged;

  GoogleDriveCloudService(
    this._config, {
    this.onConfigChanged,
  }) {
    init();
  }

  @override
  Future<void> init() async {
    googledrive = GoogleDrive(
      callbackUrl: _callbackUrl,
      clientId: _clientId,
    );
  }

  @override
  Future<CloudServiceStatus> authenticate() async {
    bool isAuthorized = await googledrive.isConnected();
    if (!isAuthorized) {
      appProvider.preventLock = true;
      isAuthorized = await googledrive.connect();
      appProvider.preventLock = false;
    }
    if (isAuthorized) {
      await fetchInfo();
      return CloudServiceStatus.success;
    } else {
      return CloudServiceStatus.unauthorized;
    }
  }

  Future<GoogleDriveUserInfo?> fetchInfo() async {
    GoogleDriveUserInfo? info = (await googledrive.getInfo()).userInfo;
    if (info != null) {
      _config.email = info.email;
      _config.account = info.displayName;
      _config.totalSize = info.total ?? 0;
      _config.usedSize = info.used ?? 0;
      onConfigChanged?.call(_config);
    }
    return info;
  }

  @override
  Future<bool> isConnected() async {
    bool connected = await googledrive.isConnected();
    if (connected) {
      GoogleDriveUserInfo? info = await fetchInfo();
      return info != null;
    }
    return connected;
  }

  @override
  Future<bool> deleteFile(String path) async {
    GoogleDriveResponse response = await googledrive.deleteById(path);
    return response.isSuccess;
  }

  @override
  Future<bool> deleteOldBackup([int? maxCount]) async {
    maxCount ??= CloudOTPHiveUtil.getMaxBackupsCount();
    List<GoogleDriveFileInfo>? list = await listBackups();
    if (list == null) return false;
    list.sort((a, b) {
      return a.lastModifiedDateTime.compareTo(b.lastModifiedDateTime);
    });
    while (list.length > maxCount) {
      var file = list.removeAt(0);
      await deleteFile(file.id);
    }
    return true;
  }

  @override
  Future<Uint8List?> downloadFile(
    String path, {
    Function(int p1, int p2)? onProgress,
  }) async {
    GoogleDriveResponse response = await googledrive.pullById(path);
    return response.isSuccess ? response.bodyBytes ?? Uint8List(0) : null;
  }

  @override
  Future<int> getBackupsCount() async {
    return (await listBackups())?.length ?? 0;
  }

  @override
  Future<List<GoogleDriveFileInfo>?> listBackups() async {
    var list = await listFiles();
    if (list == null) return null;
    list = list
        .where((element) => ExportTokenUtil.isBackup(element.name))
        .toList();
    return list;
  }

  @override
  Future<List<GoogleDriveFileInfo>?> listFiles() async {
    GoogleDriveResponse response = await googledrive.list(_googledrivePath);
    if (!response.isSuccess) return null;
    List<GoogleDriveFileInfo> files = response.files;
    return files;
  }

  @override
  Future<void> signOut() async {
    await googledrive.disconnect();
  }

  @override
  Future<bool> uploadFile(
    String fileName,
    Uint8List fileData, {
    Function(int p1, int p2)? onProgress,
  }) async {
    GoogleDriveResponse response = await googledrive.push(
      fileData,
      fileName,
      fileName: _googledrivePathName,
    );
    deleteOldBackup();
    return response.isSuccess;
  }

  @override
  Future<bool> hasConfigured() async {
    return await googledrive.hasAuthorized();
  }
}
