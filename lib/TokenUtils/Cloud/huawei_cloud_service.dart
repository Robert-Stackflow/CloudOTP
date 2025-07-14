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
import '../../Utils/hive_util.dart';
import '../export_token_util.dart';
import 'cloud_service.dart';

class HuaweiCloudService extends CloudService {
  @override
  CloudServiceType get type => CloudServiceType.HuaweiCloud;
  static const String _customAuthEndpoint =
      'http://localhost:3009/oauth/cloudotp/huaweicloud/login';
  static const String _customTokenEndpoint =
      'http://localhost:3009/oauth/cloudotp/huaweicloud/token';
  static const String _callbackUrl = "cloudotp://auth/huaweicloud/callback";
  static const String _clientId = '114701957';
  static const String _huaweiCloudEmptyPath = '';
  static const String _huaweiCloudPath = 'CloudOTP';
  final CloudServiceConfig _config;
  late HuaweiCloud huaweiCloud;
  Function(CloudServiceConfig)? onConfigChanged;

  HuaweiCloudService(
    this._config, {
    this.onConfigChanged,
  }) {
    init();
  }

  @override
  Future<void> init() async {
    huaweiCloud = HuaweiCloud.server(
      customAuthEndpoint: _customAuthEndpoint,
      customTokenEndpoint: _customTokenEndpoint,
      customRevokeEndpoint: "",
      callbackUrl: _callbackUrl,
      clientId: _clientId,
    );
  }

  @override
  Future<CloudServiceStatus> authenticate() async {
    bool isAuthorized = await huaweiCloud.isConnected();
    if (!isAuthorized) {
      isAuthorized = await huaweiCloud.connect();
    }
    if (isAuthorized) {
      HuaweiCloudUserInfo? info = await fetchInfo();
      return info != null
          ? CloudServiceStatus.success
          : CloudServiceStatus.connectionError;
    } else {
      return CloudServiceStatus.unauthorized;
    }
  }

  Future<HuaweiCloudUserInfo?> fetchInfo() async {
    HuaweiCloudUserInfo? info = (await huaweiCloud.getInfo()).userInfo;
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
    bool connected = await huaweiCloud.isConnected();
    if (connected) {
      HuaweiCloudUserInfo? info = await fetchInfo();
      return info != null;
    }
    return connected;
  }

  @override
  Future<bool> deleteFile(String path) async {
    HuaweiCloudResponse response = await huaweiCloud.deleteById(path);
    return response.isSuccess;
  }

  @override
  Future<bool> deleteOldBackup([int? maxCount]) async {
    maxCount ??= CloudOTPHiveUtil.getMaxBackupsCount();
    List<HuaweiCloudFileInfo>? list = await listBackups();
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
    HuaweiCloudResponse response = await huaweiCloud.pullById(path);
    return response.isSuccess ? response.bodyBytes ?? Uint8List(0) : null;
  }

  @override
  Future<int> getBackupsCount() async {
    return (await listBackups())?.length ?? 0;
  }

  @override
  Future<List<HuaweiCloudFileInfo>?> listBackups() async {
    var list = await listFiles();
    if (list == null) return null;
    list = list
        .where((element) => ExportTokenUtil.isBackup(element.name))
        .toList();
    return list;
  }

  @override
  Future<List<HuaweiCloudFileInfo>?> listFiles() async {
    HuaweiCloudResponse response =
        await huaweiCloud.list(_huaweiCloudEmptyPath);
    if (!response.isSuccess) return null;
    List<HuaweiCloudFileInfo> files = response.files;
    return files;
  }

  @override
  Future<void> signOut() async {
    await huaweiCloud.disconnect();
  }

  @override
  Future<bool> uploadFile(
    String fileName,
    Uint8List fileData, {
    Function(int p1, int p2)? onProgress,
  }) async {
    HuaweiCloudResponse response = await huaweiCloud.push(
      fileData,
      _huaweiCloudPath,
      fileName: fileName,
    );
    deleteOldBackup();
    return response.isSuccess;
  }

  @override
  Future<bool> hasConfigured() async {
    return await huaweiCloud.hasAuthorized();
  }
}
