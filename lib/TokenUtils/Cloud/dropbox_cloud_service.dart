import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_dropbox/dropbox_response.dart';
import 'package:flutter_dropbox/flutter_dropbox.dart';
import 'package:path/path.dart';

import '../../Models/cloud_service_config.dart';
import '../../Utils/hive_util.dart';
import '../../generated/l10n.dart';
import '../export_token_util.dart';
import 'cloud_service.dart';

class DropboxCloudService extends CloudService {
  @override
  CloudServiceType get type => CloudServiceType.Dropbox;
  static const String _redirectUrl = 'cloudotp://auth/dropbox/callback';
  static const String _clientID = 'ljyx5bk2jq92esr';
  static const String _dropboxEmptyPath = '';
  static const String _dropboxPath = '/';
  final CloudServiceConfig _config;
  late Dropbox dropbox;
  late BuildContext context;
  Function(CloudServiceConfig)? onConfigChanged;

  DropboxCloudService(
    this.context,
    this._config, {
    this.onConfigChanged,
  }) {
    init();
  }

  @override
  Future<void> init() async {
    dropbox = Dropbox(redirectURL: _redirectUrl, clientID: _clientID);
  }

  @override
  Future<CloudServiceStatus> authenticate() async {
    bool isAuthorized = await dropbox.isConnected();
    if (!isAuthorized) {
      isAuthorized = await dropbox.connect(
        context,
        windowName: S.current.cloudTypeDropboxAuthenticateWindowName,
      );
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
    DropboxResponse response = await dropbox.delete(join(_dropboxPath, path));
    return response.isSuccess;
  }

  @override
  Future<bool> deleteOldBackup([int? maxCount]) async {
    maxCount ??= HiveUtil.getMaxBackupsCount();
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
    DropboxResponse response = await dropbox.pull(path);
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
}
