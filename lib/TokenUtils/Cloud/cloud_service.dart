import 'dart:typed_data';

import 'package:cloudotp/Models/cloud_service_config.dart';

enum CloudServiceStatus {
  success,
  connectionError,
  unauthorized,
  unknownError,
  expired,
}

abstract class CloudService {
  CloudServiceType get type;

  Future<void> init();

  Future<dynamic> listFiles();

  Future<dynamic> listBackups();

  Future<int> getBackupsCount();

  Future<bool> deleteOldBackup([int? maxCount]);

  Future<bool> uploadFile(
    String fileName,
    Uint8List fileData, {
    Function(int, int)? onProgress,
  });

  Future<Uint8List> downloadFile(
    String path, {
    Function(int, int)? onProgress,
  });

  Future<bool> deleteFile(String path);

  Future<CloudServiceStatus> authenticate();

  Future<bool> isConnected();

  Future<bool> isConfigured();

  Future<void> signOut();
}
