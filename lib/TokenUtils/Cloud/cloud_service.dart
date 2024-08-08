import 'dart:typed_data';

abstract class CloudService {
  Future<void> init();

  Future<dynamic> listFiles();

  Future<dynamic> listBackups();

  Future<int> getBackupsCount();

  Future<void> deleteOldBackup(int maxCount);

  Future<void> uploadFile(
    String fileName,
    Uint8List fileData, {
    Function(int, int)? onProgress,
  });

  Future<Uint8List> downloadFile(
    String path, {
    Function(int, int)? onProgress,
  });

  Future<void> deleteFile(String path);

  Future<void> authenticate();

  Future<void> signOut();
}
