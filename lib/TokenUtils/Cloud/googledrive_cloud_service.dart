import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

import '../../Models/cloud_service_config.dart';
import 'cloud_service.dart';

class GoogleDriveCloudService extends CloudService {
  static const String _redirectUrl = 'cloudotp://auth/onedrive/callback';
  static const String _clientID = '3b953ca4-3dd4-4148-a80b-b1ac8c39fd97';
  static const String _onedrivePath = '/cloudotp';
  final CloudServiceConfig _config;
  late BuildContext context;
  Function(CloudServiceConfig)? onConfigChanged;

  GoogleDriveCloudService(
    this.context,
    this._config, {
    this.onConfigChanged,
  }) {
    init();
  }

  @override
  Future<void> init() async {}

  @override
  Future<CloudServiceStatus> authenticate() async {
    bool isAuthorized = false;
    if (!isAuthorized) {
      isAuthorized = true;
      if (isAuthorized) {
        await fetchInfo();
        return CloudServiceStatus.success;
      } else {
        return CloudServiceStatus.unauthorized;
      }
    } else {
      return CloudServiceStatus.success;
    }
  }

  Future<dynamic> fetchInfo() async {
    return null;
  }

  @override
  Future<bool> isConnected() async {
    bool connected = false;
    if (connected) {
      await fetchInfo();
    }
    return connected;
  }

  @override
  Future<bool> deleteFile(String path) async {
    print('deleteFile');
    return true;
  }

  @override
  Future<bool> deleteOldBackup([int? maxCount]) async {
    print('deleteOldBackup');
    return true;
  }

  @override
  Future<Uint8List> downloadFile(
    String path, {
    Function(int p1, int p2)? onProgress,
  }) async {
    print('downloadFile');
    return Uint8List(0);
  }

  @override
  Future<int> getBackupsCount() async {
    print("getBackupsCount");
    return 0;
  }

  @override
  Future listBackups() async {
    print("listBackups");
  }

  @override
  Future listFiles() async {
    print("listFiles");
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> uploadFile(
    String fileName,
    Uint8List fileData, {
    Function(int p1, int p2)? onProgress,
  }) async {
    print("uploadFile");
    return true;
  }
}
