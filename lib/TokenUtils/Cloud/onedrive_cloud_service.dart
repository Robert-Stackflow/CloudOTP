import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_onedrive/flutter_onedrive.dart';

import '../../Models/cloud_service_config.dart';
import 'cloud_service.dart';

class OneDriveCloudService extends CloudService {
  static const String _redirectUrl = 'cloudotp://auth/onedrive';
  static const String _clientID = '3b953ca4-3dd4-4148-a80b-b1ac8c39fd97';
  static const String _onedrivePath = '/cloudotp';
  final CloudServiceConfig _config;
  late OneDrive onedrive;
  late BuildContext context;

  OneDriveCloudService(
    this.context,
    this._config,
  ) {
    init();
  }

  @override
  Future<void> init() async {
    onedrive = OneDrive(redirectURL: _redirectUrl, clientID: _clientID);
    authenticate();
  }

  @override
  Future<CloudServiceStatus> authenticate() async {
    bool isAuthorized = await onedrive.isConnected();
    if (!isAuthorized) {
      isAuthorized = await onedrive.connect(context);
      return CloudServiceStatus.unauthorized;
    } else {
      return CloudServiceStatus.success;
    }
  }

  @override
  Future<void> deleteFile(String path) async {
    print('deleteFile');
  }

  @override
  Future<void> deleteOldBackup(int maxCount) async {
    print('deleteOldBackup');
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
  Future<void> signOut() async {
    await onedrive.disconnect();
  }

  @override
  Future<void> uploadFile(
    String fileName,
    Uint8List fileData, {
    Function(int p1, int p2)? onProgress,
  }) async {
    print("uploadFile");
  }
}
