import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_onedrive/flutter_onedrive.dart';
import 'package:flutter_onedrive/onedrive_response.dart';
import 'package:path/path.dart';

import '../../Models/cloud_service_config.dart';
import '../../Utils/hive_util.dart';
import '../../generated/l10n.dart';
import '../export_token_util.dart';
import 'cloud_service.dart';

class OneDriveCloudService extends CloudService {
  @override
  CloudServiceType get type => CloudServiceType.OneDrive;
  static const String _redirectUrl = 'cloudotp://auth/onedrive/callback';
  static const String _clientID = '3b953ca4-3dd4-4148-a80b-b1ac8c39fd97';
  static const String _onedrivePath = '/CloudOTP';
  final CloudServiceConfig _config;
  late OneDrive onedrive;
  late BuildContext context;
  Function(CloudServiceConfig)? onConfigChanged;

  OneDriveCloudService(
    this.context,
    this._config, {
    this.onConfigChanged,
  }) {
    init();
  }

  @override
  Future<void> init() async {
    onedrive = OneDrive(redirectURL: _redirectUrl, clientID: _clientID);
  }

  @override
  Future<CloudServiceStatus> authenticate() async {
    bool isAuthorized = await onedrive.isConnected();
    if (!isAuthorized) {
      isAuthorized = await onedrive.connect(
        context,
        windowName: S.current.cloudTypeOneDriveAuthenticateWindowName,
      );
    }
    if (isAuthorized) {
      await fetchInfo();
      return CloudServiceStatus.success;
    } else {
      return CloudServiceStatus.unauthorized;
    }
  }

  Future<OneDriveUserInfo?> fetchInfo() async {
    OneDriveUserInfo? info = (await onedrive.getInfo()).userInfo;
    if (info != null) {
      _config.email = info.email;
      _config.account = info.displayName;
      _config.remainingSize = info.remaining ?? 0;
      _config.totalSize = info.total ?? 0;
      _config.usedSize = info.used ?? 0;
      onConfigChanged?.call(_config);
    }
    return info;
  }

  @override
  Future<bool> isConnected() async {
    bool connected = await onedrive.isConnected();
    if (connected) {
      OneDriveUserInfo? info = await fetchInfo();
      return info != null;
    }
    return connected;
  }

  @override
  Future<bool> deleteFile(String path) async {
    OneDriveResponse response = await onedrive.deleteById(path);
    return response.isSuccess;
  }

  @override
  Future<bool> deleteOldBackup([int? maxCount]) async {
    maxCount ??= HiveUtil.getMaxBackupsCount();
    List<OneDriveFileInfo>? list = await listBackups();
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
    OneDriveResponse response = await onedrive.pullById(path);
    return response.isSuccess ? response.bodyBytes ?? Uint8List(0) : null;
  }

  @override
  Future<int> getBackupsCount() async {
    return (await listBackups())?.length ?? 0;
  }

  @override
  Future<List<OneDriveFileInfo>?> listBackups() async {
    var list = await listFiles();
    if (list == null) return null;
    list = list
        .where((element) => ExportTokenUtil.isBackup(element.name))
        .toList();
    return list;
  }

  @override
  Future<List<OneDriveFileInfo>?> listFiles() async {
    OneDriveResponse response = await onedrive.list(_onedrivePath);
    if (!response.isSuccess) return null;
    List<OneDriveFileInfo> files = response.files;
    return files;
  }

  @override
  Future<void> signOut() async {
    await onedrive.disconnect();
  }

  @override
  Future<bool> uploadFile(
    String fileName,
    Uint8List fileData, {
    Function(int p1, int p2)? onProgress,
  }) async {
    OneDriveResponse response = await onedrive.push(
      fileData,
      join(_onedrivePath, fileName),
    );
    deleteOldBackup();
    return response.isSuccess;
  }

  @override
  Future<bool> hasConfigured() async {
    return await onedrive.hasAuthorized();
  }
}
