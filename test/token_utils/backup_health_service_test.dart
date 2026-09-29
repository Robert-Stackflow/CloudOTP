import 'dart:io';
import 'dart:typed_data';

import 'package:awesome_cloud/awesome_cloud.dart';
import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category.dart';
import 'package:cloudotp/TokenUtils/Backup/backup.dart';
import 'package:cloudotp/TokenUtils/Backup/backup_encrypt_v1.dart';
import 'package:cloudotp/TokenUtils/Backup/backup_health_service.dart';
import 'package:cloudotp/TokenUtils/Cloud/cloud_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const password = 'test-backup-password';
  late Uint8List encrypted;

  setUpAll(() async {
    final token = OtpToken.init(
      issuer: 'Test',
      secret: 'JBSWY3DPEHPK3PXP',
    );
    final category = TokenCategory.title(title: 'Test')..bindings = [token.uid];
    encrypted = await BackupEncryptionV1().encrypt(
      Backup(tokens: [token], categories: [category]),
      password,
    );
  });

  test('checks decrypted counts without importing backup data', () async {
    final result = await BackupHealthService.verifyBytes(
      encrypted,
      password,
      sourceName: 'local',
    );

    expect(result.status, BackupHealthStatus.healthy);
    expect(result.tokenCount, 1);
    expect(result.categoryCount, 1);
    expect(result.bindingCount, 1);
  });

  test('reports a damaged backup', () async {
    final damaged = Uint8List.fromList(encrypted);
    damaged[damaged.length - 1] ^= 1;

    final result = await BackupHealthService.verifyBytes(
      damaged,
      password,
      sourceName: 'local',
    );

    expect(result.status, BackupHealthStatus.invalidPasswordOrCorrupted);
  });

  test('checks the newest local backup file', () async {
    final directory = await Directory.systemTemp.createTemp('cloudotp-health-');
    try {
      final older = File('${directory.path}/CloudOTP-Backup-old.bin');
      final newer = File('${directory.path}/CloudOTP-Backup-new.bin');
      await older.writeAsBytes(Uint8List.fromList([0, 1, 2]));
      await newer.writeAsBytes(encrypted);
      await older.setLastModified(DateTime(2024, 1, 1));
      await newer.setLastModified(DateTime(2024, 1, 2));

      final result = await BackupHealthService.checkLatestLocal(
        [older, newer],
        password,
      );

      expect(result.status, BackupHealthStatus.healthy);
      expect(result.fileName, 'CloudOTP-Backup-new.bin');
      expect(result.tokenCount, 1);
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('checks a readable cloud even if its configured flag is stale',
      () async {
    final config = _TestCloudServiceConfig();
    final fake = _FakeCloudService(
      files: [
        OneDriveFileInfo(
          id: 'backup-id',
          name: 'CloudOTP-Backup-test.bin',
          size: encrypted.length,
          createdDateTime: 1,
          lastModifiedDateTime: 2,
          description: '',
          fileMimeType: 'application/octet-stream',
        ),
      ],
      bytes: encrypted,
    );

    final result = await BackupHealthService.checkLatestCloud(
      config,
      password,
      cloudService: fake,
    );

    expect(config.configured, isFalse);
    expect(result.status, BackupHealthStatus.healthy);
    expect(fake.downloadedId, 'backup-id');
  });

  test('distinguishes an unreadable cloud list', () async {
    final config = _TestCloudServiceConfig()
      ..configured = true;
    final result = await BackupHealthService.checkLatestCloud(
      config,
      password,
      cloudService: _FakeCloudService(files: null, bytes: null),
    );

    expect(result.status, BackupHealthStatus.listFailed);
  });
}

class _TestCloudServiceConfig extends CloudServiceConfig {
  _TestCloudServiceConfig() : super.init(type: CloudServiceType.OneDrive);

  @override
  String get displayName => 'OneDrive';
}

class _FakeCloudService implements CloudService {
  _FakeCloudService({required this.files, required this.bytes});

  final List<OneDriveFileInfo>? files;
  final Uint8List? bytes;
  String? downloadedId;

  @override
  CloudServiceType get type => CloudServiceType.OneDrive;

  @override
  Future<List<OneDriveFileInfo>?> listBackups() async => files;

  @override
  Future<Uint8List?> downloadFile(
    String path, {
    Function(int, int)? onProgress,
  }) async {
    downloadedId = path;
    return bytes;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
