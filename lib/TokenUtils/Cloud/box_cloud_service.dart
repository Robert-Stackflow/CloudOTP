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

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:awesome_cloud/awesome_cloud.dart';
import 'package:http/http.dart' as http;

import '../../Models/cloud_service_config.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/hive_util.dart';
import '../export_token_util.dart';
import 'cloud_service.dart';

class BoxCloudService extends CloudService {
  @override
  CloudServiceType get type => CloudServiceType.Box;

  static const String _customAuthEndpoint =
      '${CloudService.serverEndpoint}/oauth/cloudotp/box/login';
  static const String _customTokenEndpoint =
      '${CloudService.serverEndpoint}/oauth/cloudotp/box/token';
  static const String _callbackUrl = 'cloudotp://auth/box/callback';
  static const String _clientId = 'ivmfg11xn0cllzc08j8hj06e1ef5zqtr';
  static const String _boxPath = 'CloudOTP';

  final CloudServiceConfig _config;
  late BoxCloud box;
  Function(CloudServiceConfig)? onConfigChanged;

  BoxCloudService(
    this._config, {
    this.onConfigChanged,
  }) {
    init();
  }

  @override
  Future<void> init() async {
    box = BoxCloud.server(
      customAuthEndpoint: _customAuthEndpoint,
      customTokenEndpoint: _customTokenEndpoint,
      customRevokeEndpoint: '',
      callbackUrl: _callbackUrl,
      clientId: _clientId,
    );
  }

  @override
  Future<bool> checkServer() async {
    try {
      final response = await http.head(Uri.parse(CloudService.serverEndpoint));
      ILogger.info('Box Cloud service availability response for $_customAuthEndpoint: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<CloudServiceStatus> authenticate() async {
    bool isAuthorized = await box.isConnected();
    if (!isAuthorized) {
      appProvider.preventLock = true;
      isAuthorized = await box.connect();
      appProvider.preventLock = false;
    }
    if (isAuthorized) {
      await fetchInfo();
      return CloudServiceStatus.success;
    } else {
      return CloudServiceStatus.unauthorized;
    }
  }

  Future<BoxUserInfo?> fetchInfo() async {
    final userInfo = (await box.getInfo()).userInfo;
    if (userInfo != null) {
      _config.email = userInfo.login ?? "";
      _config.account = userInfo.name ?? "";
      _config.totalSize = userInfo.maxUploadSize ?? 0;
      _config.usedSize = userInfo.spaceUsed ?? 0;
      onConfigChanged?.call(_config);
    }
    return userInfo;
  }

  @override
  Future<bool> isConnected() async {
    final connected = await box.isConnected();
    if (connected) {
      final info = await fetchInfo();
      return info != null;
    }
    return connected;
  }

  @override
  Future<bool> deleteFile(String path) async {
    final response = await box.deleteById(path);
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
    final response = await box.pullById(path);
    return response.isSuccess ? response.bodyBytes : null;
  }

  @override
  Future<int> getBackupsCount() async {
    return (await listBackups())?.length ?? 0;
  }

  @override
  Future<List<BoxFileInfo>?> listBackups() async {
    var list = await listFiles();
    if (list == null) return null;
    list = list
        .where((element) => ExportTokenUtil.isBackup(element.name))
        .toList();
    return list;
  }

  @override
  Future<List<BoxFileInfo>?> listFiles() async {
    final response = await box.list(_boxPath);
    return response.isSuccess ? response.files : null;
  }

  @override
  Future<void> signOut() async {
    await box.disconnect();
  }

  @override
  Future<bool> uploadFile(
    String fileName,
    Uint8List fileData, {
    Function(int p1, int p2)? onProgress,
  }) async {
    final response = await box.push(
      fileData,
      _boxPath,
      fileName,
    );
    deleteOldBackup();
    return response.isSuccess;
  }

  @override
  Future<bool> hasConfigured() async {
    return await box.hasAuthorized();
  }
}
