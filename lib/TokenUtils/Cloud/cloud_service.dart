import 'dart:typed_data';

enum CloudServiceStatus {
  success,
  connectionError,
  unauthorized,
  unknownError,
  expired,
}

abstract class CloudService {
  Future<void> init();

  Future<dynamic> listFiles();

  Future<dynamic> listBackups();

  Future<int> getBackupsCount();

  Future<void> deleteOldBackup(int maxCount);

  Future<bool> uploadFile(
    String fileName,
    Uint8List fileData, {
    Function(int, int)? onProgress,
  });

  Future<Uint8List> downloadFile(
    String path, {
    Function(int, int)? onProgress,
  });

  Future<void> deleteFile(String path);

  Future<CloudServiceStatus> authenticate();

  Future<bool> isConnected();

  Future<void> signOut();
}
