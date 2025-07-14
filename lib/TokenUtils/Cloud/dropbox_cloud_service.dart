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
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:path/path.dart';

import '../../Models/cloud_service_config.dart';
import '../../Utils/hive_util.dart';
import '../export_token_util.dart';
import 'cloud_service.dart';

class DropboxCloudService extends CloudService {
  @override
  CloudServiceType get type => CloudServiceType.Dropbox;
  static const String _callbackUrl = 'cloudotp://auth/dropbox/callback';
  static const String _clientId = 'ljyx5bk2jq92esr';
  static const String _dropboxEmptyPath = '';
  static const String _dropboxPath = '/';
  final CloudServiceConfig _config;
  late Dropbox dropbox;
  Function(CloudServiceConfig)? onConfigChanged;

  DropboxCloudService(
    this._config, {
    this.onConfigChanged,
  }) {
    init();
  }

  @override
  Future<void> init() async {
    dropbox = Dropbox(
      callbackUrl: _callbackUrl,
      clientId: _clientId,
    );
  }

  @override
  Future<CloudServiceStatus> authenticate() async {
    bool isAuthorized = await dropbox.isConnected();
    if (!isAuthorized) {
      appProvider.preventLock = true;
      isAuthorized = await dropbox.connect();
      appProvider.preventLock = false;
    }
    if (isAuthorized) {
      DropboxUserInfo? info = await fetchInfo();
      return info != null
          ? CloudServiceStatus.success
          : CloudServiceStatus.connectionError;
    } else {
      return CloudServiceStatus.unauthorized;
    }
  }

  Future<DropboxUserInfo?> fetchInfo() async {
    DropboxUserInfo? info = (await dropbox.getInfo()).userInfo;
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
    bool connected = await dropbox.isConnected();
    if (connected) {
      DropboxUserInfo? info = await fetchInfo();
      return info != null;
    }
    return connected;
  }

  @override
  Future<bool> deleteFile(String path) async {
    DropboxResponse response =
        await dropbox.deleteById(join(_dropboxPath, path));
    return response.isSuccess;
  }

  @override
  Future<bool> deleteOldBackup([int? maxCount]) async {
    maxCount ??= CloudOTPHiveUtil.getMaxBackupsCount();
    List<DropboxFileInfo>? list = await listBackups();
    if (list == null) return false;
    list.sort((a, b) {
      return a.lastModifiedDateTime.compareTo(b.lastModifiedDateTime);
    });
    List<String> toDeleteFileNames = [];
    while (list.length > maxCount) {
      var file = list.removeAt(0);
      toDeleteFileNames.add(file.name);
    }
    await dropbox.deleteBatch(
        toDeleteFileNames.map((e) => join(_dropboxPath, e)).toList());
    return true;
  }

  @override
  Future<Uint8List?> downloadFile(
    String path, {
    Function(int p1, int p2)? onProgress,
  }) async {
    DropboxResponse response = await dropbox.pullById(path);
    return response.isSuccess ? response.bodyBytes ?? Uint8List(0) : null;
  }

  @override
  Future<int> getBackupsCount() async {
    return (await listBackups())?.length ?? 0;
  }

  @override
  Future<List<DropboxFileInfo>?> listBackups() async {
    var list = await listFiles();
    if (list == null) return null;
    list = list
        .where((element) => ExportTokenUtil.isBackup(element.name))
        .toList();
    return list;
  }

  @override
  Future<List<DropboxFileInfo>?> listFiles() async {
    DropboxResponse response = await dropbox.list(_dropboxEmptyPath);
    if (!response.isSuccess) return null;
    List<DropboxFileInfo> files = response.files;
    return files;
  }

  @override
  Future<void> signOut() async {
    await dropbox.disconnect();
  }

  @override
  Future<bool> uploadFile(
    String fileName,
    Uint8List fileData, {
    Function(int p1, int p2)? onProgress,
  }) async {
    DropboxResponse response = await dropbox.push(
      fileData,
      join(_dropboxPath, fileName),
    );
    deleteOldBackup();
    return response.isSuccess;
  }

  @override
  Future<bool> hasConfigured() async {
    return await dropbox.hasAuthorized();
  }
}
