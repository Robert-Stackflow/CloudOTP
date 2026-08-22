import 'dart:async';
import 'dart:typed_data';

import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/TokenUtils/Cloud/cloud_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cloud backup retention', () {
    test('zero and negative limits keep every backup', () {
      expect(
        CloudService.getOldBackupDeleteCount(backupCount: 5, maxCount: 0),
        0,
      );
      expect(
        CloudService.getOldBackupDeleteCount(backupCount: 5, maxCount: -1),
        0,
      );
    });

    test('only backups beyond a positive limit are deleted', () {
      expect(
        CloudService.getOldBackupDeleteCount(backupCount: 5, maxCount: 3),
        2,
      );
      expect(
        CloudService.getOldBackupDeleteCount(backupCount: 2, maxCount: 3),
        0,
      );
    });

    test('successful upload waits for retention cleanup', () async {
      final service = _FakeCloudService();
      var completed = false;
      final upload = service.completeUpload(true).then((value) {
        completed = true;
        return value;
      });

      await Future<void>.delayed(Duration.zero);
      expect(service.cleanupCalls, 1);
      expect(completed, isFalse);

      service.cleanupCompleter.complete(true);
      expect(await upload, isTrue);
      expect(completed, isTrue);
    });

    test('failed upload does not delete an older backup', () async {
      final service = _FakeCloudService();

      expect(await service.completeUpload(false), isFalse);
      expect(service.cleanupCalls, 0);
    });
  });
}

class _FakeCloudService extends CloudService {
  final Completer<bool> cleanupCompleter = Completer<bool>();
  int cleanupCalls = 0;

  @override
  CloudServiceType get type => CloudServiceType.Webdav;

  @override
  Future<bool> deleteOldBackup([int? maxCount]) {
    cleanupCalls++;
    return cleanupCompleter.future;
  }

  @override
  Future<CloudServiceStatus> authenticate() async => CloudServiceStatus.success;

  @override
  Future<bool> deleteFile(String path) async => true;

  @override
  Future<Uint8List?> downloadFile(String path,
          {Function(int, int)? onProgress}) async =>
      null;

  @override
  Future<int> getBackupsCount() async => 0;

  @override
  Future<bool> hasConfigured() async => true;

  @override
  Future<void> init() async {}

  @override
  Future<bool> isConnected() async => true;

  @override
  Future<dynamic> listBackups() async => const [];

  @override
  Future<dynamic> listFiles() async => const [];

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> uploadFile(String fileName, Uint8List fileData,
          {Function(int, int)? onProgress}) async =>
      true;
}
