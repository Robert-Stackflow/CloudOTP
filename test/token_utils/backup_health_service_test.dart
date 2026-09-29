import 'dart:io';
import 'dart:typed_data';

import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category.dart';
import 'package:cloudotp/TokenUtils/Backup/backup.dart';
import 'package:cloudotp/TokenUtils/Backup/backup_encrypt_v1.dart';
import 'package:cloudotp/TokenUtils/Backup/backup_health_service.dart';
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
}
